
class Sucursal {
  final int id;
  final String nombre;
  final String direccion;
  final double latitud;
  final double longitud;
  final String telefono;
  final String horario;

  Sucursal({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.telefono,
    required this.horario,
  });

  factory Sucursal.fromMap(Map<String, dynamic> map) {
    return Sucursal(
      id: map['id'] as int,
      nombre: map['nombre'] ?? '',
      direccion: map['direccion'] ?? '',
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
      telefono: map['telefono'] ?? '',
      horario: map['horario'] ?? '',
    );
  }
}
