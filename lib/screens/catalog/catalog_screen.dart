import 'package:flutter/material.dart';

/// Pantalla temporal. Se reemplaza por el catálogo real en HU-03.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: const Center(child: Text('Aquí irá el catálogo (HU-03)')),
    );
  }
}