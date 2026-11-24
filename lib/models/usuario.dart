class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final bool activo;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.activo,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'].toString(),
      nombre: map['nombre'] ?? '',
      correo: map['correo'] ?? '',
      rol: map['rol'] ?? 'cliente',
      activo: map['activo'] == true,
    );
  }

  bool get esDueno => rol == 'dueno';

  bool get esEmpleado => rol == 'empleado';

  bool get esCliente => rol == 'cliente';

  bool get esPersonal => esDueno || esEmpleado;
}