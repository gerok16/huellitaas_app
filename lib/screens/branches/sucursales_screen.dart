
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/sucursal.dart';
import '../../services/sucursal_service.dart';

class SucursalesScreen extends StatefulWidget {
  const SucursalesScreen({super.key});

  @override
  State<SucursalesScreen> createState() => _SucursalesScreenState();
}

class _SucursalesScreenState extends State<SucursalesScreen> {
  final SucursalService _service = SucursalService();

  late Future<List<Sucursal>> _sucursalesFuture;

  @override
  void initState() {
    super.initState();
    _sucursalesFuture = _service.obtenerSucursales();
  }

  void _recargar() {
    setState(() {
      _sucursalesFuture = _service.obtenerSucursales();
    });
  }

  void _mostrarDetalle(Sucursal sucursal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sucursal.nombre,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(sucursal.direccion),
              contentPadding: EdgeInsets.zero,
            ),
            if (sucursal.telefono.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(sucursal.telefono),
                contentPadding: EdgeInsets.zero,
              ),
            if (sucursal.horario.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(sucursal.horario),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sucursales Huellitas'),
        actions: [
          IconButton(
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: FutureBuilder<List<Sucursal>>(
        future: _sucursalesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 45),
                    const SizedBox(height: 12),
                    const Text('No se pudieron cargar las sucursales'),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _recargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final sucursales = snapshot.data ?? [];

          if (sucursales.isEmpty) {
            return const Center(
              child: Text('Todavía no hay sucursales registradas.'),
            );
          }

          // Google Maps Flutter no soporta Windows de escritorio.
          if (defaultTargetPlatform == TargetPlatform.windows) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sucursales.length,
              itemBuilder: (context, index) {
                final sucursal = sucursales[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.store,
                      color: Colors.pink,
                      size: 30,
                    ),
                    title: Text(sucursal.nombre),
                    subtitle: Text(sucursal.direccion),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _mostrarDetalle(sucursal),
                  ),
                );
              },
            );
          }

          final marcadores = sucursales.map((sucursal) {
            return Marker(
              markerId: MarkerId(sucursal.id.toString()),
              position: LatLng(sucursal.latitud, sucursal.longitud),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRose,
              ),
              infoWindow: InfoWindow(
                title: sucursal.nombre,
                snippet: sucursal.direccion,
                onTap: () => _mostrarDetalle(sucursal),
              ),
              onTap: () => _mostrarDetalle(sucursal),
            );
          }).toSet();

          return GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-16.5000, -68.1500),
              zoom: 12,
            ),
            markers: marcadores,
            mapType: MapType.normal,
            myLocationButtonEnabled: false,
          );
        },
      ),
    );
  }
}
