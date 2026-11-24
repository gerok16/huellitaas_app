class Proveedor {
  final int id;
  final String nombre;
  final String contacto;
  final String telefono;
  final String correo;
  final String direccion;
  final String nit;
  final bool activo;

  const Proveedor({
    required this.id,
    required this.nombre,
    this.contacto = '',
    this.telefono = '',
    this.correo = '',
    this.direccion = '',
    this.nit = '',
    this.activo = true,
  });

  factory Proveedor.fromMap(Map<String, dynamic> map) {
    return Proveedor(
      id: (map['id'] as num).toInt(),
      nombre: map['nombre']?.toString() ?? '',
      contacto: map['contacto']?.toString() ?? '',
      telefono: map['telefono']?.toString() ?? '',
      correo: map['correo']?.toString() ?? '',
      direccion: map['direccion']?.toString() ?? '',
      nit: map['nit']?.toString() ?? '',
      activo: map['activo'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre.trim(),
      'contacto': contacto.trim(),
      'telefono': telefono.trim(),
      'correo': correo.trim(),
      'direccion': direccion.trim(),
      'nit': nit.trim(),
      'activo': activo,
    };
  }
}