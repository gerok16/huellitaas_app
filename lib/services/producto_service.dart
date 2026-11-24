
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../models/producto.dart';

class ProductoService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Producto>> productosActivos() async {
    final datos = await _db
        .from('productos')
        .select()
        .eq('activo', true)
        .order('nombre');

    return datos.map((p) => Producto.fromMap(p)).toList();
  }

  Future<List<Producto>> todos() async {
    final datos = await _db
        .from('productos')
        .select()
        .order('nombre');

    return datos.map((p) => Producto.fromMap(p)).toList();
  }

  Future<Producto?> obtener(int id) async {
    final datos = await _db
        .from('productos')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (datos == null) return null;

    return Producto.fromMap(datos);
  }

  // Subir fotografía al bucket Productos.
  Future<String> subirImagen(XFile imagen) async {
    final bytes = await imagen.readAsBytes();

    final extension = imagen.name.contains('.')
        ? imagen.name.split('.').last.toLowerCase()
        : 'jpg';

    final nombreArchivo =
        '${DateTime.now().microsecondsSinceEpoch}.$extension';

    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };

    await _db.storage.from('Productos').uploadBinary(
      nombreArchivo,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: false,
      ),
    );

    return _db.storage
        .from('Productos')
        .getPublicUrl(nombreArchivo);
  }

  Future<void> crear(Producto producto) async {
    await _db.from('productos').insert(producto.toMap());
  }

  Future<void> actualizar(int id, Producto producto) async {
    await _db
        .from('productos')
        .update(producto.toMap())
        .eq('id', id);
  }

  Future<void> cambiarActivo(int id, bool activo) async {
    await _db
        .from('productos')
        .update({'activo': activo})
        .eq('id', id);
  }
}
