class Producto {
  int? id;
  String nombre;
  double precio;
  String categoria;
  String? descripcion;
  DateTime fechaCreacion;

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    required this.categoria,
    this.descripcion,
    required this.fechaCreacion,
  });

  // Convertir a Map para la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'categoria': categoria,
      'descripcion': descripcion,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  // Crear objeto desde Map
  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      precio: map['precio'],
      categoria: map['categoria'],
      descripcion: map['descripcion'],
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
    );
  }
}