import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/venta.dart';
import '../models/estado_venta.dart';
import '../models/eventoestado.dart';

class VentaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const int limiteConsulta = 100;

  static const String _columnas = '''
    id,
    codigo,
    fecha,
    total,
    usuario_id,
    cliente_id,
    estado,
    metodo_pago,
    tipo_entrega,
    sucursal_id,
    direccion_entrega_id,
    notas,
    motivo_anulacion,
    detalle_ventas(*),
    venta_estados(*)
  ''';

  // =====================================================
  // 1. REGISTRAR VENTA
  // =====================================================

  Future<Map<String, dynamic>> registrarVenta(
    List<Map<String, int>> items, {
    required String clienteId,
    String metodoPago = 'efectivo',
    String tipoEntrega = 'recojo',
    int? sucursalId,
    int? direccionId,
    String notas = '',
  }) async {
    if (items.isEmpty) {
      throw Exception('El carrito está vacío.');
    }

    try {
      final params = <String, dynamic>{
        'p_items': items,
        'p_cliente_id': clienteId,
        'p_metodo_pago': metodoPago,
        'p_tipo_entrega': tipoEntrega,
        'p_notas': notas,
      };

      if (sucursalId != null) {
        params['p_sucursal_id'] = sucursalId;
      }

      if (direccionId != null) {
        params['p_direccion_id'] = direccionId;
      }

      final respuesta = await _supabase.rpc('registrar_venta', params: params);

      if (respuesta is! Map) {
        throw Exception('Respuesta inválida del servidor.');
      }

      return Map<String, dynamic>.from(respuesta);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // =====================================================
  // 2. CONSULTAR VENTA POR CÓDIGO
  // =====================================================

  Future<Map<String, dynamic>?> consultarVenta(String codigo) async {
    final venta = await _supabase
        .from('ventas')
        .select(_columnas)
        .eq('codigo', codigo.trim().toUpperCase())
        .maybeSingle();

    return venta;
  }

  // =====================================================
  // 3. CONSULTAR COMPRAS DEL CLIENTE
  // =====================================================

  Future<List<Map<String, dynamic>>> misCompras(String clienteId) async {
    final respuesta = await _supabase
        .from('ventas')
        .select(_columnas)
        .eq('cliente_id', clienteId)
        .order('fecha', ascending: false);

    return List<Map<String, dynamic>>.from(respuesta);
  }

  // =====================================================
  // 4. LISTAR VENTAS
  // =====================================================

  Future<List<Venta>> listar({
    String? codigo,
    DateTime? desde,
    DateTime? hasta,
    EstadoVenta? estado,
    int limite = limiteConsulta,
  }) async {
    try {
      var filtro = _supabase.from('ventas').select(_columnas);

      final texto = (codigo ?? '').trim().replaceAll(RegExp(r'[%_,()]'), '');

      if (texto.isNotEmpty) {
        filtro = filtro.ilike('codigo', '%$texto%');
      }

      if (desde != null) {
        filtro = filtro.gte('fecha', desde.toUtc().toIso8601String());
      }

      if (hasta != null) {
        filtro = filtro.lt('fecha', hasta.toUtc().toIso8601String());
      }

      if (estado != null) {
        filtro = filtro.eq('estado', estado.valor);
      }

      final datos = await filtro.order('fecha', ascending: false).limit(limite);

      final ventas = datos.map((fila) => Venta.fromMap(fila)).toList();

      return _conNombres(ventas);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // =====================================================
  // 5. BUSCAR VENTA POR CÓDIGO
  // =====================================================

  Future<Venta?> buscarPorCodigo(String codigo) async {
    try {
      final fila = await _supabase
          .from('ventas')
          .select(_columnas)
          .eq('codigo', codigo.trim().toUpperCase())
          .maybeSingle();

      if (fila == null) return null;

      final ventas = await _conNombres([Venta.fromMap(fila)]);

      return ventas.first;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // =====================================================
  // 6. CONSULTAR HISTORIAL DE ESTADOS
  // =====================================================

  Future<List<EventoEstado>> obtenerHistorial(String ventaId) async {
    try {
      final respuesta = await _supabase
          .from('venta_estados')
          .select()
          .eq('venta_id', int.parse(ventaId))
          .order('fecha', ascending: true);

      return respuesta.map((fila) {
        return EventoEstado.fromMap(fila);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // =====================================================
  // 7. CAMBIAR ESTADO DE UNA VENTA
  // =====================================================

  Future<Map<String, dynamic>> cambiarEstadoVenta({
    required String ventaId,
    required EstadoVenta estado,
    String nota = '',
  }) async {
    if (estado == EstadoVenta.cancelado) {
      throw Exception('Utiliza anularVenta para cancelar una venta.');
    }

    try {
      final respuesta = await _supabase.rpc(
        'cambiar_estado_venta',
        params: {
          'p_venta_id': int.parse(ventaId),
          'p_estado': estado.valor,
          'p_nota': nota,
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

  // =====================================================
  // 8. ANULAR VENTA
  // =====================================================

  Future<Map<String, dynamic>> anularVenta({
    required String ventaId,
    String motivo = '',
  }) async {
    try {
      final respuesta = await _supabase.rpc(
        'anular_venta',
        params: {'p_venta_id': int.parse(ventaId), 'p_motivo': motivo},
      );

      if (respuesta is! Map) {
        throw Exception('Respuesta inválida del servidor.');
      }

      return Map<String, dynamic>.from(respuesta);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // =====================================================
  // 9. COMPLETAR NOMBRES DE CLIENTES Y VENDEDORES
  // =====================================================

  Future<List<Venta>> _conNombres(List<Venta> ventas) async {
    if (ventas.isEmpty) return ventas;

    final ids = <String>{};

    for (final venta in ventas) {
      if (venta.clienteId != null) {
        ids.add(venta.clienteId!);
      }

      if (venta.usuarioId != null) {
        ids.add(venta.usuarioId!);
      }
    }

    if (ids.isEmpty) return ventas;

    try {
      final filas = await _supabase
          .from('usuarios')
          .select('id,nombre,correo')
          .inFilter('id', ids.toList());

      final porId = <String, Map<String, dynamic>>{
        for (final fila in filas) fila['id'].toString(): fila,
      };

      return ventas.map((venta) {
        final cliente = porId[venta.clienteId];
        final vendedor = porId[venta.usuarioId];

        return venta.copyWith(
          clienteNombre: cliente?['nombre']?.toString(),
          clienteCorreo: cliente?['correo']?.toString(),
          vendedorNombre: vendedor?['nombre']?.toString(),
        );
      }).toList();
    } catch (_) {
      return ventas;
    }
  }
}
