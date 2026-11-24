import 'package:supabase_flutter/supabase_flutter.dart';

/// Convierte los errores de Supabase (en inglés) a mensajes claros en español.
String traducirErrorAuth(Object error) {
  final texto = error is AuthException
      ? error.message
      : error.toString().replaceFirst('Exception: ', '');
  final m = texto.toLowerCase();

  if (m.contains('socketexception') ||
      m.contains('failed host lookup') ||
      m.contains('clientexception')) {
    return 'Sin conexión a internet. Revisa tu red e inténtalo de nuevo.';
  }
  if (m.contains('invalid login credentials')) {
    return 'Correo o contraseña incorrectos.';
  }
  if (m.contains('email not confirmed')) {
    return 'Tu correo aún no está verificado.';
  }
  if (m.contains('user already registered') ||
      m.contains('already been registered')) {
    return 'Ese correo ya está registrado. Inicia sesión o recupera tu contraseña.';
  }
  if (m.contains('token has expired') ||
      (m.contains('invalid') && m.contains('token'))) {
    return 'El código es incorrecto o ya venció. Pide uno nuevo.';
  }
  if (m.contains('for security purposes') ||
      (m.contains('after') && m.contains('seconds'))) {
    return 'Espera un momento antes de pedir otro código.';
  }
  if (m.contains('rate limit')) {
    return 'Se enviaron demasiados correos. Inténtalo de nuevo más tarde.';
  }
  if (m.contains('error sending') && m.contains('email')) {
    return 'No pudimos enviar el correo. Inténtalo de nuevo en unos minutos.';
  }
  if (m.contains('different from the old password')) {
    return 'La nueva contraseña debe ser distinta a la anterior.';
  }
  if (m.contains('at least') && m.contains('characters')) {
    return 'La contraseña debe tener al menos 6 caracteres.';
  }
  if (m.contains('unable to validate email') ||
      (m.contains('email address') && m.contains('invalid'))) {
    return 'Ingresa un correo electrónico válido.';
  }

  return texto;
}

/// true si el error significa "el correo todavía no fue verificado".
bool esCorreoNoConfirmado(Object error) {
  return error is AuthException &&
      error.message.toLowerCase().contains('email not confirmed');
}
