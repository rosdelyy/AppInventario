/// Tipos de movimiento registrados en `movimientos_inventario`.
enum TipoMovimiento {
  venta('VENTA', 'Salidas por Venta'),
  entrada('ENTRADA', 'Entradas Proveedor'),
  ajuste('AJUSTE', 'Ajustes'),
  merma('MERMA', 'Mermas');

  final String dbValue;
  final String filterLabel;

  const TipoMovimiento(this.dbValue, this.filterLabel);

  static TipoMovimiento fromDb(String value) {
    return TipoMovimiento.values.firstWhere(
      (t) => t.dbValue == value,
      orElse: () => TipoMovimiento.ajuste,
    );
  }
}

/// Registro individual de Kardex en la tabla `movimientos_inventario`.
class MovimientoInventario {
  final int? id;
  final int productoId;
  final String nombreProducto;
  final int? ventaId;
  final String tipo;
  final int cantidad;
  final int stockAnterior;
  final int stockNuevo;
  final String referencia;
  final String? nota;
  final String fecha;

  const MovimientoInventario({
    this.id,
    required this.productoId,
    required this.nombreProducto,
    this.ventaId,
    required this.tipo,
    required this.cantidad,
    required this.stockAnterior,
    required this.stockNuevo,
    required this.referencia,
    this.nota,
    required this.fecha,
  });

  TipoMovimiento get tipoEnum => TipoMovimiento.fromDb(tipo);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'producto_id': productoId,
      'nombre_producto': nombreProducto,
      'venta_id': ventaId,
      'tipo': tipo,
      'cantidad': cantidad,
      'stock_anterior': stockAnterior,
      'stock_nuevo': stockNuevo,
      'referencia': referencia,
      'nota': nota,
      'fecha': fecha,
    };
  }

  factory MovimientoInventario.fromMap(Map<String, dynamic> map) {
    return MovimientoInventario(
      id: map['id'] as int?,
      productoId: (map['producto_id'] as num).toInt(),
      nombreProducto: map['nombre_producto'] as String,
      ventaId: map['venta_id'] as int?,
      tipo: map['tipo'] as String,
      cantidad: (map['cantidad'] as num).toInt(),
      stockAnterior: (map['stock_anterior'] as num).toInt(),
      stockNuevo: (map['stock_nuevo'] as num).toInt(),
      referencia: map['referencia'] as String,
      nota: map['nota'] as String?,
      fecha: map['fecha'] as String,
    );
  }
}

/// Agrupacion visual para mostrar tickets con multiples productos o movimientos individuales.
class MovimientoGrupo {
  final String titulo;
  final String tipo;
  final String fecha;
  final int? ventaId;
  final double? montoVenta;
  final String? metodoPago;
  final List<MovimientoInventario> items;

  const MovimientoGrupo({
    required this.titulo,
    required this.tipo,
    required this.fecha,
    this.ventaId,
    this.montoVenta,
    this.metodoPago,
    required this.items,
  });
}

/// Resumen operativo para las 3 metricas superiores del Historial.
class ResumenMovimientos {
  final int totalVentasCount;
  final double totalVentasMonto;
  final int totalEntradasUnidades;
  final int totalMermasUnidades;

  const ResumenMovimientos({
    required this.totalVentasCount,
    required this.totalVentasMonto,
    required this.totalEntradasUnidades,
    required this.totalMermasUnidades,
  });
}
