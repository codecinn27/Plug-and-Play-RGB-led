import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'udp_messages.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT,
            timestamp TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE device_info (
            id INTEGER PRIMARY KEY,
            device_id TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertMessage(String content) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<List<String>> getMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('messages', orderBy: 'id DESC');

    return maps.map((map) => map['content'] as String).toList();
  }

  static Future<void> clearMessages() async {
    final db = await DBHelper.database;
    await db.delete('messages');
  }

  // Save or update latest device ID
  static Future<void> saveDeviceId(String deviceId) async {
    final db = await database;
    await db.insert(
      'device_info',
      {'id': 1, 'device_id': deviceId},
      conflictAlgorithm: ConflictAlgorithm.replace, // ✅ always keep latest
    );
  }

  // Retrieve saved device ID (returns null if not found)
  static Future<String?> getSavedDeviceId() async {
    final db = await database;
    final List<Map<String, dynamic>> result =
        await db.query('device_info', where: 'id = ?', whereArgs: [1]);

    if (result.isNotEmpty) {
      return result.first['device_id'] as String;
    }
    return null;
  }


}
