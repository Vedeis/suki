import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction.dart';

class DatabaseService {
  DatabaseService._();
  static final instance = DatabaseService._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'moneyflow.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
          amount INTEGER NOT NULL,
          type TEXT NOT NULL,
          source TEXT NOT NULL,
          raw_text TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX idx_transactions_date ON transactions(created_at)');
    });
    return _db!;
  }

  Future<int> insert(MoneyTransaction tx) async =>
      (await database).insert('transactions', tx.toMap());

  Future<List<MoneyTransaction>> all() async {
    final rows = await (await database).query('transactions', orderBy: 'created_at DESC');
    return rows.map(MoneyTransaction.fromMap).toList();
  }

  Future<void> delete(int id) async =>
      (await database).delete('transactions', where: 'id = ?', whereArgs: [id]);

  Future<bool> existsSimilar(String raw, DateTime time) async {
    final rows = await (await database).query(
      'transactions',
      where: 'raw_text = ? AND created_at >= ?',
      whereArgs: [raw, time.subtract(const Duration(minutes: 3)).toIso8601String()],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
