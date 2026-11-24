import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Usuario> iniciarSesion(String correo, String password) async {
    final respuesta = await _supabase.auth.signInWithPassword(
      email: correo.trim(),
      password: password,
    );

    final usuarioAuth = respuesta.user;

    if (usuarioAuth == null) {
      throw Exception('No se pudo iniciar sesión.');
    }

    final perfil = await _supabase
        .from('usuarios')
        .select()
        .eq('id', usuarioAuth.id)
        .maybeSingle();

    if (perfil == null) {
      await _supabase.auth.signOut();
      throw Exception('No se encontró el perfil del usuario.');
    }

    final usuario = Usuario.fromMap(perfil);

    if (!usuario.activo) {
      await _supabase.auth.signOut();
      throw Exception('Tu cuenta está desactivada.');
    }

    return usuario;
  }

  Future<Usuario?> obtenerPerfilActual() async {
    final actual = _supabase.auth.currentUser;
    if (actual == null) return null;

    final perfil = await _supabase
        .from('usuarios')
        .select()
        .eq('id', actual.id)
        .maybeSingle();

    if (perfil == null) return null;

    final usuario = Usuario.fromMap(perfil);
    if (!usuario.activo) {
      await cerrarSesion();
      return null;
    }

    return usuario;
  }

  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  // ---------------------------------------------------------------------
  // VERIFICACIÓN DE CORREO (código de 6 dígitos)
  // ---------------------------------------------------------------------

  /// Confirma el correo con el código recibido. Si es correcto,
  /// Supabase abre la sesión automáticamente.
  Future<void> verificarCodigoRegistro({
    required String correo,
    required String codigo,
  }) async {
    final respuesta = await _supabase.auth.verifyOTP(
      email: correo.trim(),
      token: codigo.trim(),
      type: OtpType.signup,
    );

    if (respuesta.session == null) {
      throw Exception('No se pudo verificar el código.');
    }
  }

  Future<void> reenviarCodigoRegistro(String correo) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: correo.trim(),
    );
  }

  // ---------------------------------------------------------------------
  // RECUPERAR CONTRASEÑA (código de 6 dígitos)
  // ---------------------------------------------------------------------

  Future<void> solicitarRecuperacion(String correo) async {
    await _supabase.auth.resetPasswordForEmail(correo.trim());
  }

  /// Verifica el código, cambia la contraseña y cierra la sesión temporal
  /// para que el usuario ingrese con su nueva contraseña.
  Future<void> restablecerPassword({
    required String correo,
    required String codigo,
    required String nuevaPassword,
  }) async {
    await _supabase.auth.verifyOTP(
      email: correo.trim(),
      token: codigo.trim(),
      type: OtpType.recovery,
    );

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: nuevaPassword),
      );
    } finally {
      await _supabase.auth.signOut();
    }
  }
}
