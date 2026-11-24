/// Una línea de una venta (producto, cantidad y precio al momento de vender).
class DetalleVenta {
  final String id;
  final int? productoId;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  const DetalleVenta({
    required this.id,
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleVenta.fromMap(Map<String, dynamic> map) {
    final cantidad = (map['cantidad'] as num?)?.toInt() ?? 0;
    final precio = _aDouble(map['precio_unitario']);
    final subtotal = map['subtotal'] == null
        ? precio * cantidad
        : _aDouble(map['subtotal']);

    return DetalleVenta(
      id: map['id']?.toString() ?? '',
      productoId: (map['producto_id'] as num?)?.toInt(),
      nombreProducto: map['nombre_producto']?.toString() ?? 'Producto',
      cantidad: cantidad,
      precioUnitario: precio,
      subtotal: subtotal,
    );
  }

  String get precioTexto => 'Bs. ${precioUnitario.toStringAsFixed(2)}';
  String get subtotalTexto => 'Bs. ${subtotal.toStringAsFixed(2)}';
}

double _aDouble(dynamic valor) {
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor?.toString() ?? '') ?? 0;
}
