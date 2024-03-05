import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/crud/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

class NotesService {
  Database? _db;
  List<DatabaseNote> _notes = [];
  //creating a singleton
  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance();
  factory NotesService() => _shared;

  final _notesStreamController =
      StreamController<List<DatabaseNote>>.broadcast();
  Stream<List<DatabaseNote>> get allNotes => _notesStreamController.stream;
  Future<DatabaseUser?> getOrCreateUser({required String email}) async {
    try {
      final user = await getUser(email: email);
      return user;
    } on CouldNotFindUser {
      final createdUser = createUser(email: email);
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String text,
  }) async {
    await _ensureDbIsOpen();
    final db = getDtabaseorThrow();
    //make sure note exists
    await getNote(id: note.id);
    //update db
    final updatesCount = await db?.update(noteTable, {
      textColumn: text,
      isSyncedWithCloudColumn: 0,
    });
    if (updatesCount == 0) {
      throw CouldNotUpdateNote();
    } else {
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  Future<Iterable<DatabaseNote>> getAllNotes() async {
    final db = getDtabaseorThrow();
    final notes = await db?.query(noteTable);
    if (notes != null) {
      return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
    }
    return [];
  }

  Future<DatabaseNote> getNote({required int id}) async {
    final db = getDtabaseorThrow();
    final notes = await db?.query(
      noteTable,
      limit: 1,
      where: 'id=?',
      whereArgs: [id],
    );
    if (notes != null && notes.isEmpty) {
      throw CouldNotFindNote();
    } else if (notes != null) {
      final note = DatabaseNote.fromRow(notes.first);
      _notes.removeWhere((node) => note.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
    return const DatabaseNote(
      id: 0,
      userId: 0,
      text: '',
      isSyncedWithCloud: false,
    );
  }

  Future<int?> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = getDtabaseorThrow();
    final numberOfDeletion = await db?.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return numberOfDeletion;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = getDtabaseorThrow();
    final deleteCount = await db?.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deleteCount == 0) {
      throw CouldNotDeleteNote();
    } else {
      final count = _notes.length;
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
    final db = getDtabaseorThrow();
    final dbUser = await getUser(email: owner.email);
    // make sure owner exists in the database with the correct id
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }
    const text = '';
    // create the note
    final noteId = await db?.insert(noteTable, {
      userIdCoulumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });
    final note = DatabaseNote(
      id: noteId!,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );
    _notes.add(note);
    _notesStreamController.add(_notes);
    return note;
  }

  Future<DatabaseUser?> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = getDtabaseorThrow();
    final result = await db?.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (result != null && result.isEmpty) {
      throw CouldNotFindUser();
    } else if (result != null) {
      return DatabaseUser.fromRow(result.first);
    }
    return null;
  }

  Future<DatabaseUser> createUser({required String email}) async {
    final db = getDtabaseorThrow();
    final result = await db?.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (result != null && result.isNotEmpty) {
      throw UserAlreadyExists();
    }
    final userId =
        await db?.insert(userTable, {emailColumn: email.toLowerCase()});
    return DatabaseUser(id: userId!, email: email);
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = getDtabaseorThrow();
    final deleteCount = await db?.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deleteCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Database? getDtabaseorThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseNotOpenException();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseNotOpenException();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      //do nothing
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbpath = join(docsPath.path, dbName);
      final db = await openDatabase(dbpath);
      _db = db;

      await db.execute(createUserTable);

      await db.execute(createNotesTable);
      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }
}

@immutable
class DatabaseUser extends Equatable {
  final int id;
  final String email;
  const DatabaseUser({
    required this.id,
    required this.email,
  });
  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;
  @override
  String toString() => 'Person, ID: $id, email: $email';
  @override
  List<Object?> get props => [id, email];
}

class DatabaseNote extends Equatable {
  final int id;
  final int userId;
  final String text;
  final isSyncedWithCloud;

  const DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });
  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdCoulumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;
  @override
  String toString() =>
      'Note, ID: $id, userId: $userId, isSyncedWithCloud: $isSyncedWithCloud, text:$text';
  @override
  List<Object?> get props => [id, userId, text, isSyncedWithCloud];
}

const dbName = 'notes.db';
const userTable = 'user';
const noteTable = 'note';
const idColumn = 'id';
const emailColumn = 'email';
const userIdCoulumn = 'user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'isSyncedWithCloud';
const createNotesTable = '''CREATE TABLE IF NOT EXIST "note" (
          "id"	INTEGER NOT NULL,
          "user_id"	NUMERIC NOT NULL,
          "text"	TEXT,
          "is_synced_with_cloud"	INTEGER NOT NULL,
          FOREIGN KEY("user_id") REFERENCES "user"("id"),
          PRIMARY KEY("id" AUTOINCREMENT)
        );
       ''';
const createUserTable = '''CREATE TABLE IF NOT EXIST "user" (
          "id"	INTEGER NOT NULL,
          "email"	TEXT NOT NULL UNIQUE,
          PRIMARY KEY("id" AUTOINCREMENT)
        );
        ''';
