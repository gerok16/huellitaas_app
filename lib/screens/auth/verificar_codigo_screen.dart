import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/auth_errores.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

/// Pantalla donde el cliente escribe el código de 6 dígitos que le llegó
/// por correo para verificar su cuenta.
class VerificarCodigoScreen extends StatefulWidget {
  final String correo;

  const VerificarCodigoScreen({super.key, required this.correo});

  @override
  State<VerificarCodigoScreen> createState() => _VerificarCodigoScreenState();
}

class _VerificarCodigoScreenState extends State<VerificarCodigoScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _codigo = TextEditingController();

  Timer? _timer;
  int _espera = 0;
  bool _verificando = false;
  bool _reenviando = false;

  @override
  void initState() {
    super.initState();
    // El código recién se envió: se espera antes de permitir reenviarlo.
    _iniciarEspera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codigo.dispose();
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

  Future<void> _verificar() async {
    final codigo = _codigo.text.trim();

    if (codigo.length != 6) {
      _mensaje('Ingresa los 6 dígitos del código.');
      return;
    }

    setState(() => _verificando = true);

    try {
      await _auth.verificarCodigoRegistro(
        correo: widget.correo,
        codigo: codigo,
      );

      final encontrado = await authProvider.cargarPerfil();

      if (!mounted) return;

      if (encontrado) {
        _mensaje('¡Correo verificado! Bienvenido a Huellitas.');
        final usuario = authProvider.usuario;
        context.go(usuario?.esCliente == true ? '/cliente' : '/inicio');
      } else {
        await authProvider.cerrarSesion();
        _mensaje('Correo verificado. Ya puedes iniciar sesión.');
        if (mounted) context.go('/login');
      }
    } catch (e) {
      _codigo.clear();
      _mensaje(traducirErrorAuth(e));
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  Future<void> _reenviar() async {
    setState(() => _reenviando = true);

    try {
      await _auth.reenviarCodigoRegistro(widget.correo);
      _iniciarEspera();
      _mensaje('Te enviamos un código nuevo.');
    } catch (e) {
      _mensaje(traducirErrorAuth(e));
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeReenviar = _espera <= 0 && !_reenviando;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar correo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/registro'),
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
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  'Revisa tu correo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Enviamos un código de 6 dígitos a\n${widget.correo}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                TextField(
                  controller: _codigo,
                  enabled: !_verificando,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 12,
                  ),
                  decoration: const InputDecoration(hintText: '······'),
                  onChanged: (valor) {
                    // Al completar los 6 dígitos se verifica solo.
                    if (valor.length == 6 && !_verificando) _verificar();
                  },
                ),
                const SizedBox(height: 22),

                FilledButton(
                  onPressed: _verificando ? null : _verificar,
                  child: _verificando
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Verificar'),
                ),
                const SizedBox(height: 10),

                TextButton(
                  onPressed: puedeReenviar ? _reenviar : null,
                  child: Text(
                    _espera > 0
                        ? 'Reenviar código en $_espera s'
                        : 'Reenviar código',
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/registro'),
                  child: const Text('Usar otro correo'),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¿No lo ves? Revisa la carpeta de spam o correo no deseado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSoft, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
