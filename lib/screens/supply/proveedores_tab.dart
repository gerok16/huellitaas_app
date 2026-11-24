import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/proveedor.dart';
import '../../services/proveedor_service.dart';

/// Lista de proveedores: crear, editar, activar/desactivar y comprar.
class ProveedoresTab extends StatefulWidget {
  final Future<void> Function()? onCompraRegistrada;

  const ProveedoresTab({
    super.key,
    this.onCompraRegistrada,
  });

  @override
  State<ProveedoresTab> createState() => _ProveedoresTabState();
}

class _ProveedoresTabState extends State<ProveedoresTab> {
  final ProveedorService _service = ProveedorService();

  late Future<List<Proveedor>> _proveedores;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _proveedores = _service.listar();
  }

  void _recargar() => setState(_cargar);

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  String _limpio(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _formulario([Proveedor? actual]) async {
    final resultado = await showDialog<Proveedor>(
      context: context,
      builder: (_) => _ProveedorDialog(proveedor: actual),
    );

    if (resultado == null || !mounted) return;

    try {
      if (actual == null) {
        await _service.crear(resultado);
        _mensaje('Proveedor creado.');
      } else {
        await _service.actualizar(actual.id, resultado);
        _mensaje('Proveedor actualizado.');
      }

      _recargar();
    } catch (e) {
      _mensaje(_limpio(e));
    }
  }

  Future<void> _cambiarActivo(Proveedor p, bool activo) async {
    try {
      await _service.cambiarActivo(p.id, activo);
      _mensaje(
        activo ? 'Proveedor activado.' : 'Proveedor desactivado.',
      );
      _recargar();
    } catch (e) {
      _mensaje(_limpio(e));
    }
  }

  Future<void> _comprar(Proveedor p) async {
    await context.push(
      '/compras/nueva',
      extra: <String, Object?>{'proveedor': p},
    );

    if (mounted) {
      await widget.onCompraRegistrada?.call();
    }
  }

  Widget _linea(IconData icono, String texto) {
    if (texto.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icono,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Proveedor p) {
    return Opacity(
      opacity: p.activo ? 1 : 0.55,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.pinkLight,
                    child: Icon(
                      Icons.local_shipping_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombre,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (!p.activo)
                          const Text(
                            'Inactivo',
                            style: TextStyle(
                              color: AppColors.textSoft,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Switch(
                    value: p.activo,
                    onChanged: (valor) => _cambiarActivo(p, valor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _linea(Icons.person_outline, p.contacto),
              _linea(Icons.phone_outlined, p.telefono),
              _linea(Icons.email_outlined, p.correo),
              _linea(
                Icons.badge_outlined,
                p.nit.isEmpty ? '' : 'NIT: ${p.nit}',
              ),
              _linea(Icons.place_outlined, p.direccion),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _formulario(p),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                    ),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: p.activo ? () => _comprar(p) : null,
                    icon: const Icon(
                      Icons.add_shopping_cart,
                      size: 18,
                    ),
                    label: const Text('Comprar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estado(
      IconData icono,
      String titulo, {
        bool reintentar = false,
      }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        Icon(
          icono,
          size: 62,
          color: AppColors.pinkSoft,
        ),
        const SizedBox(height: 14),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (reintentar)
          TextButton(
            onPressed: _recargar,
            child: const Text('Reintentar'),
          ),
      ],
    );
  }

  Widget _lista() {
    return FutureBuilder<List<Proveedor>>(
      future: _proveedores,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _estado(
            Icons.cloud_off_outlined,
            'No se pudieron cargar los proveedores.',
            reintentar: true,
          );
        }

        final todos = snapshot.data ?? [];
        final texto = _filtro.trim().toLowerCase();

        final lista = texto.isEmpty
            ? todos
            : todos
            .where(
              (p) =>
          p.nombre.toLowerCase().contains(texto) ||
              p.contacto.toLowerCase().contains(texto),
        )
            .toList();

        if (todos.isEmpty) {
          return _estado(
            Icons.local_shipping_outlined,
            'Aún no tienes proveedores.\n'
                'Toca "Nuevo proveedor" para agregar el primero.',
          );
        }

        if (lista.isEmpty) {
          return _estado(
            Icons.search_off,
            'Ningún proveedor coincide.',
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
          itemCount: lista.length,
          itemBuilder: (context, index) {
            return _tarjeta(lista[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo proveedor'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: TextField(
              onChanged: (valor) {
                setState(() => _filtro = valor);
              },
              decoration: const InputDecoration(
                hintText: 'Buscar proveedor',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _recargar();
                await _proveedores;
              },
              child: _lista(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formulario para crear o editar un proveedor.
class _ProveedorDialog extends StatefulWidget {
  final Proveedor? proveedor;

  const _ProveedorDialog({
    this.proveedor,
  });

  @override
  State<_ProveedorDialog> createState() => _ProveedorDialogState();
}

class _ProveedorDialogState extends State<_ProveedorDialog> {
  final _form = GlobalKey<FormState>();

  late final TextEditingController _nombre;
  late final TextEditingController _contacto;
  late final TextEditingController _telefono;
  late final TextEditingController _correo;
  late final TextEditingController _nit;
  late final TextEditingController _direccion;

  @override
  void initState() {
    super.initState();

    final p = widget.proveedor;

    _nombre = TextEditingController(
      text: p?.nombre ?? '',
    );
    _contacto = TextEditingController(
      text: p?.contacto ?? '',
    );
    _telefono = TextEditingController(
      text: p?.telefono ?? '',
    );
    _correo = TextEditingController(
      text: p?.correo ?? '',
    );
    _nit = TextEditingController(
      text: p?.nit ?? '',
    );
    _direccion = TextEditingController(
      text: p?.direccion ?? '',
    );
  }

  @override
  void dispose() {
    _nombre.dispose();
    _contacto.dispose();
    _telefono.dispose();
    _correo.dispose();
    _nit.dispose();
    _direccion.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;

    Navigator.pop(
      context,
      Proveedor(
        id: widget.proveedor?.id ?? 0,
        nombre: _nombre.text.trim(),
        contacto: _contacto.text.trim(),
        telefono: _telefono.text.trim(),
        correo: _correo.text.trim(),
        nit: _nit.text.trim(),
        direccion: _direccion.text.trim(),
        activo: widget.proveedor?.activo ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.proveedor != null;

    return AlertDialog(
      title: Text(
        editando ? 'Editar proveedor' : 'Nuevo proveedor',
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre o empresa *',
                  ),
                  validator: (v) =>
                  (v == null || v.trim().length < 2)
                      ? 'Ingresa el nombre del proveedor.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contacto,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Persona de contacto',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _correo,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                  ),
                  validator: (v) {
                    final correo = v?.trim() ?? '';

                    if (correo.isEmpty) return null;

                    return RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(correo)
                        ? null
                        : 'Ingresa un correo válido.';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nit,
                  decoration: const InputDecoration(
                    labelText: 'NIT',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _direccion,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}