import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  Usuario? usuario;
  bool cargando = true;

  bool get estaAutenticado => usuario != null;
  bool get esDueno => usuario?.esDueno ?? false;

  Future<void> inicializar() async {
    await cargarPerfil();
  }

  /// Carga el perfil de la sesión actual de Supabase.
  /// Se usa al abrir la app y después de verificar un código.
  /// Devuelve true si se encontró un perfil activo.
  Future<bool> cargarPerfil() async {
    try {
      usuario = await _service.obtenerPerfilActual();
    } catch (_) {
      usuario = null;
    }

    cargando = false;
    notifyListeners();
    return usuario != null;
  }

  Future<void> iniciarSesion(String correo, String password) async {
    cargando = true;
    notifyListeners();

    try {
      usuario = await _service.iniciarSesion(correo, password);
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async {
    await _service.cerrarSesion();
    usuario = null;
    notifyListeners();
  }
}

final authProvider = AuthProvider();
