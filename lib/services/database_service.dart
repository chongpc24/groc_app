import 'package:path/path.dart';
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
    final basePath = await getDatabasesPath();
    final dbPath = join(basePath, 'groc.db');
    return openDatabase(
      dbPath,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createProductTables(db);
        await _createCartTables(db);
        await _createPrivateCacheTables(db);
        await _createIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCartTables(db);
        }
        if (oldVersion < 3) {
          await _createPrivateCacheTables(db);
        }
        await _createIndexes(db);
      },
    );
  }

  Future<void> _createProductTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products(
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
  }

  Future<void> _createCartTables(DatabaseExecutor db) async {
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

  }

  Future<void> _createPrivateCacheTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profile_cache(
        userId TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        fullName TEXT NOT NULL,
        icNumber TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        gender TEXT NOT NULL,
        address TEXT,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shopping_lists_cache(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shopping_list_items_cache(
        id TEXT PRIMARY KEY,
        listId TEXT NOT NULL,
        userId TEXT NOT NULL,
        itemCode TEXT NOT NULL,
        itemName TEXT NOT NULL,
        premiseCode TEXT NOT NULL,
        storeName TEXT NOT NULL,
        price REAL NOT NULL,
        unit TEXT,
        category TEXT,
        quantity INTEGER NOT NULL,
        addedAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_category ON products(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_itemName ON products(itemName)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_itemCode ON products(itemCode)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_premise ON cart(premiseCode)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_itemCode_cart ON cart(itemCode)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_syncStatus ON cart(syncStatus)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orderDate ON order_history(orderDate)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_syncStatus_order ON order_history(syncStatus)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_lists_cache_user ON shopping_lists_cache(userId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_list_items_cache_list ON shopping_list_items_cache(listId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_list_items_cache_user ON shopping_list_items_cache(userId)');
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
    return rows.map((row) => row['category'] as String).toList();
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

  Future<List<Map<String, dynamic>>> search(
      String query, {
        String? category,
      }) async {
    final db = await database;
    final words = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return [];

    final wordClauses = words.map((word) => 'itemName LIKE ?').join(' AND ');
    final wordArgs = words.map((word) => '%$word%').toList();
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
    return db.query(
      'products',
      where: 'itemCode = ?',
      whereArgs: [itemCode],
    );
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
      return;
    }
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
    await db.delete(
      'cart',
      where: 'premiseCode = ?',
      whereArgs: [premiseCode],
    );
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

  Future<void> upsertProfileCache(Map<String, dynamic> profile) async {
    final db = await database;
    await db.insert(
      'profile_cache',
      {
        'userId': profile['id'],
        'email': profile['email'] ?? '',
        'fullName': profile['full_name'] ?? '',
        'icNumber': profile['ic_number'] ?? '',
        'phoneNumber': profile['phone_number'] ?? '',
        'gender': profile['gender'] ?? 'Prefer not to say',
        'address': profile['address'],
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getProfileCache(String userId) async {
    final db = await database;
    final rows = await db.query(
      'profile_cache',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return {
      'id': row['userId'],
      'email': row['email'],
      'full_name': row['fullName'],
      'ic_number': row['icNumber'],
      'phone_number': row['phoneNumber'],
      'gender': row['gender'],
      'address': row['address'],
    };
  }

  Future<void> replaceShoppingListCache(
      String userId,
      List<Map<String, dynamic>> lists,
      List<Map<String, dynamic>> items,
      ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'shopping_list_items_cache',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        'shopping_lists_cache',
        where: 'userId = ?',
        whereArgs: [userId],
      );

      for (final list in lists) {
        await txn.insert(
          'shopping_lists_cache',
          _listToCacheRow(userId, list),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final item in items) {
        await txn.insert(
          'shopping_list_items_cache',
          _itemToCacheRow(userId, item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> upsertShoppingListCache(
      String userId,
      Map<String, dynamic> list,
      ) async {
    final db = await database;
    await db.insert(
      'shopping_lists_cache',
      _listToCacheRow(userId, list),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteShoppingListCache(String listId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'shopping_list_items_cache',
        where: 'listId = ?',
        whereArgs: [listId],
      );
      await txn.delete(
        'shopping_lists_cache',
        where: 'id = ?',
        whereArgs: [listId],
      );
    });
  }

  Future<List<Map<String, dynamic>>> getShoppingListSummaries(
      String userId,
      ) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        l.id,
        l.userId,
        l.name,
        l.createdAt,
        l.updatedAt,
        COUNT(i.id) AS itemCount,
        COALESCE(SUM(i.price * i.quantity), 0) AS estimatedTotal
      FROM shopping_lists_cache l
      LEFT JOIN shopping_list_items_cache i ON i.listId = l.id
      WHERE l.userId = ?
      GROUP BY l.id
      ORDER BY l.updatedAt DESC, l.name COLLATE NOCASE ASC
    ''', [userId]);

    return rows.map((row) {
      return {
        'id': row['id'],
        'user_id': row['userId'],
        'name': row['name'],
        'created_at': row['createdAt'],
        'updated_at': row['updatedAt'],
        'item_count': row['itemCount'] ?? 0,
        'estimated_total': row['estimatedTotal'] ?? 0,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getShoppingListItems(
      String userId,
      String listId,
      ) async {
    final db = await database;
    final rows = await db.query(
      'shopping_list_items_cache',
      where: 'userId = ? AND listId = ?',
      whereArgs: [userId, listId],
      orderBy: 'updatedAt DESC, itemName COLLATE NOCASE ASC',
    );
    return rows.map((row) => _cacheRowToItem(row)).toList();
  }

  Future<void> replaceSingleListItemsCache(
      String userId,
      String listId,
      List<Map<String, dynamic>> items,
      ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'shopping_list_items_cache',
        where: 'userId = ? AND listId = ?',
        whereArgs: [userId, listId],
      );
      for (final item in items) {
        await txn.insert(
          'shopping_list_items_cache',
          _itemToCacheRow(userId, item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> upsertShoppingListItemCache(
      String userId,
      Map<String, dynamic> item,
      ) async {
    final db = await database;
    await db.insert(
      'shopping_list_items_cache',
      _itemToCacheRow(userId, item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteShoppingListItemCache(String itemId) async {
    final db = await database;
    await db.delete(
      'shopping_list_items_cache',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> clearPrivateCache(String userId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'profile_cache',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        'shopping_list_items_cache',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        'shopping_lists_cache',
        where: 'userId = ?',
        whereArgs: [userId],
      );
    });
  }

  Map<String, dynamic> _listToCacheRow(
      String userId,
      Map<String, dynamic> list,
      ) {
    return {
      'id': list['id'].toString(),
      'userId': userId,
      'name': list['name'] ?? '',
      'createdAt': (list['created_at'] ?? DateTime.now().toIso8601String()).toString(),
      'updatedAt': (list['updated_at'] ?? DateTime.now().toIso8601String()).toString(),
    };
  }

  Map<String, dynamic> _itemToCacheRow(
      String userId,
      Map<String, dynamic> item,
      ) {
    return {
      'id': item['id'].toString(),
      'listId': item['list_id'].toString(),
      'userId': userId,
      'itemCode': item['item_code']?.toString() ?? '',
      'itemName': item['item_name']?.toString() ?? '',
      'premiseCode': item['premise_code']?.toString() ?? '',
      'storeName': item['store_name']?.toString() ?? '',
      'price': (item['price'] as num?)?.toDouble() ?? 0.0,
      'unit': item['unit']?.toString(),
      'category': item['category']?.toString(),
      'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
      'addedAt': (item['added_at'] ?? DateTime.now().toIso8601String()).toString(),
      'updatedAt': (item['updated_at'] ?? DateTime.now().toIso8601String()).toString(),
    };
  }

  Map<String, dynamic> _cacheRowToItem(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'list_id': row['listId'],
      'item_code': row['itemCode'],
      'item_name': row['itemName'],
      'premise_code': row['premiseCode'],
      'store_name': row['storeName'],
      'price': row['price'],
      'unit': row['unit'],
      'category': row['category'],
      'quantity': row['quantity'],
      'added_at': row['addedAt'],
      'updated_at': row['updatedAt'],
    };
  }
}
