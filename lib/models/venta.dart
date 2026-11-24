import 'detalle_venta.dart';
import 'estado_venta.dart';
import 'eventoestado.dart';

class Venta {
  final String id;
  final String codigo;
  final DateTime? fecha;
  final double total;

  final String? usuarioId;
  final String? clienteId;

  final String? clienteNombre;
  final String? clienteCorreo;
  final String? vendedorNombre;

  final EstadoVenta estado;
  final String metodoPago;
  final String tipoEntrega;
  final int? sucursalId;
  final int? direccionEntregaId;
  final String notas;
  final String motivoAnulacion;

  final List<DetalleVenta> detalles;
  final List<EventoEstado> historial;

  const Venta({
    required this.id,
    required this.codigo,
    required this.fecha,
    required this.total,
    required this.detalles,
    this.usuarioId,
    this.clienteId,
    this.clienteNombre,
    this.clienteCorreo,
    this.vendedorNombre,
    this.estado = EstadoVenta.entregado,
    this.metodoPago = 'efectivo',
    this.tipoEntrega = 'recojo',
    this.sucursalId,
    this.direccionEntregaId,
    this.notas = '',
    this.motivoAnulacion = '',
    this.historial = const [],
  });

  factory Venta.fromMap(Map<String, dynamic> map) {
    final detallesCrudos = (map['detalle_ventas'] as List?) ?? [];

    final historialCrudo = (map['venta_estados'] as List?) ?? [];

    return Venta(
      id: map['id']?.toString() ?? '',
      codigo: map['codigo']?.toString() ?? '',
      fecha: DateTime.tryParse(map['fecha']?.toString() ?? '')?.toLocal(),
      total: _numero(map['total']),

      usuarioId: map['usuario_id']?.toString(),
      clienteId: map['cliente_id']?.toString(),

      estado: EstadoVenta.desdeTexto(map['estado']?.toString()),

      metodoPago: map['metodo_pago']?.toString() ?? 'efectivo',

      tipoEntrega: map['tipo_entrega']?.toString() ?? 'recojo',

      sucursalId: _entero(map['sucursal_id']),

      direccionEntregaId: _entero(map['direccion_entrega_id']),

      notas: map['notas']?.toString() ?? '',

      motivoAnulacion: map['motivo_anulacion']?.toString() ?? '',

      detalles: detallesCrudos.map((d) {
        return DetalleVenta.fromMap(Map<String, dynamic>.from(d as Map));
      }).toList(),

      historial: historialCrudo.map((e) {
        return EventoEstado.fromMap(Map<String, dynamic>.from(e as Map));
      }).toList(),
    );
  }

  Venta copyWith({
    String? clienteNombre,
    String? clienteCorreo,
    String? vendedorNombre,
  }) {
    return Venta(
      id: id,
      codigo: codigo,
      fecha: fecha,
      total: total,
      usuarioId: usuarioId,
      clienteId: clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteCorreo: clienteCorreo ?? this.clienteCorreo,
      vendedorNombre: vendedorNombre ?? this.vendedorNombre,
      estado: estado,
      metodoPago: metodoPago,
      tipoEntrega: tipoEntrega,
      sucursalId: sucursalId,
      direccionEntregaId: direccionEntregaId,
      notas: notas,
      motivoAnulacion: motivoAnulacion,
      detalles: detalles,
      historial: historial,
    );
  }

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

  String get metodoPagoTexto {
    switch (metodoPago) {
      case 'qr':
        return 'Código QR';
      case 'transferencia':
        return 'Transferencia';
      case 'tarjeta':
        return 'Tarjeta';
      default:
        return 'Efectivo';
    }
  }

  String get tipoEntregaTexto =>
      tipoEntrega == 'domicilio' ? 'A domicilio' : 'Recojo en sucursal';

  static double _numero(dynamic valor) {
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor?.toString() ?? '') ?? 0;
  }

  static int? _entero(dynamic valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor.toString());
  }

  static String _dos(int n) => n.toString().padLeft(2, '0');
}
