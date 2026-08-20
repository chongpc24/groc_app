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
      version: 1,
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
}
