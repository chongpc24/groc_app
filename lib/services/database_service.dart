import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'groc.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            itemCode TEXT,
            itemName TEXT,
            unit TEXT,
            category TEXT,
            premiseCode TEXT,
            storeName TEXT,
            price REAL,
            date TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_category ON products(category)');
        await db.execute('CREATE INDEX idx_itemName ON products(itemName)');
        await db.execute('CREATE INDEX idx_itemCode ON products(itemCode)');

        await db.execute('''
          CREATE TABLE cart(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            itemCode TEXT NOT NULL,
            itemName TEXT NOT NULL,
            premiseCode TEXT NOT NULL,
            storeName TEXT NOT NULL,
            price REAL NOT NULL,
            quantity INTEGER NOT NULL,
            addedAt TEXT NOT NULL,
            syncedAt TEXT,
            syncStatus TEXT DEFAULT 'pending'
          )
        ''');
        await db.execute('CREATE INDEX idx_premise ON cart(premiseCode)');
        await db.execute('CREATE INDEX idx_itemCode_cart ON cart(itemCode)');
        await db.execute('CREATE INDEX idx_syncStatus ON cart(syncStatus)');

        await db.execute('''
          CREATE TABLE order_history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            orderId TEXT UNIQUE NOT NULL,
            premiseCode TEXT NOT NULL,
            storeName TEXT NOT NULL,
            totalAmount REAL NOT NULL,
            itemCount INTEGER NOT NULL,
            orderDate TEXT NOT NULL,
            deliveryAddress TEXT,
            status TEXT DEFAULT 'pending',
            syncedAt TEXT,
            syncStatus TEXT DEFAULT 'pending'
          )
        ''');
        await db.execute('CREATE INDEX idx_orderDate ON order_history(orderDate)');
        await db.execute('CREATE INDEX idx_syncStatus_order ON order_history(syncStatus)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cart(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              itemCode TEXT NOT NULL,
              itemName TEXT NOT NULL,
              premiseCode TEXT NOT NULL,
              storeName TEXT NOT NULL,
              price REAL NOT NULL,
              quantity INTEGER NOT NULL,
              addedAt TEXT NOT NULL,
              syncedAt TEXT,
              syncStatus TEXT DEFAULT 'pending'
            )
          ''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_premise ON cart(premiseCode)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_itemCode_cart ON cart(itemCode)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_syncStatus ON cart(syncStatus)');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS order_history(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              orderId TEXT UNIQUE NOT NULL,
              premiseCode TEXT NOT NULL,
              storeName TEXT NOT NULL,
              totalAmount REAL NOT NULL,
              itemCount INTEGER NOT NULL,
              orderDate TEXT NOT NULL,
              deliveryAddress TEXT,
              status TEXT DEFAULT 'pending',
              syncedAt TEXT,
              syncStatus TEXT DEFAULT 'pending'
            )
          ''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_orderDate ON order_history(orderDate)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_syncStatus_order ON order_history(syncStatus)');
        }
      },
    );
  }

  Future<void> replaceAll(List<Map<String, dynamic>> rows) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('products');
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert('products', row);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<int> rowCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await database;
    return db.query('products');
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT category FROM products WHERE category IS NOT NULL ORDER BY category',
    );
    return rows.map((r) => r['category'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getByCategory(String category) async {
    final db = await database;
    return db.rawQuery('''
    SELECT itemCode, itemName, unit, category, premiseCode, storeName,
           MIN(price) AS price, date
    FROM products
    WHERE category = ?
    GROUP BY itemCode
    ORDER BY itemName
  ''', [category]);
  }

  Future<List<Map<String, dynamic>>> search(String query, {String? category}) async {
    final db = await database;

    final words = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return [];

    final wordClauses = words.map((_) => 'itemName LIKE ?').join(' AND ');
    final wordArgs = words.map((w) => '%$w%').toList();

    final whereClause = category != null
        ? '$wordClauses AND category = ?'
        : wordClauses;
    final args = category != null ? [...wordArgs, category] : wordArgs;

    return db.rawQuery('''
    SELECT itemCode, itemName, unit, category, premiseCode, storeName,
           MIN(price) AS price, date
    FROM products
    WHERE $whereClause
    GROUP BY itemCode
    ORDER BY itemName
    LIMIT 100
  ''', args);
  }

  Future<List<Map<String, dynamic>>> getByItemCode(String itemCode) async {
    final db = await database;
    return db.query('products', where: 'itemCode = ?', whereArgs: [itemCode]);
  }


  Future<int> addToCart(Map<String, dynamic> cartItem) async {
    final db = await database;
    return db.insert('cart', {
      ...cartItem,
      'addedAt': DateTime.now().toIso8601String(),
      'syncStatus': 'pending',
    });
  }

  Future<List<Map<String, dynamic>>> getAllCartItems() async {
    final db = await database;
    return db.query('cart', orderBy: 'addedAt DESC');
  }

  Future<List<Map<String, dynamic>>> getCartByStore(String premiseCode) async {
    final db = await database;
    return db.query(
      'cart',
      where: 'premiseCode = ?',
      whereArgs: [premiseCode],
      orderBy: 'addedAt DESC',
    );
  }

  Future<void> updateCartQuantity(int id, int quantity) async {
    final db = await database;
    if (quantity <= 0) {
      await db.delete('cart', where: 'id = ?', whereArgs: [id]);
    } else {
      await db.update(
        'cart',
        {
          'quantity': quantity,
          'syncStatus': 'pending',
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> removeFromCart(int id) async {
    final db = await database;
    await db.delete('cart', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCart() async {
    final db = await database;
    await db.delete('cart');
  }

  Future<void> clearCartByStore(String premiseCode) async {
    final db = await database;
    await db.delete('cart', where: 'premiseCode = ?', whereArgs: [premiseCode]);
  }

  Future<List<Map<String, dynamic>>> getPendingSyncCart() async {
    final db = await database;
    return db.query(
      'cart',
      where: 'syncStatus = ?',
      whereArgs: ['pending'],
    );
  }

  Future<void> markCartAsSynced(List<int> ids) async {
    final db = await database;
    for (final id in ids) {
      await db.update(
        'cart',
        {
          'syncStatus': 'synced',
          'syncedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }


  Future<int> saveOrder(Map<String, dynamic> order) async {
    final db = await database;
    return db.insert('order_history', {
      ...order,
      'orderDate': DateTime.now().toIso8601String(),
      'syncStatus': 'pending',
    });
  }

  Future<List<Map<String, dynamic>>> getOrderHistory() async {
    final db = await database;
    return db.query('order_history', orderBy: 'orderDate DESC');
  }

  Future<List<Map<String, dynamic>>> getOrdersByStore(String premiseCode) async {
    final db = await database;
    return db.query(
      'order_history',
      where: 'premiseCode = ?',
      whereArgs: [premiseCode],
      orderBy: 'orderDate DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncOrders() async {
    final db = await database;
    return db.query(
      'order_history',
      where: 'syncStatus = ?',
      whereArgs: ['pending'],
    );
  }

  Future<void> markOrderAsSynced(String orderId) async {
    final db = await database;
    await db.update(
      'order_history',
      {
        'syncStatus': 'synced',
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'orderId = ?',
      whereArgs: [orderId],
    );
  }
}