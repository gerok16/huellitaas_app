import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/compra.dart';

class CompraService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const int limiteConsulta = 100;
  static const String _columnas = '*,proveedores(nombre),detalle_compras(*)';

  /// Registra la compra y sube el stock (solo el dueño).
  Future<Map<String, dynamic>> registrarCompra({
    required int proveedorId,
    required List<ItemCompra> items,
    String notas = '',
  }) async {
    if (items.isEmpty) {
      throw Exception('Agrega al menos un producto.');
    }

    try {
      final respuesta = await _supabase.rpc(
        'registrar_compra',
        params: {
          'p_proveedor_id': proveedorId,
          'p_items': items.map((i) => i.toJson()).toList(),
          'p_notas': notas.trim(),
        },
      );

      if (respuesta is! Map) {
        throw Exception('Respuesta inválida del servidor.');
      }

      return Map<String, dynamic>.from(respuesta);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Historial de compras, de la más reciente a la más antigua.
  /// [hasta] es EXCLUSIVO (el día siguiente al último que quieres incluir).
  Future<List<Compra>> listar({
    DateTime? desde,
    DateTime? hasta,
    int? proveedorId,
    int limite = limiteConsulta,
  }) async {
    try {
      var filtro = _supabase.from('compras').select(_columnas);

      if (proveedorId != null) {
        filtro = filtro.eq('proveedor_id', proveedorId);
      }
      if (desde != null) {
        filtro = filtro.gte('fecha', desde.toUtc().toIso8601String());
      }
      if (hasta != null) {
        filtro = filtro.lt('fecha', hasta.toUtc().toIso8601String());
      }

      final datos =
      await filtro.order('fecha', ascending: false).limit(limite);

      return datos.map((fila) => Compra.fromMap(fila)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Compra?> buscarPorCodigo(String codigo) async {
    try {
      final fila = await _supabase
          .from('compras')
          .select(_columnas)
          .eq('codigo', codigo.trim().toUpperCase())
          .maybeSingle();

      return fila == null ? null : Compra.fromMap(fila);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}