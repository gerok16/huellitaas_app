import 'package:flutter/material.dart';
import '../models/producto.dart';

class ItemCarrito {
  final Producto producto;
  int cantidad;

  ItemCarrito({
    required this.producto,
    this.cantidad = 1,
  });

  double get subtotal => producto.precio * cantidad;
}

class CarritoProvider extends ChangeNotifier {
  final Map<int, ItemCarrito> _items = {};

  /// Id del usuario dueño del carrito actual.
  String? _usuarioId;

  List<ItemCarrito> get items => _items.values.toList();

  int get cantidadTotal =>
      _items.values.fold(0, (total, item) => total + item.cantidad);

  double get total =>
      _items.values.fold(0, (suma, item) => suma + item.subtotal);

  /// Vacía el carrito si cambió el usuario (logout o cambio de cuenta).
  ///
  /// No llama a notifyListeners() a propósito: este método se ejecuta
  /// desde el `update` de ChangeNotifierProxyProvider, es decir, durante
  /// el build, y notificar ahí provocaría un error de Flutter.
  void sincronizarUsuario(String? usuarioId) {
    if (_usuarioId == usuarioId) return;
    _usuarioId = usuarioId;
    _items.clear();
  }

  bool agregarProducto(Producto producto) {
    if (!producto.activo || producto.stock <= 0) return false;

    final existente = _items[producto.id];

    if (existente != null) {
      if (existente.cantidad >= producto.stock) return false;
      existente.cantidad++;
    } else {
      _items[producto.id] = ItemCarrito(producto: producto);
    }

    notifyListeners();
    return true;
  }

  bool aumentarCantidad(int id) {
    final item = _items[id];
    if (item == null || item.cantidad >= item.producto.stock) {
      return false;
    }

    item.cantidad++;
    notifyListeners();
    return true;
  }

  void disminuirCantidad(int id) {
    final item = _items[id];
    if (item == null) return;

    if (item.cantidad > 1) {
      item.cantidad--;
    } else {
      _items.remove(id);
    }

    notifyListeners();
  }

  void eliminarProducto(int id) {
    _items.remove(id);
    notifyListeners();
  }

  void vaciarCarrito() {
    _items.clear();
    notifyListeners();
  }
}
