import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/proveedor.dart';

class ProveedorService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Proveedor>> listar({bool soloActivos = false}) async {
    try {
      var filtro = _db.from('proveedores').select();
      if (soloActivos) filtro = filtro.eq('activo', true);

      final datos = await filtro.order('nombre');
      return datos.map((fila) => Proveedor.fromMap(fila)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> crear(Proveedor proveedor) async {
    try {
      await _db.from('proveedores').insert(proveedor.toMap());
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> actualizar(int id, Proveedor proveedor) async {
    try {
      await _db.from('proveedores').update(proveedor.toMap()).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> cambiarActivo(int id, bool activo) async {
    try {
      await _db.from('proveedores').update({'activo': activo}).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}