import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/translation_result.dart';
import '../models/translation_mode.dart';

class HistoryService {
  HistoryService._();
  static final instance = HistoryService._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'speakeasy.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transcript TEXT NOT NULL,
          japanese TEXT NOT NULL,
          latency_ms INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          is_favorite INTEGER NOT NULL DEFAULT 0,
          mode TEXT NOT NULL DEFAULT 'en_to_jp'
        )
      '''),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE history ADD COLUMN mode TEXT NOT NULL DEFAULT 'en_to_jp'",
          );
        }
      },
    );
  }

  Future<void> save(TranslationResult result) async {
    final database = await db;
    await database.insert('history', {
      'transcript': result.transcript,
      'japanese': result.outputText,
      'latency_ms': result.totalLatencyMs,
      'created_at': result.timestamp.millisecondsSinceEpoch,
      'is_favorite': 0,
      'mode': result.mode.dbValue,
    });
    await database.execute('''
      DELETE FROM history WHERE id NOT IN (
        SELECT id FROM history ORDER BY created_at DESC LIMIT 50
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getRecent({int limit = 10}) async {
    final database = await db;
    return database.query(
      'history',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final database = await db;
    await database.update(
      'history',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final database = await db;
    return database.query(
      'history',
      where: 'is_favorite = 1',
      orderBy: 'created_at DESC',
    );
  }
}
