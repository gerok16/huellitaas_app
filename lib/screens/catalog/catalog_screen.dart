
import 'package:flutter/material.dart';

import '../../models/producto.dart';
import '../../services/producto_service.dart';

class CatalogScreen extends StatefulWidget {
  final bool embedded;

  const CatalogScreen({super.key, this.embedded = false});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ProductoService _service = ProductoService();
  late Future<List<Producto>> _productos;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    _productos = _service.productosActivos();
  }

  Widget _imagenProducto(String url, {double height = 125}) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: url.trim().isEmpty
          ? _imagenReemplazo()
          : Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        errorBuilder: (_, __, ___) => _imagenReemplazo(),
      ),
    );
  }

  Widget _imagenReemplazo() {
    return Container(
      color: const Color(0xFFFCE4EC),
      child: const Center(
        child: Icon(
          Icons.pets,
          size: 55,
          color: Color(0xFFEC407A),
        ),
      ),
    );
  }

  void _verDetalle(Producto p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(p.nombre),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _imagenProducto(p.imagenUrl, height: 180),
              const SizedBox(height: 15),
              Text(
                p.precioTexto,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEC407A),
                ),
              ),
              const SizedBox(height: 8),
              Text('Categoría: ${p.categoria}'),
              const SizedBox(height: 8),
              Text(
                p.descripcion.isEmpty
                    ? 'Sin descripción disponible.'
                    : p.descripcion,
              ),
              const SizedBox(height: 12),
              Text(
                p.disponible ? 'Disponible' : 'Agotado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: p.disponible ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
        title: const Text('Catálogo Huellitas'),
        actions: [
          IconButton(
            onPressed: () {
              setState(_recargar);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuestros productos 🐾',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text('Todo lo que tu mascota necesita.'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Producto>>(
              future: _productos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 50),
                        const SizedBox(height: 10),
                        const Text('No se pudieron cargar los productos.'),
                        TextButton(
                          onPressed: () {
                            setState(_recargar);
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
                    child: Text('Todavía no hay productos disponibles.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(_recargar);
                    await _productos;
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final p = productos[index];

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _verDetalle(p),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: _imagenProducto(p.imagenUrl),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
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
                                    const SizedBox(height: 5),
                                    Text(
                                      p.precioTexto,
                                      style: const TextStyle(
                                        color: Color(0xFFEC407A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(
                                          p.disponible
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 15,
                                          color: p.disponible
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            p.disponible
                                                ? 'Disponible'
                                                : 'Agotado',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: p.disponible
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
