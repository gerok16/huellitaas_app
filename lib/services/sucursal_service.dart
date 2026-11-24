
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sucursal.dart';

class SucursalService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Sucursal>> obtenerSucursales() async {
    final respuesta = await _supabase
        .from('sucursales')
        .select()
        .eq('activo', true)
        .order('nombre');

    return (respuesta as List)
        .map((item) => Sucursal.fromMap(item))
        .toList();
  }
}
