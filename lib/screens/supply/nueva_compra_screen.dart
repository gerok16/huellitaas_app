
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/compra.dart';
import '../../models/producto.dart';
import '../../models/proveedor.dart';
import '../../services/compra_service.dart';
import '../../services/producto_service.dart';
import '../../services/proveedor_service.dart';

class NuevaCompraScreen extends StatefulWidget {
  final Proveedor? proveedorInicial;
  final List<Producto> productosIniciales;

  const NuevaCompraScreen({
    super.key,
    this.proveedorInicial,
    this.productosIniciales = const [],
  });

  @override
  State<NuevaCompraScreen> createState() => _NuevaCompraScreenState();
}

class _NuevaCompraScreenState extends State<NuevaCompraScreen> {
  final _compras = CompraService();
  final _proveedoresService = ProveedorService();
  final _productosService = ProductoService();
  final _notas = TextEditingController();

  late Future<List<Proveedor>> _proveedores;
  late Future<List<Producto>> _productos;

  Proveedor? _proveedor;
  final List<ItemCompra> _items = [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _proveedor = widget.proveedorInicial;
    _proveedores = _proveedoresService.listar(soloActivos: true);
    _productos = _productosService.todos();

    for (final p in widget.productosIniciales) {
      _items.add(
        ItemCompra(
          producto: p,
          cantidad: _cantidadSugerida(p),
          costoUnitario: p.costo,
        ),
      );
    }
  }

  @override
  void dispose() {
    _notas.dispose();
    super.dispose();
  }

  int _cantidadSugerida(Producto p) {
    final cantidad = p.stockMinimo * 2 - p.stock;
    return cantidad < 1 ? 1 : cantidad;
  }

  double get _total =>
      _items.fold(0, (suma, item) => suma + item.subtotal);

  int get _unidades =>
      _items.fold(0, (suma, item) => suma + item.cantidad);

  void _mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  String _limpio(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  Future<void> _elegirProveedor() async {
    try {
      final lista = await _proveedores;

      if (!mounted) return;

      final elegido = await showModalBottomSheet<Proveedor>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) {
          if (lista.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No hay proveedores activos.\n'
                    'Crea uno en la pestaña Proveedores.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return SafeArea(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: lista.length,
              itemBuilder: (context, index) {
                final p = lista[index];

                return ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: Text(p.nombre),
                  subtitle: Text(
                    [p.contacto, p.telefono]
                        .where((t) => t.trim().isNotEmpty)
                        .join(' · '),
                  ),
                  selected: _proveedor?.id == p.id,
                  onTap: () => Navigator.pop(sheetContext, p),
                );
              },
            ),
          );
        },
      );

      if (elegido != null && mounted) {
        setState(() => _proveedor = elegido);
      }
    } catch (e) {
      _mensaje(_limpio(e));
    }
  }

  Future<void> _agregarProducto() async {
    try {
      final todos = await _productos;

      if (!mounted) return;

      final agregados = _items.map((i) => i.producto.id).toSet();
      final disponibles =
      todos.where((p) => !agregados.contains(p.id)).toList();

      final elegido = await showModalBottomSheet<Producto>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _SelectorProducto(productos: disponibles),
      );

      if (elegido == null || !mounted) return;

      setState(() {
        _items.add(
          ItemCompra(
            producto: elegido,
            cantidad: _cantidadSugerida(elegido),
            costoUnitario: elegido.costo,
          ),
        );
      });
    } catch (e) {
      _mensaje(_limpio(e));
    }
  }

  Future<void> _confirmar() async {
    final proveedor = _proveedor;

    if (proveedor == null) {
      _mensaje('Elige un proveedor.');
      return;
    }

    if (_items.isEmpty) {
      _mensaje('Agrega al menos un producto.');
      return;
    }

    for (final item in _items) {
      if (item.cantidad <= 0) {
        _mensaje('Revisa la cantidad de "${item.producto.nombre}".');
        return;
      }

      if (item.costoUnitario <= 0) {
        _mensaje('Ingresa el costo de "${item.producto.nombre}".');
        return;
      }
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar compra'),
        content: Text(
          'Proveedor: ${proveedor.nombre}\n'
              '${_items.length} producto(s) · $_unidades unidad(es)\n'
              'Total: Bs. ${_total.toStringAsFixed(2)}\n\n'
              'El stock se actualizará de inmediato.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _guardando = true);

    try {
      final resultado = await _compras.registrarCompra(
        proveedorId: proveedor.id,
        items: _items,
        notas: _notas.text,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 55,
          ),
          title: const Text('Compra registrada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('El stock fue actualizado.'),
              const SizedBox(height: 14),
              SelectableText(
                'Código: ${resultado['codigo'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Total: Bs. ${resultado['total'] ?? ''}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );

      if (mounted) context.pop(true);
    } catch (e) {
      _mensaje('No se pudo registrar: ${_limpio(e)}');
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Widget _tarjetaProveedor() {
    final p = _proveedor;

    return Card(
      child: ListTile(
        onTap: _guardando ? null : _elegirProveedor,
        leading: const CircleAvatar(
          backgroundColor: AppColors.pinkLight,
          child: Icon(
            Icons.local_shipping_outlined,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          p?.nombre ?? 'Elegir proveedor',
          style: TextStyle(
            color: p == null ? AppColors.textSoft : AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: p == null
            ? const Text('Obligatorio')
            : Text(
          [p.contacto, p.telefono]
              .where((t) => t.trim().isNotEmpty)
              .join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _barraInferior() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x33F8BBD0),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_unidades unidad(es)',
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Bs. ${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 155,
              child: FilledButton(
                onPressed: _guardando ? null : _confirmar,
                child: _guardando
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Registrar compra',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva compra'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _tarjetaProveedor(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Productos',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _guardando ? null : _agregarProducto,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Todavía no agregaste productos.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final item in _items)
                    _FilaItem(
                      key: ValueKey(item.producto.id),
                      item: item,
                      onCambio: () => setState(() {}),
                      onEliminar: () {
                        setState(() => _items.remove(item));
                      },
                    ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notas,
                  maxLines: 2,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                  ),
                ),
              ],
            ),
          ),
          _barraInferior(),
        ],
      ),
    );
  }
}

class _FilaItem extends StatefulWidget {
  final ItemCompra item;
  final VoidCallback onCambio;
  final VoidCallback onEliminar;

  const _FilaItem({
    super.key,
    required this.item,
    required this.onCambio,
    required this.onEliminar,
  });

  @override
  State<_FilaItem> createState() => _FilaItemState();
}

class _FilaItemState extends State<_FilaItem> {
  late final TextEditingController _cantidad;
  late final TextEditingController _costo;

  @override
  void initState() {
    super.initState();

    _cantidad = TextEditingController(
      text: '${widget.item.cantidad}',
    );

    _costo = TextEditingController(
      text: widget.item.costoUnitario > 0
          ? widget.item.costoUnitario.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _cantidad.dispose();
    _costo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.item.producto;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Stock actual: ${p.stock} · mínimo: ${p.stockMinimo}',
                        style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar',
                  onPressed: widget.onEliminar,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _cantidad,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                    ),
                    onChanged: (value) {
                      widget.item.cantidad = int.tryParse(value) ?? 0;
                      widget.onCambio();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _costo,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9.,]'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Costo unit. (Bs.)',
                      helperText: p.costo > 0
                          ? 'Último: Bs. ${p.costo.toStringAsFixed(2)}'
                          : null,
                    ),
                    onChanged: (value) {
                      widget.item.costoUnitario =
                          double.tryParse(value.replaceAll(',', '.')) ?? 0;
                      widget.onCambio();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Subtotal: Bs. ${widget.item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorProducto extends StatefulWidget {
  final List<Producto> productos;

  const _SelectorProducto({
    required this.productos,
  });

  @override
  State<_SelectorProducto> createState() => _SelectorProductoState();
}

class _SelectorProductoState extends State<_SelectorProducto> {
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final texto = _filtro.trim().toLowerCase();

    final lista = texto.isEmpty
        ? widget.productos
        : widget.productos.where((p) {
      return p.nombre.toLowerCase().contains(texto) ||
          p.categoria.toLowerCase().contains(texto);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (value) {
                  setState(() => _filtro = value);
                },
                decoration: const InputDecoration(
                  hintText: 'Buscar producto',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: lista.isEmpty
                  ? const Center(
                child: Text('No hay productos para agregar.'),
              )
                  : ListView.builder(
                itemCount: lista.length,
                itemBuilder: (context, index) {
                  final p = lista[index];

                  return ListTile(
                    title: Text(p.nombre),
                    subtitle: Text(
                      '${p.categoria} · stock ${p.stock} / '
                          'mín. ${p.stockMinimo}'
                          '${p.activo ? '' : ' · inactivo'}',
                    ),
                    trailing: p.stockBajo
                        ? const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                    )
                        : null,
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
