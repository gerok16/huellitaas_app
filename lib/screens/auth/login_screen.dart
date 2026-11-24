import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/auth_errores.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _password = TextEditingController();

  bool _ocultarPassword = true;
  bool _cargando = false;

  @override
  void dispose() {
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _ingresar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      await context.read<AuthProvider>().iniciarSesion(
        _correo.text.trim(),
        _password.text,
      );

      if (!mounted) return;

      final usuario = context.read<AuthProvider>().usuario;

      context.go(usuario?.esCliente == true ? '/cliente' : '/inicio');
    } catch (e) {
      if (!mounted) return;

      // Cuenta creada pero con el correo sin verificar: se manda un código
      // nuevo y se lleva al cliente a la pantalla de verificación.
      if (esCorreoNoConfirmado(e)) {
        final correo = _correo.text.trim();

        try {
          await AuthService().reenviarCodigoRegistro(correo);
        } catch (_) {
          // Si el reenvío falla (por ejemplo, límite de tiempo), igual
          // se muestra la pantalla: allí puede pedir otro código.
        }

        if (!mounted) return;

        _mensaje('Tu correo aún no está verificado. Te enviamos un código.');
        context.go('/verificar', extra: correo);
        return;
      }

      _mensaje(traducirErrorAuth(e));
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.pets,
                    size: 75,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    '¡Bienvenido a Huellitas!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 28),

                  TextFormField(
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu correo.';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Ingresa un correo válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _password,
                    obscureText: _ocultarPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _ocultarPassword = !_ocultarPassword;
                          });
                        },
                        icon: Icon(
                          _ocultarPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña.';
                      }
                      return null;
                    },
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go(
                        '/recuperar',
                        extra: _correo.text.trim(),
                      ),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  const SizedBox(height: 8),

                  FilledButton(
                    onPressed: _cargando ? null : _ingresar,
                    child: _cargando
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text('Ingresar'),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(
                        child: Text('¿No tienes cuenta? '),
                      ),
                      TextButton(
                        onPressed: () => context.go('/registro'),
                        child: const Text('Regístrate'),
                      ),
                    ],
                  ),

                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
