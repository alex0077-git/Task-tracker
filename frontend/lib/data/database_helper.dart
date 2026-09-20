import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// ignore: unnecessary_import
// Mobile plugin registration / default factory; FFI re-exports the same types.
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'password_hasher.dart';

/// Local SQLite access — replaces the Django ORM for the shipped app.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'task_tracker.db';
  static const _dbVersion = 1;

  /// Default manager seeded on first launch (empty database).
  static const seedManagerUsername = 'manager';
  static const seedManagerPassword = 'manager123';

  Database? _database;
  static bool _factoryReady = false;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    _ensureFactory();
    final documents = await getApplicationDocumentsDirectory();
    final path = p.join(documents.path, _dbName);
    final db = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
    await _seedIfEmpty(db);
    return db;
  }

  static void _ensureFactory() {
    if (_factoryReady) {
      return;
    }
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite is not supported on web in this offline build.',
      );
    }
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _factoryReady = true;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  email TEXT NOT NULL DEFAULT '',
  is_manager INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
)
''');
    await db.execute('''
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  priority TEXT NOT NULL,
  status TEXT NOT NULL,
  due_date TEXT NOT NULL,
  assignee_id INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (assignee_id) REFERENCES users (id)
)
''');
    await db.execute('''
CREATE TABLE task_comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER NOT NULL,
  author_id INTEGER NOT NULL,
  body TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
  FOREIGN KEY (author_id) REFERENCES users (id)
)
''');
  }

  Future<void> _seedIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) AS c FROM users'),
    );
    if (count != null && count > 0) {
      return;
    }
    await db.insert('users', {
      'username': seedManagerUsername,
      'password_hash': PasswordHasher.hash(seedManagerPassword),
      'email': '',
      'is_manager': 1,
      'is_active': 1,
    });
  }
}
