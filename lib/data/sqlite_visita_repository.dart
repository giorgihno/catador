import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/visita.dart';
import 'app_exception.dart';
import 'visita_repository.dart';

/// Implementación de [VisitaRepository] con SQLite (paquete sqflite).
///
/// Guarda cada visita con sus metadatos: ruta de la imagen y coordenadas.
class SqliteVisitaRepository implements VisitaRepository {
  static const String _tabla = 'visitas';
  static const int _version = 1;

  Database? _db;

  /// Abre la base una sola vez y reutiliza la conexión.
  Future<Database> _abrir() async {
    final existente = _db;
    if (existente != null) return existente;

    final carpeta = await getDatabasesPath();
    final db = await openDatabase(
      p.join(carpeta, 'catador.db'),
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tabla (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            restaurante TEXT NOT NULL,
            pedido TEXT NOT NULL,
            me_gusto TEXT,
            no_me_gusto TEXT,
            calificacion INTEGER NOT NULL,
            ruta_foto TEXT,
            latitud REAL,
            longitud REAL,
            fecha TEXT NOT NULL
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  @override
  Future<List<Visita>> obtenerTodas() async {
    try {
      final db = await _abrir();
      final filas = await db.query(_tabla, orderBy: 'fecha DESC');
      return filas.map(Visita.fromMap).toList();
    } on DatabaseException catch (e) {
      throw AppException('No se pudieron leer tus visitas: ${e.toString()}');
    }
  }

  @override
  Future<List<Visita>> obtenerDeRestaurante(
    String restaurante, {
    int? excluirId,
  }) async {
    try {
      final db = await _abrir();
      final filas = await db.query(
        _tabla,
        where: excluirId == null
            ? 'restaurante = ? COLLATE NOCASE'
            : 'restaurante = ? COLLATE NOCASE AND id != ?',
        whereArgs: excluirId == null ? [restaurante] : [restaurante, excluirId],
        orderBy: 'fecha DESC',
      );
      return filas.map(Visita.fromMap).toList();
    } on DatabaseException catch (e) {
      throw AppException('No se pudo leer el historial: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> obtenerRestaurantes() async {
    try {
      final db = await _abrir();
      final filas = await db.rawQuery(
        'SELECT restaurante FROM $_tabla '
        'GROUP BY restaurante COLLATE NOCASE '
        'ORDER BY restaurante COLLATE NOCASE',
      );
      return filas.map((fila) => fila['restaurante'] as String).toList();
    } on DatabaseException catch (e) {
      throw AppException('No se pudieron leer los restaurantes: ${e.toString()}');
    }
  }

  @override
  Future<int> insertar(Visita visita) async {
    try {
      final db = await _abrir();
      final datos = visita.toMap()..remove('id');
      return await db.insert(_tabla, datos);
    } on DatabaseException catch (e) {
      throw AppException('No se pudo guardar la visita: ${e.toString()}');
    }
  }

  @override
  Future<void> eliminar(int id) async {
    try {
      final db = await _abrir();
      await db.delete(_tabla, where: 'id = ?', whereArgs: [id]);
    } on DatabaseException catch (e) {
      throw AppException('No se pudo eliminar la visita: ${e.toString()}');
    }
  }
}
