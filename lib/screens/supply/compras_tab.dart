import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/compra.dart';
import '../../services/compra_service.dart';

/// Historial de compras a proveedores.
class ComprasTab extends StatefulWidget {
  const ComprasTab({super.key});

  @override
  State<ComprasTab> createState() => _ComprasTabState();
}

class _ComprasTabState extends State<ComprasTab> {
  final CompraService _service = CompraService();

  /// 7, 30 o 0 (todas).
  int _dias = 30;
  String _filtro = '';
  late Future<List<Compra>> _compras;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    DateTime? desde;

    if (_dias > 0) {
      final ahora = DateTime.now();
      desde = DateTime(ahora.year, ahora.month, ahora.day - (_dias - 1));
    }

    _compras = _service.listar(desde: desde);
  }

  void _recargar() => setState(_cargar);

  Future<void> _abrirDetalle(Compra compra) async {
    await context.push(
      '/compras/${Uri.encodeComponent(compra.codigo)}',
      extra: compra,
    );

    if (mounted) _recargar();
  }

  Widget _chip(String texto, int dias) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: _dias == dias,
        onSelected: (_) {
          setState(() {
            _dias = dias;
            _cargar();
          });
        },
      ),
    );
  }

  Widget _resumen(List<Compra> compras) {
    final validas = compras.where((c) => !c.esAnulada);
    final total = validas.fold<double>(0, (suma, c) => suma + c.total);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.pinkLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${compras.length} compra(s)',
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'Bs. ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Compra c) {
    final anulada = c.esAnulada;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirDetalle(c),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.pinkLight,
                child: Icon(Icons.inventory_2_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.codigo,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c.fechaHoraTexto}\n'
                          '${c.proveedorNombre} · ${c.unidades} unidad(es)',
                    ),
                    if (anulada)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Anulada',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                c.totalTexto,
                style: TextStyle(
                  color: anulada ? AppColors.textSoft : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  decoration: anulada ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estado(IconData icono, String titulo, {bool reintentar = false}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        Icon(icono, size: 62, color: AppColors.pinkSoft),
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
          TextButton(onPressed: _recargar, child: const Text('Reintentar')),
      ],
    );
  }

  Widget _lista() {
    return FutureBuilder<List<Compra>>(
      future: _compras,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _estado(
            Icons.cloud_off_outlined,
            'No se pudieron cargar las compras.',
            reintentar: true,
          );
        }

        final todas = snapshot.data ?? [];

        if (todas.isEmpty) {
          return _estado(
            Icons.shopping_bag_outlined,
            'No hay compras en este período.',
          );
        }

        final texto = _filtro.trim().toLowerCase();
        final compras = texto.isEmpty
            ? todas
            : todas
            .where((c) =>
        c.codigo.toLowerCase().contains(texto) ||
            c.proveedorNombre.toLowerCase().contains(texto))
            .toList();

        if (compras.isEmpty) {
          return _estado(Icons.search_off, 'Ninguna compra coincide.');
        }

        return Column(
          children: [
            _resumen(compras),
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                itemCount: compras.length,
                itemBuilder: (context, index) => _tarjeta(compras[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: TextField(
            onChanged: (v) => setState(() => _filtro = v),
            decoration: const InputDecoration(
              hintText: 'Buscar por código o proveedor',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: Row(
            children: [
              _chip('7 días', 7),
              _chip('30 días', 30),
              _chip('Todas', 0),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _recargar();
              await _compras;
            },
            child: _lista(),
          ),
        ),
      ],
    );
  }
}