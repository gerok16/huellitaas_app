import 'estado_venta.dart';

class EventoEstado {
  final String id;
  final String ventaId;
  final EstadoVenta estado;
  final String? usuarioId;
  final String nota;
  final DateTime? fecha;

  const EventoEstado({
    required this.id,
    required this.ventaId,
    required this.estado,
    this.usuarioId,
    required this.nota,
    this.fecha,
  });

  factory EventoEstado.fromMap(Map<String, dynamic> map) {
    return EventoEstado(
      id: map['id']?.toString() ?? '',
      ventaId: map['venta_id']?.toString() ?? '',
      estado: EstadoVenta.desdeTexto(map['estado']?.toString()),
      usuarioId: map['usuario_id']?.toString(),
      nota: map['nota']?.toString() ?? '',
      fecha: DateTime.tryParse(map['fecha']?.toString() ?? '')?.toLocal(),
    );
  }

  String get fechaTexto {
    if (fecha == null) return 'Fecha no disponible';

    final f = fecha!;
    final dia = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    final hora = f.hour.toString().padLeft(2, '0');
    final minuto = f.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${f.year} $hora:$minuto';
  }
}
