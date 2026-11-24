import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/auth_errores.dart';
import '../../providers/auth_provider.dart';
import '../../services/cliente_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  final _confirmarPassword = TextEditingController();

  final ClienteService _clienteService = ClienteService();

  bool _ocultarPassword = true;
  bool _ocultarConfirmacion = true;
  bool _cargando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _password.dispose();
    _confirmarPassword.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final correo = _correo.text.trim();

      final requiereVerificacion = await _clienteService.registrarCliente(
        nombre: _nombre.text,
        correo: correo,
        password: _password.text,
      );

      if (!mounted) return;

      if (requiereVerificacion) {
        // "Confirm email" activado: se envió un código al correo.
        _mensaje('Te enviamos un código de verificación a $correo.');
        context.go('/verificar', extra: correo);
      } else {
        // "Confirm email" desactivado: la sesión ya está abierta.
        final encontrado = await authProvider.cargarPerfil();

        if (!mounted) return;

        if (encontrado) {
          final usuario = authProvider.usuario;
          context.go(usuario?.esCliente == true ? '/cliente' : '/inicio');
        } else {
          _mensaje('Cuenta creada. Ya puedes iniciar sesión.');
          context.go('/login');
        }
      }
    } catch (e) {
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
        title: const Text('Crear cuenta'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
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
                  const SizedBox(height: 12),
                  Text(
                    '¡Únete a Huellitas!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea tu cuenta para comprar tus productos favoritos.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  TextFormField(
                    controller: _nombre,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Ingresa tu nombre completo.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                      helperText:
                      'Usa un correo real: te enviaremos un código.',
                    ),
                    validator: (value) {
                      final correo = value?.trim() ?? '';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                          .hasMatch(correo)) {
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
                      if (value == null || value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmarPassword,
                    obscureText: _ocultarConfirmacion,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _ocultarConfirmacion = !_ocultarConfirmacion;
                          });
                        },
                        icon: Icon(
                          _ocultarConfirmacion
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value != _password.text) {
                        return 'Las contraseñas no coinciden.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 25),

                  FilledButton(
                    onPressed: _cargando ? null : _registrar,
                    child: _cargando
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text('Crear cuenta'),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Ya tengo una cuenta. Iniciar sesión'),
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
