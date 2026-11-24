import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../models/compra.dart';
import '../../services/compra_service.dart';

/// Detalle de una compra a proveedor.
/// Si ya tienes la [compra] se muestra al instante; si solo llega el
/// [codigo], la pantalla la busca en Supabase.
class DetalleCompraScreen extends StatefulWidget {
  final String codigo;
  final Compra? compra;

  const DetalleCompraScreen({super.key, required this.codigo, this.compra});

  @override
  State<DetalleCompraScreen> createState() => _DetalleCompraScreenState();
}

class _DetalleCompraScreenState extends State<DetalleCompraScreen> {
  final CompraService _service = CompraService();
  late Future<Compra?> _compra;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _compra = widget.compra != null
        ? Future.value(widget.compra)
        : _service.buscarPorCodigo(widget.codigo);
  }

  Future<void> _copiar(String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Código copiado.')));
  }

  Widget _fila(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 19, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: Text(
              etiqueta,
              style: const TextStyle(color: AppColors.textSoft),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cabecera(Compra c) {
    final color = c.esAnulada ? AppColors.error : AppColors.success;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    c.codigo,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar código',
                  onPressed: () => _copiar(c.codigo),
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                c.esAnulada ? 'Anulada' : 'Recibida',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 24),
            _fila(Icons.event, 'Fecha', c.fechaTexto),
            if (c.horaTexto.isNotEmpty)
              _fila(Icons.schedule, 'Hora', c.horaTexto),
            _fila(Icons.local_shipping_outlined, 'Proveedor', c.proveedorNombre),
            if (c.notas.isNotEmpty) _fila(Icons.notes_outlined, 'Notas', c.notas),
          ],
        ),
      ),
    );
  }

  Widget _productos(Compra c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Productos (${c.unidades} unidad(es))',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (c.detalles.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Esta compra no tiene productos registrados.'),
              )
            else
              for (final d in c.detalles)
                ListTile(
                  dense: true,
                  title: Text(
                    d.nombreProducto,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${d.cantidad} × ${d.costoTexto}'),
                  trailing: Text(
                    d.subtotalTexto,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _total(Compra c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.pinkLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'TOTAL',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            c.totalTexto,
            style: TextStyle(
              color: c.esAnulada ? AppColors.textSoft : AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              decoration: c.esAnulada ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mensaje(IconData icono, String titulo, {Widget? boton}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            if (boton != null) ...[const SizedBox(height: 14), boton],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de compra')),
      body: FutureBuilder<Compra?>(
        future: _compra,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _mensaje(
              Icons.cloud_off_outlined,
              'No se pudo cargar la compra.',
              boton: TextButton(
                onPressed: () => setState(_cargar),
                child: const Text('Reintentar'),
              ),
            );
          }

          final compra = snapshot.data;

          if (compra == null) {
            return _mensaje(
              Icons.search_off,
              'No existe una compra con el código ${widget.codigo}.',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _cabecera(compra),
                    const SizedBox(height: 4),
                    _productos(compra),
                    const SizedBox(height: 12),
                    _total(compra),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}