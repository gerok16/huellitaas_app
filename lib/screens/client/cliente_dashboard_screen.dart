
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/producto.dart';
import '../../providers/auth_provider.dart';
import '../../providers/carrito_provider.dart';
import '../../services/producto_service.dart';
import '../../services/venta_service.dart';

class ClienteDashboardScreen extends StatefulWidget {
  const ClienteDashboardScreen({super.key});

  @override
  State<ClienteDashboardScreen> createState() =>
      _ClienteDashboardScreenState();
}

class _ClienteDashboardScreenState extends State<ClienteDashboardScreen> {
  final _productoService = ProductoService();
  final _ventaService = VentaService();

  late Future<List<Producto>> _productosFuture;
  late Future<List<Map<String, dynamic>>> _comprasFuture;

  int _indice = 0;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _productosFuture = _productoService.productosActivos();

    final usuario = context.read<AuthProvider>().usuario;
    _comprasFuture = usuario == null
        ? Future.value([])
        : _ventaService.misCompras(usuario.id);
  }

  Future<void> _recargarProductos() async {
    final futuro = _productoService.productosActivos();

    if (!mounted) return;
    setState(() {
      _productosFuture = futuro;
    });

    await futuro;
  }

  Future<void> _recargarCompras() async {
    final usuario = context.read<AuthProvider>().usuario;
    if (usuario == null) return;

    final futuro = _ventaService.misCompras(usuario.id);

    if (!mounted) return;
    setState(() {
      _comprasFuture = futuro;
    });

    await futuro;
  }

  void _mensaje(String texto, [Color? color]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          backgroundColor: color ?? AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await context.read<AuthProvider>().cerrarSesion();
      if (mounted) context.go('/login');
    } catch (_) {
      _mensaje('No se pudo cerrar la sesión.', AppColors.error);
    }
  }

  void _agregarAlCarrito(Producto p) {
    final ok = context.read<CarritoProvider>().agregarProducto(p);

    _mensaje(
      ok ? '${p.nombre} agregado al carrito.' : 'No hay stock disponible.',
      ok ? AppColors.primary : AppColors.error,
    );
  }

  Future<Map<String, String>?> _datosCompra(double total) {
    String pago = 'efectivo';
    String entrega = 'recojo';

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizar) => AlertDialog(
          title: const Text('Confirmar compra'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total: Bs. ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: pago,
                  decoration: const InputDecoration(
                    labelText: 'Método de pago',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'efectivo',
                      child: Text('Efectivo'),
                    ),
                    DropdownMenuItem(value: 'qr', child: Text('QR')),
                    DropdownMenuItem(
                      value: 'transferencia',
                      child: Text('Transferencia'),
                    ),
                    DropdownMenuItem(
                      value: 'tarjeta',
                      child: Text('Tarjeta'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) actualizar(() => pago = v);
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: entrega,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de entrega',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_shipping),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'recojo',
                      child: Text('Recojo en sucursal'),
                    ),
                    DropdownMenuItem(
                      value: 'domicilio',
                      child: Text('Entrega a domicilio'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) actualizar(() => entrega = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () => Navigator.pop(ctx, {
                'metodo_pago': pago,
                'tipo_entrega': entrega,
              }),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarCompra() async {
    if (_procesando) return;

    final carrito = context.read<CarritoProvider>();
    final usuario = context.read<AuthProvider>().usuario;

    if (usuario == null) {
      _mensaje('Inicia sesión nuevamente.', AppColors.error);
      return;
    }

    if (carrito.items.isEmpty) {
      _mensaje('Tu carrito está vacío.', AppColors.error);
      return;
    }

    final totalAnterior = carrito.total;
    final datos = await _datosCompra(totalAnterior);

    if (datos == null || !mounted) return;

    final items = carrito.items.map((item) => <String, int>{
      'producto_id': item.producto.id,
      'cantidad': item.cantidad,
    }).toList();

    setState(() {
      _procesando = true;
    });

    bool cargando = false;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
      cargando = true;

      final resultado = await _ventaService.registrarVenta(
        items,
        clienteId: usuario.id,
        metodoPago: datos['metodo_pago']!,
        tipoEntrega: datos['tipo_entrega']!,
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();
      cargando = false;

      carrito.vaciarCarrito();

      await _recargarProductos();
      await _recargarCompras();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: 48,
          ),
          title: const Text('¡Compra realizada! 🐾'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tu compra fue registrada correctamente.'),
              const SizedBox(height: 12),
              _dato(
                'Código',
                resultado['codigo']?.toString() ?? 'Sin código',
                Icons.receipt,
              ),
              _dato(
                'Total',
                _total(resultado['total'] ?? totalAnterior),
                Icons.payments,
              ),
              _dato(
                'Pago',
                _pago(datos['metodo_pago']),
                Icons.payment,
              ),
              _dato(
                'Entrega',
                _entrega(datos['tipo_entrega']),
                Icons.local_shipping,
              ),
            ],
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      if (cargando) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      _mensaje(
        e.toString().replaceFirst('Exception: ', ''),
        AppColors.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  Widget _dato(String titulo, String valor, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icono, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: Colors.grey)),
                Text(
                  valor,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pago(String? v) => {
    'qr': 'QR',
    'transferencia': 'Transferencia',
    'tarjeta': 'Tarjeta',
  }[v] ??
      'Efectivo';

  String _entrega(String? v) =>
      v == 'domicilio' ? 'Entrega a domicilio' : 'Recojo en sucursal';

  String _estado(String? v) => {
    'pendiente': 'Pendiente',
    'pagado': 'Pagado',
    'preparando': 'Preparando',
    'listo': 'Listo para entregar',
    'entregado': 'Entregado',
    'cancelado': 'Cancelado',
  }[v] ??
      v ??
      'Sin estado';

  Color _colorEstado(String? v) => {
    'pendiente': Colors.orange,
    'pagado': Colors.teal,
    'preparando': Colors.deepPurple,
    'listo': AppColors.primary,
    'entregado': AppColors.success,
    'cancelado': AppColors.error,
  }[v] ??
      Colors.grey;

  String _fecha(dynamic v) {
    if (v == null) return 'Fecha no disponible';

    try {
      final f = DateTime.parse(v.toString()).toLocal();
      return '${f.day.toString().padLeft(2, '0')}/'
          '${f.month.toString().padLeft(2, '0')}/${f.year} - '
          '${f.hour.toString().padLeft(2, '0')}:'
          '${f.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return v.toString();
    }
  }

  String _total(dynamic v) {
    final n = double.tryParse(v?.toString() ?? '');
    return n == null ? 'Bs. ${v ?? '0.00'}' : 'Bs. ${n.toStringAsFixed(2)}';
  }

  Widget _vacio(IconData icono, String titulo, String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 55, color: AppColors.primary),
            const SizedBox(height: 15),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, CarritoProvider>(
      builder: (context, auth, carrito, _) => Scaffold(
        backgroundColor: AppColors.pinkLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            ['Huellitas', 'Mi carrito', 'Mis compras'][_indice],
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (_indice == 0)
              IconButton(
                onPressed: _recargarProductos,
                icon: const Icon(Icons.refresh),
              ),
            if (_indice == 2)
              IconButton(
                onPressed: _recargarCompras,
                icon: const Icon(Icons.refresh),
              ),
            IconButton(
              onPressed: _cerrarSesion,
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout, color: AppColors.error),
            ),
          ],
        ),
        body: IndexedStack(
          index: _indice,
          children: [
            _inicio(auth.usuario?.nombre ?? 'Cliente'),
            _carrito(carrito),
            _misCompras(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indice,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.pinkSoft,
          onDestinationSelected: (i) {
            setState(() {
              _indice = i;
            });
            if (i == 2) _recargarCompras();
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.storefront_outlined),
              selectedIcon: Icon(
                Icons.storefront,
                color: AppColors.primary,
              ),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: carrito.cantidadTotal > 0,
                label: Text('${carrito.cantidadTotal}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: carrito.cantidadTotal > 0,
                label: Text('${carrito.cantidadTotal}'),
                child: Icon(
                  Icons.shopping_cart,
                  color: AppColors.primary,
                ),
              ),
              label: 'Carrito',
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(
                Icons.receipt_long,
                color: AppColors.primary,
              ),
              label: 'Mis compras',
            ),
          ],
        ),
      ),
    );
  }

  // INICIO Y CATEGORÍAS

  Widget _inicio(String nombre) {
    return RefreshIndicator(
      onRefresh: _recargarProductos,
      child: FutureBuilder<List<Producto>>(
        future: _productosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              children: [
                SizedBox(
                  height: 400,
                  child: _vacio(
                    Icons.error,
                    'Error al cargar',
                    'Intenta actualizar nuevamente.',
                  ),
                ),
              ],
            );
          }

          final productos =
          (snapshot.data ?? []).where((p) => p.activo).toList();

          final categorias = <String, List<Producto>>{};

          for (final p in productos) {
            final categoria = p.categoria.trim();
            if (categoria.isNotEmpty) {
              categorias.putIfAbsent(categoria, () => []).add(p);
            }
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _banner(nombre),
              const SizedBox(height: 24),
              if (productos.isEmpty)
                _vacio(
                  Icons.inventory_2,
                  'Sin productos',
                  'Todavía no hay productos disponibles.',
                )
              else ...[
                const Text(
                  'Explora nuestras categorías 🐾',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 15),
                ...categorias.entries.take(4).map(
                      (e) => _carruselCategoria(e.key, e.value),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _banner(String nombre) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8BBD0), Color(0xFFE1BEE7)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¡Hola! 🐾'),
                Text(
                  nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Todo lo que tu mascota necesita.'),
              ],
            ),
          ),
          const Icon(
            Icons.pets,
            size: 45,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _carruselCategoria(String categoria, List<Producto> productos) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pets, color: AppColors.primary, size: 21),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  categoria,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '${productos.length} productos',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: productos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final p = productos[i];
                final disponible = p.activo && p.stock > 0;

                return Container(
                  width: 165,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withValues(alpha: 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 115,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _imagenProducto(p),
                            if (!disponible)
                              Container(
                                color: Colors.black45,
                                child: const Center(
                                  child: Text(
                                    'AGOTADO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.precioTexto,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: 34,
                                child: FilledButton.tonalIcon(
                                  onPressed: disponible
                                      ? () => _agregarAlCarrito(p)
                                      : null,
                                  icon: const Icon(
                                    Icons.add_shopping_cart,
                                    size: 15,
                                  ),
                                  label: const Text(
                                    'Agregar',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  style: FilledButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    backgroundColor: AppColors.pinkSoft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagenAlternativa(String categoria) {
    final c = categoria.toLowerCase();

    final icono = c.contains('alimento')
        ? Icons.restaurant
        : c.contains('higiene')
        ? Icons.cleaning_services
        : c.contains('juguete')
        ? Icons.toys
        : Icons.pets;

    return Container(
      color: AppColors.pinkSoft,
      child: Center(
        child: Icon(icono, size: 45, color: AppColors.primary),
      ),
    );
  }

  Widget _imagenProducto(Producto p) {
    final url = p.imagenUrl.trim();

    if (url.isEmpty) return _imagenAlternativa(p.categoria);

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => _imagenAlternativa(p.categoria),
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  // CARRITO

  Widget _carrito(CarritoProvider carrito) {
    if (carrito.items.isEmpty) {
      return _vacio(
        Icons.shopping_cart,
        'Carrito vacío',
        'Agrega productos para realizar una compra.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: carrito.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final item = carrito.items[i];
              final p = item.producto;

              return Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 65,
                          height: 65,
                          child: _imagenProducto(p),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              p.precioTexto,
                              style: const TextStyle(
                                color: AppColors.primary,
                              ),
                            ),
                            Row(
                              children: [
                                _botonCantidad(
                                  Icons.remove,
                                      () => carrito.disminuirCantidad(p.id),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text('${item.cantidad}'),
                                ),
                                _botonCantidad(
                                  Icons.add,
                                  item.cantidad < p.stock
                                      ? () => carrito.aumentarCantidad(p.id)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: () =>
                                carrito.eliminarProducto(p.id),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                          ),
                          Text(
                            'Bs. ${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Bs. ${carrito.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 21,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _procesando ? null : _confirmarCompra,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      _procesando ? 'Procesando...' : 'Realizar compra',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _botonCantidad(IconData icono, VoidCallback? accion) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: accion,
        padding: EdgeInsets.zero,
        icon: Icon(icono, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.pinkSoft,
          foregroundColor: AppColors.primary,
        ),
      ),
    );
  }

  // HISTORIAL DE COMPRAS

  Widget _misCompras() {
    return RefreshIndicator(
      onRefresh: _recargarCompras,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _comprasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || (snapshot.data ?? []).isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 450,
                  child: _vacio(
                    Icons.receipt_long,
                    snapshot.hasError
                        ? 'Error al cargar'
                        : 'Aún no tienes compras',
                    snapshot.hasError
                        ? 'Intenta actualizar nuevamente.'
                        : 'Tus compras aparecerán aquí.',
                  ),
                ),
              ],
            );
          }

          final compras = snapshot.data!;

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: compras.length,
            itemBuilder: (_, i) => _tarjetaCompra(compras[i]),
          );
        },
      ),
    );
  }

  Widget _tarjetaCompra(Map<String, dynamic> compra) {
    final estado = compra['estado']?.toString();

    final detalles = (compra['detalle_ventas'] as List?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ??
        [];

    final fecha = _fecha(compra['fecha']);
    final total = _total(compra['total']);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(
          Icons.receipt_long,
          color: AppColors.primary,
          size: 30,
        ),
        title: Text(
          compra['codigo']?.toString() ?? 'Sin código',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(fecha),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              total,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            _estadoChip(estado),
          ],
        ),
        childrenPadding: const EdgeInsets.all(14),
        children: [
          _filaCompra(Icons.calendar_today, 'Fecha', fecha),
          if (compra['metodo_pago'] != null)
            _filaCompra(
              Icons.payment,
              'Pago',
              _pago(compra['metodo_pago'].toString()),
            ),
          if (compra['tipo_entrega'] != null)
            _filaCompra(
              Icons.local_shipping,
              'Entrega',
              _entrega(compra['tipo_entrega'].toString()),
            ),
          _filaCompra(Icons.attach_money, 'Total', total),
          if (detalles.isNotEmpty) ...[
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Productos comprados',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...detalles.map(_detalleProducto),
          ],
        ],
      ),
    );
  }

  Widget _estadoChip(String? estado) {
    final color = _colorEstado(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _estado(estado),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _filaCompra(IconData icono, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detalleProducto(Map<String, dynamic> detalle) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.pinkLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.pets, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detalle['nombre_producto']?.toString() ?? 'Producto',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Cantidad: ${detalle['cantidad'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _total(detalle['subtotal']),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
