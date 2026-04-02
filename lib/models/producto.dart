class Producto {
  int? id;
  String nombre;
  double precio;
  String categoria;
  String? descripcion;
  String? codigoBarras;
  DateTime fechaCreacion;

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    required this.categoria,
    this.descripcion,
    this.codigoBarras,
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
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
    );
  }
}