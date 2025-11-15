// lib/services/db_helper.dart

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/contact.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static Database? _db;
  static const String _dbName = 'contacts.db';
  static const int _dbVersion = 1;
  static const String tableContacts = 'contacts';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableContacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prenom TEXT NOT NULL,
        nom TEXT NOT NULL,
        telephone TEXT NOT NULL,
        email TEXT NOT NULL
      )
    ''');
  }

  // CRUD
  Future<int> insertContact(Contact contact) async {
    final db = await database;
    return await db.insert(tableContacts, contact.toMap());
  }

  Future<int> updateContact(Contact contact) async {
    final db = await database;
    return await db.update(
      tableContacts,
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    return await db.delete(
      tableContacts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Contact>> getAllContacts() async {
    final db = await database;
    final maps = await db.query(
      tableContacts,
      orderBy: 'prenom COLLATE NOCASE ASC, nom COLLATE NOCASE ASC',
    );
    return maps.map((m) => Contact.fromMap(m)).toList();
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete(tableContacts);
  }
}
