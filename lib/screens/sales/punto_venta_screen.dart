
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/producto.dart';
import '../../providers/auth_provider.dart';
import '../../providers/carrito_provider.dart';
import '../../services/cliente_service.dart';
import '../../services/producto_service.dart';
import '../../services/venta_service.dart';

class PuntoVentaScreen extends StatefulWidget {
  final bool embedded;
  final bool modoCliente;

  const PuntoVentaScreen({
    super.key,
    this.embedded = false,
    this.modoCliente = false,
  });

  @override
  State<PuntoVentaScreen> createState() => _PuntoVentaScreenState();
}

class _PuntoVentaScreenState extends State<PuntoVentaScreen> {
  final ProductoService _productosService = ProductoService();
  final VentaService _ventaService = VentaService();
  final ClienteService _clienteService = ClienteService();

  late Future<List<Producto>> _productos;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _recargarProductos();
  }

  void _recargarProductos() {
    _productos = _productosService.productosActivos();
  }

  void _mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<String?> _seleccionarCliente() async {
    try {
      final clientes = await _clienteService.obtenerClientes();

      if (!mounted) return null;

      if (clientes.isEmpty) {
        _mensaje('Todavía no hay clientes registrados.');
        return null;
      }

      return await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Seleccionar cliente'),
            content: SizedBox(
              width: 400,
              height: 350,
              child: ListView.builder(
                itemCount: clientes.length,
                itemBuilder: (context, index) {
                  final cliente = clientes[index];

                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(cliente['nombre'] ?? 'Sin nombre'),
                    subtitle: Text(cliente['correo'] ?? ''),
                    onTap: () {
                      Navigator.pop(
                        dialogContext,
                        cliente['id'].toString(),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _mensaje('No se pudieron cargar los clientes: $e');
      return null;
    }
  }

  Future<Map<String, String>?> _confirmarDatosOperacion(
      double total,
      ) async {
    String metodoPago = 'efectivo';
    String tipoEntrega = 'recojo';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, actualizarDialogo) {
            return AlertDialog(
              title: Text(
                widget.modoCliente
                    ? 'Confirmar compra'
                    : 'Confirmar venta',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Total a pagar: Bs. ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Método de pago',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: metodoPago,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'efectivo',
                        child: Text('Efectivo'),
                      ),
                      DropdownMenuItem(
                        value: 'qr',
                        child: Text('QR'),
                      ),
                      DropdownMenuItem(
                        value: 'transferencia',
                        child: Text('Transferencia'),
                      ),
                      DropdownMenuItem(
                        value: 'tarjeta',
                        child: Text('Tarjeta'),
                      ),
                    ],
                    onChanged: (valor) {
                      if (valor != null) {
                        actualizarDialogo(() {
                          metodoPago = valor;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tipo de entrega',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: tipoEntrega,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'recojo',
                        child: Text('Recojo en tienda'),
                      ),
                      DropdownMenuItem(
                        value: 'domicilio',
                        child: Text('Entrega a domicilio'),
                      ),
                    ],
                    onChanged: (valor) {
                      if (valor != null) {
                        actualizarDialogo(() {
                          tipoEntrega = valor;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      {
                        'metodo_pago': metodoPago,
                        'tipo_entrega': tipoEntrega,
                      },
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmarVenta() async {
    final carrito = context.read<CarritoProvider>();
    final usuario = context.read<AuthProvider>().usuario;

    if (carrito.items.isEmpty) {
      _mensaje('Agrega productos antes de continuar.');
      return;
    }

    if (usuario == null) {
      _mensaje('No se encontró la sesión del usuario.');
      return;
    }

    String clienteId;

    if (usuario.esCliente) {
      clienteId = usuario.id;
    } else {
      final seleccionado = await _seleccionarCliente();

      if (seleccionado == null || !mounted) return;

      clienteId = seleccionado;
    }

    final datosOperacion = await _confirmarDatosOperacion(
      carrito.total,
    );

    if (datosOperacion == null || !mounted) return;

    setState(() => _procesando = true);

    try {
      final items = carrito.items.map((item) {
        return <String, int>{
          'producto_id': item.producto.id,
          'cantidad': item.cantidad,
        };
      }).toList();

      final resultado = await _ventaService.registrarVenta(
        items,
        clienteId: clienteId,
        metodoPago: datosOperacion['metodo_pago']!,
        tipoEntrega: datosOperacion['tipo_entrega']!,
      );

      carrito.vaciarCarrito();

      if (!mounted) return;

      setState(_recargarProductos);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 55,
          ),
          title: Text(
            widget.modoCliente
                ? '¡Compra realizada!'
                : '¡Venta registrada!',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('La operación se realizó correctamente.'),
              const SizedBox(height: 15),
              SelectableText(
                'Código: ${resultado['codigo'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: Bs. ${resultado['total'] ?? ''}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pago: ${datosOperacion['metodo_pago']}',
              ),
              Text(
                'Entrega: ${datosOperacion['tipo_entrega']}',
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
    } catch (e) {
      if (mounted) {
        setState(_recargarProductos);
      }

      _mensaje(
        'No se pudo completar la operación: '
            '${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  // ---------------------------------------------------------------------
  // LISTA DE PRODUCTOS
  // ---------------------------------------------------------------------

  Widget _listaProductos() {
    return FutureBuilder<List<Producto>>(
      future: _productos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudieron cargar los productos.'),
                TextButton(
                  onPressed: () {
                    setState(_recargarProductos);
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final productos = snapshot.data ?? [];

        if (productos.isEmpty) {
          return const Center(
            child: Text('No hay productos activos disponibles.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: productos.length,
          itemBuilder: (context, index) {
            final producto = productos[index];

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFCE4EC),
                  child: Icon(
                    Icons.pets,
                    color: Color(0xFFEC407A),
                  ),
                ),
                title: Text(
                  producto.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${producto.precioTexto} · Stock: ${producto.stock}',
                ),
                trailing: IconButton(
                  onPressed: producto.stock > 0
                      ? () {
                    final agregado = context
                        .read<CarritoProvider>()
                        .agregarProducto(producto);

                    _mensaje(
                      agregado
                          ? 'Producto agregado al carrito.'
                          : 'No hay stock suficiente.',
                    );
                  }
                      : null,
                  icon: const Icon(Icons.add_shopping_cart),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // FILA DE PRODUCTO DEL CARRITO
  // ---------------------------------------------------------------------

  Widget _filaCarrito(
      ItemCarrito item,
      CarritoProvider carrito,
      ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${item.producto.nombre}\n'
                '${item.producto.precioTexto} c/u',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {
            carrito.disminuirCantidad(item.producto.id);
          },
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('${item.cantidad}'),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {
            final ok = carrito.aumentarCantidad(item.producto.id);
            if (!ok) _mensaje('Stock máximo alcanzado.');
          },
          icon: const Icon(Icons.add_circle_outline),
        ),
        const SizedBox(width: 4),
        Text(
          'Bs. ${item.subtotal.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {
            carrito.eliminarProducto(item.producto.id);
          },
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // PANEL DEL CARRITO
  // ---------------------------------------------------------------------

  Widget _panelCarrito(
      CarritoProvider carrito,
      double alturaMaxima,
      ) {
    final items = carrito.items;

    return Container(
      constraints: BoxConstraints(maxHeight: alturaMaxima),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x66F8BBD0),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Carrito',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('${carrito.cantidadTotal} unidades'),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Todavía no agregaste productos.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _filaCarrito(items[index], carrito);
                  },
                ),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Bs. ${carrito.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFEC407A),
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _procesando || items.isEmpty
                  ? null
                  : _confirmarVenta,
              icon: _procesando
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(
                widget.modoCliente
                    ? Icons.shopping_bag
                    : Icons.point_of_sale,
              ),
              label: Text(
                _procesando
                    ? 'Procesando...'
                    : widget.modoCliente
                    ? 'Finalizar compra'
                    : 'Registrar venta',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
        title: Text(
          widget.modoCliente ? 'Mis compras' : 'Punto de venta',
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(child: _listaProductos()),
              _panelCarrito(
                carrito,
                constraints.maxHeight * 0.5,
              ),
            ],
          );
        },
      ),
    );
  }
}
