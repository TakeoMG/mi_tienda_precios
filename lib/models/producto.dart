class Producto {
  int? id;
  String nombre;
  double precio;
  String categoria;
  String? descripcion;
  String? codigoBarras;
  String? imagenPath; // <--- Nuevo campo
  DateTime fechaCreacion;

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    required this.categoria,
    this.descripcion,
    this.codigoBarras,
    this.imagenPath,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'categoria': categoria,
      'descripcion': descripcion,
      'codigoBarras': codigoBarras,
      'imagenPath': imagenPath,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      precio: map['precio'],
      categoria: map['categoria'],
      descripcion: map['descripcion'],
      codigoBarras: map['codigoBarras'],
      imagenPath: map['imagenPath'],
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
    );
  }
}