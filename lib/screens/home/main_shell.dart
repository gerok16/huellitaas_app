import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../catalog/catalog_screen.dart';
import '../products/gestion_productos_screen.dart';
import '../sales/consulta_venta_screen.dart';
import '../sales/punto_venta_screen.dart';
import '../supply/abastecimiento_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario!;
    final esDueno = auth.esDueno;

    final pantallas = [
      const CatalogScreen(embedded: true),
      const PuntoVentaScreen(embedded: true),
      const ConsultaVentaScreen(embedded: true),
      if (esDueno) const GestionProductosScreen(embedded: true),
      if (esDueno) const AbastecimientoScreen(embedded: true),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(esDueno ? 'Panel del Dueño' : 'Huellitas'),
        actions: [
          IconButton(
            tooltip: 'Sucursales',
            onPressed: () => context.push('/sucursales'),
            icon: const Icon(Icons.location_on_outlined),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await context.read<AuthProvider>().cerrarSesion();

              if (context.mounted) {
                context.go('/');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFEC407A),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, ${usuario.nombre}!',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(esDueno ? 'Dueño' : 'Empleado'),
                    ],
                  ),
                ),
                const Icon(
                  Icons.pets,
                  color: Color(0xFFEC407A),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _indice,
              children: pantallas,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (index) {
          setState(() => _indice = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Catálogo',
          ),
          const NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Ventas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Consultas',
          ),
          if (esDueno)
            const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Productos',
            ),
          if (esDueno)
            const NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: 'Abastecer',
            ),
        ],
      ),
    );
  }
}