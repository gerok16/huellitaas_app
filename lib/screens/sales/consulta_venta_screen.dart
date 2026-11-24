
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/venta.dart';
import '../../models/estado_venta.dart';
import '../../services/venta_service.dart';

enum _Periodo { hoy, semana, mes, todo, rango }

class ConsultaVentaScreen extends StatefulWidget {
  final bool embedded;

  const ConsultaVentaScreen({super.key, this.embedded = false});

  @override
  State<ConsultaVentaScreen> createState() => _ConsultaVentaScreenState();
}

class _ConsultaVentaScreenState extends State<ConsultaVentaScreen> {
  final VentaService _service = VentaService();
  final TextEditingController _busquedaController = TextEditingController();

  _Periodo _periodo = _Periodo.todo;
  EstadoVenta? _estadoSeleccionado;
  DateTimeRange? _rango;
  late Future<List<Venta>> _ventasFuture;

  @override
  void initState() {
    super.initState();
    _ventasFuture = _cargar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  DateTimeRange? _rangoActivo() {
    final ahora = DateTime.now();

    switch (_periodo) {
      case _Periodo.hoy:
        return DateTimeRange(
          start: DateTime(ahora.year, ahora.month, ahora.day),
          end: ahora,
        );

      case _Periodo.semana:
        return DateTimeRange(
          start: ahora.subtract(const Duration(days: 7)),
          end: ahora,
        );

      case _Periodo.mes:
        return DateTimeRange(
          start: ahora.subtract(const Duration(days: 30)),
          end: ahora,
        );

      case _Periodo.rango:
        return _rango;

      case _Periodo.todo:
        return null;
    }
  }

  Future<List<Venta>> _cargar() {
    final rango = _rangoActivo();
    final codigo = _busquedaController.text.trim();

    return _service.listar(
      codigo: codigo.isEmpty ? null : codigo,
      desde: codigo.isEmpty ? rango?.start : null,
      hasta: codigo.isEmpty ? rango?.end : null,
      estado: _estadoSeleccionado,
    );
  }

  void _recargar() {
    setState(() {
      _ventasFuture = _cargar();
    });
  }

  void _buscar() => _recargar();

  Future<void> _elegirPeriodo(_Periodo periodo) async {
    if (periodo == _Periodo.rango) {
      final ahora = DateTime.now();

      final seleccionado = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(ahora.year + 1),
        initialDateRange: _rango,
      );

      if (seleccionado == null) return;

      setState(() {
        _periodo = periodo;
        _rango = seleccionado;
        _ventasFuture = _cargar();
      });

      return;
    }

    setState(() {
      _periodo = periodo;
      _ventasFuture = _cargar();
    });
  }

  void _abrirDetalle(Venta venta) {
    context.push(
      '/ventas/${Uri.encodeComponent(venta.codigo)}',
      extra: venta,
    );
  }

  String _nombrePeriodo(_Periodo periodo) {
    switch (periodo) {
      case _Periodo.hoy:
        return 'Hoy';
      case _Periodo.semana:
        return '7 días';
      case _Periodo.mes:
        return '30 días';
      case _Periodo.todo:
        return 'Todas';
      case _Periodo.rango:
        return 'Rango';
    }
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

  String _textoPago(String valor) {
    switch (valor.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'qr':
        return 'QR';
      case 'transferencia':
        return 'Transferencia';
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

  String _fecha(DateTime? fecha) {
    if (fecha == null) {
      return 'Sin fecha';
    }

    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
        title: const Text('Consulta de ventas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _construirFiltros(),
          Expanded(
            child: FutureBuilder<List<Venta>>(
              future: _ventasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _estadoVacio(
                    Icons.cloud_off_outlined,
                    'No se pudieron cargar las ventas.',
                    boton: TextButton(
                      onPressed: _recargar,
                      child: const Text('Reintentar'),
                    ),
                  );
                }

                final ventas = snapshot.data ?? [];

                if (ventas.isEmpty) {
                  return _estadoVacio(
                    Icons.receipt_long_outlined,
                    'No se encontraron ventas.',
                    subtitulo: 'Prueba cambiando los filtros de búsqueda.',
                  );
                }

                final total = ventas.fold<double>(
                  0,
                      (suma, venta) => suma + venta.total,
                );

                return RefreshIndicator(
                  onRefresh: () async => _recargar(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.analytics_outlined,
                                color: AppColors.primary,
                                size: 30,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text('${ventas.length} venta(s)'),
                                    const Text(
                                      'Total de ventas consultadas',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Bs. ${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final venta in ventas) _tarjetaVenta(venta),
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

  Widget _construirFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _busquedaController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _buscar(),
            decoration: InputDecoration(
              hintText: 'Buscar por código de venta...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () {
                  _busquedaController.clear();
                  _buscar();
                },
                icon: const Icon(Icons.close),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _Periodo.values.map((periodo) {
                return Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text(_nombrePeriodo(periodo)),
                    selected: _periodo == periodo,
                    onSelected: (_) => _elegirPeriodo(periodo),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<EstadoVenta?>(
            initialValue: _estadoSeleccionado,
            decoration: InputDecoration(
              labelText: 'Filtrar por estado',
              prefixIcon: const Icon(Icons.filter_list_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: [
              const DropdownMenuItem<EstadoVenta?>(
                value: null,
                child: Text('Todos los estados'),
              ),
              ...EstadoVenta.values.map(
                    (estado) => DropdownMenuItem<EstadoVenta?>(
                  value: estado,
                  child: Text(estado.nombre),
                ),
              ),
            ],
            onChanged: (estado) {
              setState(() {
                _estadoSeleccionado = estado;
                _ventasFuture = _cargar();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _tarjetaVenta(Venta venta) {
    final color = _colorEstado(venta.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrirDetalle(venta),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      venta.codigo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      venta.estado.nombre,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                '${_fecha(venta.fecha)} · ${venta.clienteNombre}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 7,
                children: [
                  _dato(
                    Icons.shopping_bag_outlined,
                    '${venta.unidades} unidad(es)',
                  ),
                  _dato(
                    Icons.payment_rounded,
                    _textoPago(venta.metodoPago),
                  ),
                  _dato(
                    Icons.local_shipping_outlined,
                    _textoEntrega(venta.tipoEntrega),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    venta.totalTexto,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dato(IconData icono, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: Colors.grey),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _estadoVacio(
      IconData icono,
      String titulo, {
        String? subtitulo,
        Widget? boton,
      }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 60, color: AppColors.pinkSoft),
            const SizedBox(height: 14),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 7),
              Text(subtitulo, textAlign: TextAlign.center),
            ],
            if (boton != null) ...[
              const SizedBox(height: 16),
              boton,
            ],
          ],
        ),
      ),
    );
  }
}
