import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/auth_errores.dart';
import '../../services/auth_service.dart';

/// Recuperar contraseña en dos pasos:
/// 1) el cliente escribe su correo y recibe un código de 6 dígitos;
/// 2) escribe el código y su nueva contraseña.
class RecuperarPasswordScreen extends StatefulWidget {
  final String? correoInicial;

  const RecuperarPasswordScreen({super.key, this.correoInicial});

  @override
  State<RecuperarPasswordScreen> createState() =>
      _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final AuthService _auth = AuthService();

  final _formCorreo = GlobalKey<FormState>();
  final _formReset = GlobalKey<FormState>();

  late final TextEditingController _correo;
  final _codigo = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();

  Timer? _timer;
  int _paso = 0; // 0 = pedir código, 1 = código + nueva contraseña
  int _espera = 0;
  bool _cargando = false;
  bool _ocultar = true;

  @override
  void initState() {
    super.initState();
    _correo = TextEditingController(text: widget.correoInicial ?? '');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _correo.dispose();
    _codigo.dispose();
    _password.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  void _iniciarEspera([int segundos = 60]) {
    _timer?.cancel();
    _espera = segundos;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _espera--);
      if (_espera <= 0) t.cancel();
    });
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _enviarCodigo() async {
    // En el paso 2 (reenvío) el formulario del correo ya no está en pantalla.
    if (_paso == 0 && !_formCorreo.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      await _auth.solicitarRecuperacion(_correo.text);
      if (!mounted) return;

      _iniciarEspera();
      setState(() => _paso = 1);

      // Mensaje neutro: no revela si el correo existe o no.
      _mensaje('Si el correo está registrado, te enviamos un código.');
    } catch (e) {
      _mensaje(traducirErrorAuth(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _restablecer() async {
    if (!_formReset.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      await _auth.restablecerPassword(
        correo: _correo.text,
        codigo: _codigo.text,
        nuevaPassword: _password.text,
      );

      if (!mounted) return;

      _mensaje('Contraseña actualizada. Ya puedes iniciar sesión.');
      context.go('/login');
    } catch (e) {
      _mensaje(traducirErrorAuth(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ---------------------------------------------------------------------
  // PASOS
  // ---------------------------------------------------------------------

  Widget _pasoCorreo() {
    return Form(
      key: _formCorreo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Escribe el correo de tu cuenta y te enviaremos un código '
                'de 6 dígitos para crear una contraseña nueva.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              final correo = value?.trim() ?? '';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(correo)) {
                return 'Ingresa un correo válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _cargando ? null : _enviarCodigo,
            child: _cargando
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Enviar código'),
          ),
        ],
      ),
    );
  }

  Widget _pasoCodigo() {
    return Form(
      key: _formReset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enviamos un código de 6 dígitos a\n${_correo.text.trim()}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _codigo,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 10,
            ),
            decoration: const InputDecoration(hintText: '······'),
            validator: (value) {
              if ((value ?? '').length != 6) {
                return 'Ingresa los 6 dígitos del código.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            obscureText: _ocultar,
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _ocultar = !_ocultar),
                icon: Icon(
                  _ocultar ? Icons.visibility : Icons.visibility_off,
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
            controller: _confirmar,
            obscureText: _ocultar,
            decoration: const InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: Icon(Icons.lock_reset),
            ),
            validator: (value) {
              if (value != _password.text) {
                return 'Las contraseñas no coinciden.';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _cargando ? null : _restablecer,
            child: _cargando
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Cambiar contraseña'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: (_espera <= 0 && !_cargando) ? _enviarCodigo : null,
            child: Text(
              _espera > 0
                  ? 'Reenviar código en $_espera s'
                  : 'Reenviar código',
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _paso = 0),
            child: const Text('Usar otro correo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  _paso == 0 ? '¿Olvidaste tu contraseña?' : 'Crea una nueva',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                if (_paso == 0) _pasoCorreo() else _pasoCodigo(),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Volver a iniciar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
