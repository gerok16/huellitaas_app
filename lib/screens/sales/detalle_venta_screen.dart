
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../models/venta.dart';
import '../../models/estado_venta.dart';
import '../../models/eventoestado.dart';
import '../../services/venta_service.dart';

class DetalleVentaScreen extends StatefulWidget {
  final String codigo;
  final Venta? venta;

  const DetalleVentaScreen({
    super.key,
    required this.codigo,
    this.venta,
  });

  @override
  State<DetalleVentaScreen> createState() => _DetalleVentaScreenState();
}

class _DetalleVentaScreenState extends State<DetalleVentaScreen> {
  final VentaService _service = VentaService();

  late Future<Venta?> _ventaFuture;
  Future<List<EventoEstado>>? _historialFuture;

  @override
  void initState() {
    super.initState();

    final ventaInicial = widget.venta;

    if (ventaInicial != null) {
      _ventaFuture = Future.value(ventaInicial);
      _cargarHistorial(ventaInicial);
    } else {
      _ventaFuture = _cargarVenta();
    }
  }

  Future<Venta?> _cargarVenta() async {
    final venta = await _service.buscarPorCodigo(widget.codigo);

    if (venta != null) {
      _cargarHistorial(venta);
    }

    return venta;
  }

  void _cargarHistorial(Venta venta) {
    _historialFuture = _service.obtenerHistorial(venta.id);
  }

  void _recargar() {
    setState(() {
      _historialFuture = null;
      _ventaFuture = _cargarVenta();
    });
  }

  Color _colorEstado(EstadoVenta estado) {
    switch (estado) {
      case EstadoVenta.pendiente:
        return Colors.orange;
      case EstadoVenta.pagado:
        return Colors.blue;
      case EstadoVenta.preparando:
        return Colors.deepPurple;
      case EstadoVenta.listo:
        return Colors.teal;
      case EstadoVenta.entregado:
        return AppColors.success;
      case EstadoVenta.cancelado:
        return AppColors.error;
    }
  }

  IconData _iconoEstado(EstadoVenta estado) {
    switch (estado) {
      case EstadoVenta.pendiente:
        return Icons.schedule_rounded;
      case EstadoVenta.pagado:
        return Icons.payment_rounded;
      case EstadoVenta.preparando:
        return Icons.inventory_2_outlined;
      case EstadoVenta.listo:
        return Icons.check_circle_outline_rounded;
      case EstadoVenta.entregado:
        return Icons.local_shipping_rounded;
      case EstadoVenta.cancelado:
        return Icons.cancel_outlined;
    }
  }

  String _textoPago(String valor) {
    switch (valor.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'qr':
        return 'Pago mediante QR';
      case 'transferencia':
        return 'Transferencia bancaria';
      case 'tarjeta':
        return 'Tarjeta';
      default:
        return valor.isEmpty ? 'No especificado' : valor;
    }
  }

  String _textoEntrega(String valor) {
    switch (valor.toLowerCase()) {
      case 'recojo':
        return 'Recojo en tienda';
      case 'domicilio':
        return 'Entrega a domicilio';
      default:
        return valor.isEmpty ? 'No especificado' : valor;
    }
  }

  String _fecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  String _hora(DateTime fecha) {
    return '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _copiarCodigo(String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado al portapapeles.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de venta'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Venta?>(
        future: _ventaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _estadoMensaje(
              Icons.cloud_off_outlined,
              'No se pudo cargar la venta.',
              boton: TextButton(
                onPressed: _recargar,
                child: const Text('Reintentar'),
              ),
            );
          }

          final venta = snapshot.data;

          if (venta == null) {
            return _estadoMensaje(
              Icons.search_off_rounded,
              'No se encontró la venta solicitada.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _construirEncabezado(venta),
                const SizedBox(height: 14),
                _construirEstado(venta),
                const SizedBox(height: 14),
                _construirInformacion(venta),
                const SizedBox(height: 14),
                _construirProductos(venta),
                const SizedBox(height: 14),
                _construirHistorial(venta),
                if (venta.motivoAnulacion.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _construirMotivoAnulacion(venta),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _construirEncabezado(Venta venta) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.pinkLight,
              child: Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Código de venta',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: SelectableText(
                    venta.codigo,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar código',
                  onPressed: () => _copiarCodigo(venta.codigo),
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: AppColors.primary,
                    size: 19,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text('${venta.fechaTexto} · ${venta.horaTexto}'),
          ],
        ),
      ),
    );
  }

  Widget _construirEstado(Venta venta) {
    final color = _colorEstado(venta.estado);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado del pedido',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(
                    _iconoEstado(venta.estado),
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venta.estado.nombre,
                        style: TextStyle(
                          color: color,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        venta.estado.descripcion,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirInformacion(Venta venta) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de la compra',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _filaInformacion(
              Icons.person_outline,
              'Cliente',
              venta.clienteNombre ?? '',
            ),
            _filaInformacion(
              Icons.email_outlined,
              'Correo',
              venta.clienteCorreo ?? '',
            ),
            _filaInformacion(
              Icons.badge_outlined,
              'Vendedor',
              venta.vendedorNombre ?? '',
            ),
            _filaInformacion(
              Icons.payment_outlined,
              'Método de pago',
              _textoPago(venta.metodoPago),
            ),
            _filaInformacion(
              Icons.local_shipping_outlined,
              'Tipo de entrega',
              _textoEntrega(venta.tipoEntrega),
            ),
            if (venta.sucursalId != null)
              _filaInformacion(
                Icons.store_outlined,
                'Sucursal',
                'Sucursal #${venta.sucursalId}',
              ),
            if (venta.direccionEntregaId != null)
              _filaInformacion(
                Icons.location_on_outlined,
                'Dirección de entrega',
                'Dirección #${venta.direccionEntregaId}',
              ),
            if (venta.notas.trim().isNotEmpty)
              _filaInformacion(
                Icons.notes_rounded,
                'Notas',
                venta.notas,
              ),
          ],
        ),
      ),
    );
  }

  Widget _filaInformacion(
      IconData icono,
      String titulo,
      String valor,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icono,
            size: 19,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 115,
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              valor.trim().isEmpty ? 'No especificado' : valor,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirProductos(Venta venta) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productos de la venta',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            for (final detalle in venta.detalles)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 19,
                      backgroundColor: AppColors.pinkLight,
                      child: Icon(
                        Icons.pets_rounded,
                        color: AppColors.primary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detalle.nombreProducto,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${detalle.cantidad} × ${detalle.precioTexto}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      detalle.subtotalTexto,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  venta.totalTexto,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirHistorial(Venta venta) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seguimiento del pedido',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Historial de cambios de estado de la venta.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 15),
            FutureBuilder<List<EventoEstado>>(
              future: _historialFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(15),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Text(
                    'No se pudo cargar el historial de seguimiento.',
                    style: TextStyle(
                      color: AppColors.error,
                    ),
                  );
                }

                final eventos = snapshot.data ?? [];

                if (eventos.isEmpty) {
                  return _eventoActual(venta);
                }

                return Column(
                  children: [
                    for (int i = 0; i < eventos.length; i++)
                      _elementoHistorial(
                        eventos[i],
                        i == eventos.length - 1,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventoActual(Venta venta) {
    final color = _colorEstado(venta.estado);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _iconoEstado(venta.estado),
          color: color,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                venta.estado.nombre,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Estado actual de la venta.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _elementoHistorial(
      EventoEstado evento,
      bool ultimo,
      ) {
    final dynamic datos = evento;
    final dynamic estadoValor = datos.estado;
    final dynamic fechaValor = datos.fecha;
    final dynamic notaValor = datos.nota;

    final String estadoTexto = estadoValor is EstadoVenta
        ? estadoValor.nombre
        : estadoValor?.toString() ?? 'Cambio de estado';

    final DateTime? fecha = fechaValor is DateTime
        ? fechaValor
        : DateTime.tryParse(fechaValor?.toString() ?? '');

    final String nota = notaValor?.toString() ?? '';

    final EstadoVenta? estadoEnum = EstadoVenta.values
        .where(
          (e) => e.nombre == estadoTexto || e.valor == estadoTexto,
    )
        .firstOrNull;

    final color = estadoEnum == null
        ? AppColors.primary
        : _colorEstado(estadoEnum);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(
                  Icons.circle,
                  size: 13,
                  color: color,
                ),
                if (!ultimo)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.pinkSoft,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estadoTexto,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (fecha != null)
                    Text(
                      '${_fecha(fecha)} · ${_hora(fecha)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  if (nota.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      nota,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirMotivoAnulacion(Venta venta) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Motivo de anulación',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(venta.motivoAnulacion),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoMensaje(
      IconData icono,
      String mensaje, {
        Widget? boton,
      }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              size: 60,
              color: AppColors.pinkSoft,
            ),
            const SizedBox(height: 14),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (boton != null) ...[
              const SizedBox(height: 15),
              boton,
            ],
          ],
        ),
      ),
    );
  }
}
