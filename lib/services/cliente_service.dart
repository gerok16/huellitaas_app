import 'package:supabase_flutter/supabase_flutter.dart';

class ClienteService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Crea la cuenta del cliente.
  ///
  /// Devuelve true si hay que verificar el correo con un código
  /// (cuando "Confirm email" está activado en Supabase) y false si la
  /// sesión ya quedó abierta.
  Future<bool> registrarCliente({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    final respuesta = await _supabase.auth.signUp(
      email: correo.trim(),
      password: password,
      data: {
        'nombre': nombre.trim(),
      },
    );

    final usuario = respuesta.user;

    if (usuario == null) {
      throw Exception('No se pudo crear la cuenta.');
    }

    // Con la confirmación activada, Supabase no avisa con un error si el
    // correo ya existe (por seguridad): devuelve un usuario sin identidades.
    if ((usuario.identities ?? []).isEmpty) {
      throw Exception(
        'Ese correo ya está registrado. '
            'Inicia sesión o recupera tu contraseña.',
      );
    }

    return respuesta.session == null;
  }

  Future<List<Map<String, dynamic>>> obtenerClientes() async {
    final respuesta = await _supabase
        .from('usuarios')
        .select('id,nombre,correo')
        .eq('rol', 'cliente')
        .eq('activo', true)
        .order('nombre');

    return List<Map<String, dynamic>>.from(respuesta);
  }
}
