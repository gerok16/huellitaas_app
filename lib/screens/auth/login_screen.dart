import 'package:flutter/material.dart';

/// Pantalla temporal. Se reemplaza por el formulario real en HU-02.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: const Center(child: Text('Aquí irá el login (HU-02)')),
    );
  }
}
