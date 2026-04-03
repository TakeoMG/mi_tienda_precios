import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/producto.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tienda.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // VERSIÓN 3 para incluir imagenPath
    return await openDatabase(path, version: 3, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        categoria TEXT NOT NULL,
        descripcion TEXT,
        codigoBarras TEXT,
        imagenPath TEXT,
        fechaCreacion TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE productos ADD COLUMN codigoBarras TEXT");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE productos ADD COLUMN imagenPath TEXT");
    }
  }

  Future<int> create(Producto producto) async {
    final db = await instance.database;
    return await db.insert('productos', producto.toMap());
  }

  Future<Producto?> getProductoByNombre(String nombre) async {
    final db = await instance.database;
    final maps = await db.query('productos', where: 'nombre = ?', whereArgs: [nombre.trim()]);
    if (maps.isNotEmpty) return Producto.fromMap(maps.first);
    return null;
  }

  Future<Producto?> getProductoByCodigo(String codigo) async {
    final db = await instance.database;
    final maps = await db.query('productos', where: 'codigoBarras = ?', whereArgs: [codigo]);
    if (maps.isNotEmpty) return Producto.fromMap(maps.first);
    return null;
  }

  Future<List<Producto>> readAllProductos() async {
    final db = await instance.database;
    final result = await db.query('productos', orderBy: 'nombre ASC');
    return result.map((json) => Producto.fromMap(json)).toList();
  }

  Future<int> update(Producto producto) async {
    final db = await instance.database;
    return db.update('productos', producto.toMap(), where: 'id = ?', whereArgs: [producto.id]);
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAll() async {
    final db = await instance.database;
    return await db.delete('productos');
  }
}