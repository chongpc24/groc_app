//premise_database_service.dart
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Local SQLite cache for supermarket premise data (from PriceCatcher's
/// lookup_premise.csv).
///
/// Deliberately uses its OWN database file ('premises.db') instead of the
/// team's 'groc.db' — this means it never touches, opens, or depends on
/// DatabaseService, so there's zero risk of colliding with teammates'
/// schema/version changes there.
class PremiseDatabaseService {
  static final PremiseDatabaseService _instance =
  PremiseDatabaseService._internal();
  factory PremiseDatabaseService() => _instance;
  PremiseDatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'premises.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE premises(
            premiseCode INTEGER PRIMARY KEY,
            premise TEXT,
            address TEXT,
            premiseType TEXT,
            state TEXT,
            district TEXT
          )
        ''');
      },
    );
  }

  /// Wipes and reloads the whole table — used once, right after the CSV
  /// is parsed on first launch.
  Future<void> replaceAll(List<Map<String, dynamic>> rows) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('premises');
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert(
          'premises',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<int> rowCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM premises');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await database;
    return db.query('premises');
  }
}