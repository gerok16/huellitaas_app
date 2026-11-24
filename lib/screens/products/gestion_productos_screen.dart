
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/producto.dart';
import '../../services/producto_service.dart';

class GestionProductosScreen extends StatefulWidget {
  final bool embedded;

  const GestionProductosScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<GestionProductosScreen> createState() =>
      _GestionProductosScreenState();
}

class _GestionProductosScreenState
    extends State<GestionProductosScreen> {
  final ProductoService _service = ProductoService();

  late Future<List<Producto>> _productos;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    _productos = _service.todos();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _formulario([Producto? producto]) async {
    final resultado = await showDialog<Producto>(
      context: context,
      builder: (_) => _ProductoDialog(
        producto: producto,
        service: _service,
      ),
    );

    if (resultado == null) return;

    try {
      if (producto == null) {
        await _service.crear(resultado);
        _mensaje('Producto creado correctamente');
      } else {
        await _service.actualizar(producto.id, resultado);
        _mensaje('Producto actualizado correctamente');
      }

      if (mounted) {
        setState(_recargar);
      }
    } catch (e) {
      _mensaje('No se pudo guardar el producto: $e');
    }
  }

  Future<void> _cambiarEstado(
      Producto producto,
      bool activo,
      ) async {
    try {
      await _service.cambiarActivo(producto.id, activo);

      if (mounted) {
        setState(_recargar);
        _mensaje(
          activo ? 'Producto activado' : 'Producto desactivado',
        );
      }
    } catch (e) {
      _mensaje('No se pudo cambiar el estado: $e');
    }
  }

  Widget _imagenProducto(Producto producto) {
    if (producto.imagenUrl.isEmpty) {
      return const CircleAvatar(
        backgroundColor: Color(0xFFFCE4EC),
        child: Icon(
          Icons.pets,
          color: Color(0xFFEC407A),
        ),
      );
    }

    return CircleAvatar(
      backgroundColor: const Color(0xFFFCE4EC),
      backgroundImage: NetworkImage(producto.imagenUrl),
      onBackgroundImageError: (_, __) {},
      child: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Gestión de productos')),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),

      body: FutureBuilder<List<Producto>>(
        future: _productos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No se pudieron cargar los productos.',
                  ),
                  TextButton(
                    onPressed: () => setState(_recargar),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final productos = snapshot.data ?? [];

          if (productos.isEmpty) {
            return const Center(
              child: Text(
                'Todavía no tienes productos registrados.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_recargar);
              await _productos;
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final p = productos[index];

                return Card(
                  child: Opacity(
                    opacity: p.activo ? 1 : 0.55,
                    child: ListTile(
                      onTap: () => _formulario(p),
                      leading: _imagenProducto(p),
                      title: Text(
                        p.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${p.categoria} · ${p.precioTexto}\n'
                            'Stock: ${p.stock} · Mínimo: ${p.stockMinimo}'
                            '${p.activo ? '' : '\nDesactivado'}',
                      ),
                      isThreeLine: true,
                      trailing: Switch(
                        value: p.activo,
                        onChanged: (valor) =>
                            _cambiarEstado(p, valor),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProductoDialog extends StatefulWidget {
  final Producto? producto;
  final ProductoService service;

  const _ProductoDialog({
    this.producto,
    required this.service,
  });

  @override
  State<_ProductoDialog> createState() => _ProductoDialogState();
}

class _ProductoDialogState extends State<_ProductoDialog> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nombre;
  late final TextEditingController _precio;
  late final TextEditingController _stock;
  late final TextEditingController _stockMinimo;
  late final TextEditingController _descripcion;

  static const categorias = [
    'Alimentos',
    'Accesorios',
    'Higiene',
    'Juguetes',
  ];

  String? _categoria;
  XFile? _imagenSeleccionada;
  Uint8List? _imagenBytes;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    final p = widget.producto;

    _nombre = TextEditingController(text: p?.nombre ?? '');
    _precio = TextEditingController(
      text: p == null ? '' : p.precio.toString(),
    );
    _stock = TextEditingController(
      text: p?.stock.toString() ?? '0',
    );
    _stockMinimo = TextEditingController(
      text: p?.stockMinimo.toString() ?? '0',
    );
    _descripcion = TextEditingController(
      text: p?.descripcion ?? '',
    );

    _categoria = p?.categoria;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _stock.dispose();
    _stockMinimo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  String? _validarEntero(String? valor) {
    final numero = int.tryParse(valor ?? '');

    if (numero == null || numero < 0) {
      return 'Ingresa un número entero igual o mayor a 0';
    }

    return null;
  }

  Future<void> _seleccionarImagen() async {
    try {
      final imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (imagen == null) return;

      final bytes = await imagen.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imagenSeleccionada = imagen;
        _imagenBytes = bytes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo seleccionar la imagen: $e'),
          ),
        );
      }
    }
  }

  Widget _vistaPrevia() {
    if (_imagenBytes != null) {
      return Image.memory(
        _imagenBytes!,
        height: 160,
        width: double.infinity,
        fit: BoxFit.contain,
      );
    }

    final url = widget.producto?.imagenUrl ?? '';

    if (url.isNotEmpty) {
      return Image.network(
        url,
        height: 160,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image_outlined,
          size: 55,
        ),
      );
    }

    return const Column(
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 55,
          color: Colors.grey,
        ),
        SizedBox(height: 8),
        Text('Todavía no hay una imagen seleccionada'),
      ],
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría'),
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      String imagenUrl = widget.producto?.imagenUrl ?? '';

      if (_imagenSeleccionada != null) {
        imagenUrl = await widget.service.subirImagen(
          _imagenSeleccionada!,
        );
      }

      final producto = Producto(
        id: widget.producto?.id ?? 0,
        nombre: _nombre.text.trim(),
        categoria: _categoria!,
        precio: double.parse(
          _precio.text.trim().replaceAll(',', '.'),
        ),
        stock: int.parse(_stock.text),
        stockMinimo: int.parse(_stockMinimo.text),
        descripcion: _descripcion.text.trim(),
        imagenUrl: imagenUrl,
        activo: widget.producto?.activo ?? true,
        costo: widget.producto?.costo ?? 0,
      );

      if (!mounted) return;

      Navigator.pop(context, producto);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir la imagen: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.producto == null
            ? 'Nuevo producto'
            : 'Editar producto',
      ),

      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Campo obligatorio'
                      : null,
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _categoria,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                  ),
                  items: categorias.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    );
                  }).toList(),
                  onChanged: _guardando
                      ? null
                      : (v) => setState(() => _categoria = v),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _precio,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Precio (Bs.)',
                  ),
                  validator: (v) {
                    final n = double.tryParse(
                      (v ?? '').trim().replaceAll(',', '.'),
                    );

                    if (n == null || n <= 0) {
                      return 'El precio debe ser mayor que cero';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock',
                  ),
                  validator: _validarEntero,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _stockMinimo,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock mínimo',
                  ),
                  validator: _validarEntero,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _descripcion,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                  ),
                ),

                const SizedBox(height: 18),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Fotografía del producto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 150,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: _vistaPrevia(),
                  ),
                ),

                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: _guardando
                      ? null
                      : _seleccionarImagen,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    _imagenSeleccionada == null
                        ? 'Seleccionar fotografía'
                        : 'Cambiar fotografía',
                  ),
                ),

                if (_imagenSeleccionada != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Text(
                      'Fotografía nueva seleccionada',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: _guardando
              ? null
              : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),

        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
