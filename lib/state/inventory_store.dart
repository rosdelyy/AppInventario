import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/movimiento_inventario.dart';
import '../models/producto.dart';
import '../models/venta.dart';

/// Estado compartido reactivo que sincroniza las 4 pantallas con SQLite.
class InventoryStore extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Producto> _productos = [];
  List<MovimientoGrupo> _movimientos = [];
  ResumenMovimientos _resumen = const ResumenMovimientos(
    totalVentasCount: 0,
    totalVentasMonto: 0,
    totalEntradasUnidades: 0,
    totalMermasUnidades: 0,
  );

  bool _isLoading = true;
  DateTime? _historialFecha = DateTime.now();
  TipoMovimiento? _historialTipo;

  List<Producto> get productos => List.unmodifiable(_productos);
  List<MovimientoGrupo> get movimientos => List.unmodifiable(_movimientos);
  ResumenMovimientos get resumen => _resumen;
  bool get isLoading => _isLoading;
  DateTime? get historialFecha => _historialFecha;
  TipoMovimiento? get historialTipo => _historialTipo;

  double get valorTotalAlmacen =>
      _productos.fold<double>(0.0, (sum, p) => sum + p.valorTotal);

  int get totalSkus => _productos.length;

  int get totalStockBajo => _productos.where((p) => p.isStockBajo).length;

  int get totalAgotados => _productos.where((p) => p.isAgotado).length;

  Future<void> cargarTodo() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        cargarProductos(notify: false),
        cargarHistorial(notify: false),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarProductos({bool notify = true}) async {
    _productos = await _db.obtenerProductos();
    if (notify) notifyListeners();
  }

  Future<void> cargarHistorial({bool notify = true}) async {
    _movimientos = await _db.obtenerMovimientosAgrupados(
      fecha: _historialFecha,
      tipoFiltro: _historialTipo,
    );
    _resumen = await _db.obtenerResumenMovimientos(fecha: _historialFecha);
    if (notify) notifyListeners();
  }

  Future<void> actualizarFiltrosHistorial({
    DateTime? fecha,
    bool limpiarFecha = false,
    TipoMovimiento? tipo,
    bool limpiarTipo = false,
  }) async {
    if (limpiarFecha) {
      _historialFecha = null;
    } else if (fecha != null) {
      _historialFecha = fecha;
    }

    if (limpiarTipo) {
      _historialTipo = null;
    } else if (tipo != null) {
      _historialTipo = tipo;
    }

    await cargarHistorial();
  }

  Future<void> registrarProducto(Producto producto) async {
    final skuFinal = producto.sku.trim().isEmpty
        ? await _db.generarSkuAutomatico(producto.categoria)
        : producto.sku.trim().toUpperCase();

    await _db.insertarProducto(producto.copyWith(sku: skuFinal));
    await Future.wait([
      cargarProductos(notify: false),
      cargarHistorial(notify: false),
    ]);
    notifyListeners();
  }

  Future<void> actualizarProducto(Producto producto) async {
    await _db.actualizarProducto(producto);
    await Future.wait([
      cargarProductos(notify: false),
      cargarHistorial(notify: false),
    ]);
    notifyListeners();
  }

  Future<void> eliminarProducto(int productoId) async {
    await _db.eliminarProducto(productoId);
    await Future.wait([
      cargarProductos(notify: false),
      cargarHistorial(notify: false),
    ]);
    notifyListeners();
  }

  Future<void> ajustarStockRapido({
    required Producto producto,
    required int delta,
    TipoMovimiento? tipoExplicito,
    String? referencia,
    String? nota,
  }) async {
    if (producto.id == null) return;
    final tipo = tipoExplicito ??
        (delta > 0 ? TipoMovimiento.entrada : TipoMovimiento.ajuste);

    await _db.registrarMovimientoManual(
      productoId: producto.id!,
      tipo: tipo,
      cantidadDelta: delta,
      referencia: referencia ??
          (tipo == TipoMovimiento.entrada
              ? 'Reabastecimiento Rápido'
              : tipo == TipoMovimiento.merma
                  ? 'Ajuste por Merma'
                  : 'Ajuste de Inventario'),
      nota: nota,
    );

    await Future.wait([
      cargarProductos(notify: false),
      cargarHistorial(notify: false),
    ]);
    notifyListeners();
  }

  Future<Venta> confirmarVenta({
    required List<CartItem> items,
    required MetodoPago metodoPago,
    required double pagaCon,
  }) async {
    final venta = await _db.registrarVenta(
      items: items,
      metodoPago: metodoPago,
      pagaCon: pagaCon,
    );

    await Future.wait([
      cargarProductos(notify: false),
      cargarHistorial(notify: false),
    ]);
    notifyListeners();
    return venta;
  }

  Future<(Venta, List<DetalleVenta>)?> obtenerComprobante(int ventaId) {
    return _db.obtenerComprobanteVenta(ventaId);
  }

  Future<Map<String, dynamic>> obtenerResumenCajaHoy() {
    return _db.obtenerResumenCajaHoy();
  }
}
