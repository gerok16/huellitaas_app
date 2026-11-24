
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/compra.dart';
import '../../models/producto.dart';
import '../../services/compra_service.dart';
import '../../services/producto_service.dart';
import 'proveedores_tab.dart';
import 'compras_tab.dart';
import 'reposicion_tab.dart';

/// Datos que comparten el resumen y la pestaña de Reposición.
class _DatosAbastecimiento {
final List<Producto> productos;
final List<Compra> comprasMes;

const _DatosAbastecimiento(this.productos, this.comprasMes);

int get cantidadPorReponer =>
productos.where((p) => p.activo && p.stockBajo).length;

List<Compra> get _validas => comprasMes.where((c) => !c.esAnulada).toList();

int get cantidadComprasMes => _validas.length;

double get invertidoMes =>
_validas.fold<double>(0, (suma, c) => suma + c.total);
}

/// Panel del dueño: reposición de stock, proveedores y compras.
class AbastecimientoScreen extends StatefulWidget {
final bool embedded;

const AbastecimientoScreen({super.key, this.embedded = false});

@override
State<AbastecimientoScreen> createState() => _AbastecimientoScreenState();
}

class _AbastecimientoScreenState extends State<AbastecimientoScreen> {
final ProductoService _productos = ProductoService();
final CompraService _compras = CompraService();

late Future<_DatosAbastecimiento> _datos;

int _version = 0;

@override
void initState() {
super.initState();
_datos = _cargar();
}

Future<_DatosAbastecimiento> _cargar() async {
final ahora = DateTime.now();
final inicioMes = DateTime(ahora.year, ahora.month, 1);

final r = await Future.wait<Object>([
_productos.todos(),
_compras.listar(desde: inicioMes),
]);

return _DatosAbastecimiento(
r[0] as List<Producto>,
r[1] as List<Compra>,
);
}

Future<void> _recargar() async {
final futuro = _cargar();

setState(() {
_datos = futuro;
_version++;
});

try {
await futuro;
} catch (_) {
// El error se muestra en pantalla.
}
}

Widget _dato({
required IconData icono,
required Color color,
required String valor,
required String etiqueta,
}) {
return Card(
margin: EdgeInsets.zero,
child: Padding(
padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
child: Column(
children: [
Icon(icono, color: color, size: 22),
const SizedBox(height: 4),
FittedBox(
child: Text(
valor,
style: const TextStyle(
color: AppColors.textDark,
fontSize: 17,
fontWeight: FontWeight.bold,
),
),
),
Text(
etiqueta,
textAlign: TextAlign.center,
style: const TextStyle(
color: AppColors.textSoft,
fontSize: 11,
),
),
],
),
),
);
}

Widget _resumen() {
return FutureBuilder<_DatosAbastecimiento>(
future: _datos,
builder: (context, snapshot) {
final d = snapshot.data;

return Padding(
padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
child: Row(
children: [
Expanded(
child: _dato(
icono: Icons.warning_amber_rounded,
color: AppColors.warning,
valor: d == null ? '—' : '${d.cantidadPorReponer}',
etiqueta: 'Por reponer',
),
),
const SizedBox(width: 8),
Expanded(
child: _dato(
icono: Icons.shopping_bag_outlined,
color: AppColors.primary,
valor: d == null ? '—' : '${d.cantidadComprasMes}',
etiqueta: 'Compras del mes',
),
),
const SizedBox(width: 8),
Expanded(
child: _dato(
icono: Icons.payments_outlined,
color: AppColors.success,
valor: d == null
? '—'
    : 'Bs. ${d.invertidoMes.toStringAsFixed(0)}',
etiqueta: 'Invertido este mes',
),
),
],
),
);
},
);
}

Widget _tabReposicion() {
return FutureBuilder<_DatosAbastecimiento>(
future: _datos,
builder: (context, snapshot) {
final datos = snapshot.data;

if (datos == null) {
if (snapshot.hasError) {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Text('No se pudo cargar el inventario.'),
const SizedBox(height: 6),
Text(
snapshot.error
    .toString()
    .replaceFirst('Exception: ', ''),
textAlign: TextAlign.center,
style: const TextStyle(
color: AppColors.textSoft,
fontSize: 12,
),
),
TextButton(
onPressed: _recargar,
child: const Text('Reintentar'),
),
],
),
),
);
}

return const Center(
child: CircularProgressIndicator(),
);
}

return ReposicionTab(
productos: datos.productos,
onRecargar: _recargar,
);
},
);
}

@override
Widget build(BuildContext context) {
return DefaultTabController(
length: 3,
child: Scaffold(
appBar: widget.embedded
? null
    : AppBar(
title: const Text('Abastecimiento'),
),
body: Column(
children: [
_resumen(),
const TabBar(
labelColor: AppColors.primary,
indicatorColor: AppColors.primary,
tabs: [
Tab(text: 'Reposición'),
Tab(text: 'Proveedores'),
Tab(text: 'Compras'),
],
),
Expanded(
child: TabBarView(
children: [
_tabReposicion(),
ProveedoresTab(
onCompraRegistrada: _recargar,
),
ComprasTab(
key: ValueKey(_version),
),
],
),
),
],
),
),
);
}
}
