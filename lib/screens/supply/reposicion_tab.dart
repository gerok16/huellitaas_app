
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/producto.dart';

// Productos que hay que reponer, del más urgente al menos urgente.
class ReposicionTab extends StatefulWidget {
  final List<Producto> productos;
  final Future<void> Function() onRecargar;

  const ReposicionTab({
    super.key,
    required this.productos,
    required this.onRecargar,
  });

  @override
  State<ReposicionTab> createState() => _ReposicionTabState();
}

class _ReposicionTabState extends State<ReposicionTab> {
  bool _soloBajos = true;

  // Menor número = más urgente. Los agotados van primero.
  double _urgencia(Producto p) {
    if (p.stock == 0) return -1;
    if (p.stockMinimo <= 0) return 999;
    return p.stock / p.stockMinimo;
  }

  int get _cantidadBajos =>
      widget.productos.where((p) => p.activo && p.stockBajo).length;

  List<Producto> _visibles() {
    final activos = widget.productos.where((p) => p.activo);

    final lista = (_soloBajos
        ? activos.where((p) => p.stockBajo)
        : activos)
        .toList();

    lista.sort((a, b) => _urgencia(a).compareTo(_urgencia(b)));

    return lista;
  }

  Future<void> _reponer(List<Producto> productos) async {
    await context.push(
      '/compras/nueva',
      extra: <String, Object?>{
        'productos': productos,
      },
    );

    if (mounted) {
      await widget.onRecargar();
    }
  }

  Widget _vacio() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 60),
        Icon(
          Icons.check_circle_outline,
          size: 62,
          color: AppColors.success,
        ),
        SizedBox(height: 14),
        Text(
          'Todo en orden',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'No hay productos por reponer.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _fila(Producto p) {
    final agotado = p.stock == 0;

    final color = agotado
        ? AppColors.error
        : (p.stockBajo ? AppColors.warning : AppColors.success);

    final etiqueta = agotado
        ? 'Agotado'
        : (p.stockBajo ? 'Stock bajo' : 'Stock normal');

    final progreso = p.stockMinimo <= 0
        ? (p.stock > 0 ? 1.0 : 0.0)
        : (p.stock / (p.stockMinimo * 2))
        .clamp(0.0, 1.0)
        .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 2),
                  Text(
                    p.costo > 0
                        ? '${p.categoria} · último costo Bs. ${p.costo.toStringAsFixed(2)}'
                        : p.categoria,
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progreso,
                    minHeight: 6,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: ${p.stock} · mínimo: ${p.stockMinimo}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Ancho definido para evitar restricciones infinitas.
            SizedBox(
              width: 112,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 112,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      etiqueta,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 112,
                    child: OutlinedButton(
                      onPressed: () => _reponer([p]),
                      child: const Text('Reponer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Row(
            children: [
              ChoiceChip(
                label: Text('Por reponer ($_cantidadBajos)'),
                selected: _soloBajos,
                onSelected: (_) {
                  setState(() => _soloBajos = true);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Todos'),
                selected: !_soloBajos,
                onSelected: (_) {
                  setState(() => _soloBajos = false);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRecargar,
            child: visibles.isEmpty
                ? _vacio()
                : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              itemCount: visibles.length,
              itemBuilder: (context, index) {
                return _fila(visibles[index]);
              },
            ),
          ),
        ),
        if (_soloBajos && visibles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _reponer(visibles),
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(
                  'Reponer los ${visibles.length} productos',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
