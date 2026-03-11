// lib/shared/isar/isar_service.dart
// Note: Named IsarService for guide compatibility, but backed by sqflite.

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../features/goals/models/goal.dart';

class IsarService {
  IsarService._(); // singleton — private constructor

  static final IsarService instance = IsarService._();

  Database? _db;

  // Call once in main() before runApp()
  Future<void> init() async {
    if (_db != null) return; // already open

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'keepyourvow.db');

    _db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        identityPhrase TEXT NOT NULL,
        endDate TEXT NOT NULL,
        strengthenFocus INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        isDaily INTEGER NOT NULL DEFAULT 1,
        scheduledDays TEXT NOT NULL DEFAULT '',
        createdAt TEXT NOT NULL,
        goalId INTEGER,
        frequency TEXT NOT NULL DEFAULT 'daily',
        startTime TEXT,
        currentStreak INTEGER NOT NULL DEFAULT 0,
        longestStreak INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 1,
        loggedAt TEXT NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_habit_logs_date ON habit_logs(habitId, date)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE habits ADD COLUMN frequency TEXT NOT NULL DEFAULT 'daily'");
      await db.execute('ALTER TABLE habits ADD COLUMN startTime TEXT');
      await db.execute('DROP TABLE IF EXISTS guardian_config');
    }
  }

  Database get db {
    assert(_db != null, 'IsarService.init() must be called before using db');
    return _db!;
  }

  // ─── Goal helpers ──────────────────────────────────────────────────────────
  Future<int> insertGoal(Goal goal) async {
    return await _db!.insert('goals', goal.toMap());
  }

  Future<Goal?> getActiveGoal() async {
    final rows = await _db!.query('goals', orderBy: 'createdAt DESC', limit: 1);
    if (rows.isEmpty) return null;
    return Goal.fromMap(rows.first);
  }

  Future<List<Goal>> getAllGoals() async {
    final rows = await _db!.query('goals', orderBy: 'endDate ASC');
    return rows.map(Goal.fromMap).toList();
  }

  Future<Goal?> getGoalById(int goalId) async {
    final rows =
        await _db!.query('goals', where: 'id = ?', whereArgs: [goalId]);
    if (rows.isEmpty) return null;
    return Goal.fromMap(rows.first);
  }

  Future<void> updateGoal(Goal goal) async {
    await _db!.update('goals', goal.toMap(),
        where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> deleteGoal(int goalId) async {
    await _db!.delete('goals', where: 'id = ?', whereArgs: [goalId]);
  }
}
