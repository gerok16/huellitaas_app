enum EstadoVenta {
  pendiente,
  pagado,
  preparando,
  listo,
  entregado,
  cancelado;

  /// Convierte el texto de Supabase en un estado de Dart.
  static EstadoVenta desdeTexto(String? valor) {
    switch (valor?.toLowerCase()) {
      case 'pendiente':
        return EstadoVenta.pendiente;
      case 'pagado':
        return EstadoVenta.pagado;
      case 'preparando':
        return EstadoVenta.preparando;
      case 'listo':
        return EstadoVenta.listo;
      case 'entregado':
        return EstadoVenta.entregado;
      case 'cancelado':
        return EstadoVenta.cancelado;
      default:
        return EstadoVenta.entregado;
    }
  }

  String get valor => name;

  String get nombre {
    switch (this) {
      case EstadoVenta.pendiente:
        return 'Pendiente';
      case EstadoVenta.pagado:
        return 'Pagado';
      case EstadoVenta.preparando:
        return 'Preparando';
      case EstadoVenta.listo:
        return 'Listo para entregar';
      case EstadoVenta.entregado:
        return 'Entregado';
      case EstadoVenta.cancelado:
        return 'Cancelado';
    }
  }

  String get descripcion {
    switch (this) {
      case EstadoVenta.pendiente:
        return 'El pedido fue recibido.';
      case EstadoVenta.pagado:
        return 'El pago fue confirmado.';
      case EstadoVenta.preparando:
        return 'El pedido está siendo preparado.';
      case EstadoVenta.listo:
        return 'El pedido está listo para entregar.';
      case EstadoVenta.entregado:
        return 'El pedido fue entregado.';
      case EstadoVenta.cancelado:
        return 'La venta fue anulada.';
    }
  }

  bool get esFinal =>
      this == EstadoVenta.entregado || this == EstadoVenta.cancelado;

  bool get permiteAvanzar => !esFinal;
}
