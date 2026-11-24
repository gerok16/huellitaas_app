
class Producto {
  final int id;
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;
  final int stockMinimo;
  final String descripcion;
  final String imagenUrl;
  final bool activo;
  final double costo;
  final DateTime? fechaModificacion;

  const Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    required this.stockMinimo,
    required this.descripcion,
    required this.imagenUrl,
    required this.activo,
    this.costo = 0,
    this.fechaModificacion,
  });

  bool get disponible => stock > 0;

  bool get stockBajo => stock <= stockMinimo;

  String get precioTexto => 'Bs. ${precio.toStringAsFixed(2)}';

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: (map['id'] as num).toInt(),
      nombre: map['nombre'] ?? '',
      categoria: map['categoria'] ?? '',
      precio: (map['precio'] as num).toDouble(),
      stock: (map['stock'] as num).toInt(),
      stockMinimo: (map['stock_minimo'] as num?)?.toInt() ?? 0,
      descripcion: map['descripcion'] ?? '',
      imagenUrl: map['imagen_url'] ?? '',
      activo: map['activo'] ?? true,
      costo: (map['costo'] as num?)?.toDouble() ?? 0,
      fechaModificacion: map['fecha_modificacion'] == null
          ? null
          : DateTime.parse(map['fecha_modificacion'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'categoria': categoria,
      'precio': precio,
      'stock': stock,
      'stock_minimo': stockMinimo,
      'descripcion': descripcion,
      'imagen_url': imagenUrl,
      'activo': activo,
    };
  }
}
