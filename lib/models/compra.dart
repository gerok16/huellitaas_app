import 'producto.dart';

/// Una línea de una compra ya registrada.
class DetalleCompra {
  final int productoId;
  final String nombreProducto;
  final int cantidad;
  final double costoUnitario;
  final double subtotal;

  const DetalleCompra({
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.costoUnitario,
    required this.subtotal,
  });

  factory DetalleCompra.fromMap(Map<String, dynamic> map) {
    final cantidad = (map['cantidad'] as num?)?.toInt() ?? 0;
    final costo = _aDouble(map['costo_unitario']);

    return DetalleCompra(
      productoId: (map['producto_id'] as num?)?.toInt() ?? 0,
      nombreProducto: map['nombre_producto']?.toString() ?? 'Producto',
      cantidad: cantidad,
      costoUnitario: costo,
      subtotal:
      map['subtotal'] == null ? costo * cantidad : _aDouble(map['subtotal']),
    );
  }

  String get costoTexto => 'Bs. ${costoUnitario.toStringAsFixed(2)}';
  String get subtotalTexto => 'Bs. ${subtotal.toStringAsFixed(2)}';
}

/// Una compra a un proveedor (reposición de stock).
class Compra {
  final String id;
  final String codigo;
  final int? proveedorId;
  final String proveedorNombre;
  final DateTime? fecha;
  final double total;
  final String estado;
  final String notas;
  final List<DetalleCompra> detalles;

  const Compra({
    required this.id,
    required this.codigo,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.fecha,
    required this.total,
    required this.estado,
    required this.notas,
    required this.detalles,
  });

  factory Compra.fromMap(Map<String, dynamic> map) {
    final proveedor = map['proveedores'];
    final crudos = (map['detalle_compras'] as List?) ?? const [];

    return Compra(
      id: map['id'].toString(),
      codigo: map['codigo']?.toString() ?? '',
      proveedorId: (map['proveedor_id'] as num?)?.toInt(),
      proveedorNombre: proveedor is Map
          ? proveedor['nombre']?.toString() ?? 'Proveedor'
          : 'Proveedor',
      fecha: DateTime.tryParse(map['fecha']?.toString() ?? '')?.toLocal(),
      total: _aDouble(map['total']),
      estado: map['estado']?.toString() ?? 'recibida',
      notas: map['notas']?.toString() ?? '',
      detalles: crudos
          .map((d) => DetalleCompra.fromMap(Map<String, dynamic>.from(d as Map)))
          .toList(),
    );
  }

  bool get esAnulada => estado == 'anulada';

  int get unidades => detalles.fold(0, (suma, d) => suma + d.cantidad);

  String get totalTexto => 'Bs. ${total.toStringAsFixed(2)}';

  String get fechaTexto {
    final f = fecha;
    if (f == null) return 'Fecha no disponible';
    return '${_dos(f.day)}/${_dos(f.month)}/${f.year}';
  }

  String get horaTexto {
    final f = fecha;
    if (f == null) return '';
    return '${_dos(f.hour)}:${_dos(f.minute)}';
  }

  String get fechaHoraTexto =>
      fecha == null ? fechaTexto : '$fechaTexto · $horaTexto';

  static String _dos(int n) => n.toString().padLeft(2, '0');
}

/// Un producto que se está agregando a una compra nueva (borrador).
class ItemCompra {
  final Producto producto;
  int cantidad;
  double costoUnitario;

  ItemCompra({
    required this.producto,
    this.cantidad = 1,
    required this.costoUnitario,
  });

  double get subtotal => cantidad * costoUnitario;

  Map<String, dynamic> toJson() => {
    'producto_id': producto.id,
    'cantidad': cantidad,
    'costo_unitario': costoUnitario,
  };
}

double _aDouble(dynamic valor) {
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor?.toString() ?? '') ?? 0;
}