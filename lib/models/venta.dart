import 'producto.dart';

enum MetodoPago {
  efectivo('efectivo', 'Efectivo'),
  tarjeta('tarjeta', 'Tarjeta'),
  qr('qr', 'QR / Transf.');

  final String dbValue;
  final String label;

  const MetodoPago(this.dbValue, this.label);

  static MetodoPago fromDb(String value) {
    return MetodoPago.values.firstWhere(
      (m) => m.dbValue == value,
      orElse: () => MetodoPago.efectivo,
    );
  }
}

/// Item temporal en el ticket antes de confirmar la venta.
class CartItem {
  final Producto producto;
  int cantidad;

  CartItem({
    required this.producto,
    this.cantidad = 1,
  });

  double get subtotal => producto.precioVenta * cantidad;
}

/// Modelo de cabecera de venta almacenada en la tabla `ventas`.
class Venta {
  final int? id;
  final String numeroTicket;
  final String fecha;
  final double subtotal;
  final double total;
  final String metodoPago;
  final double pagaCon;
  final double cambio;
  final int totalProductos;
  final int totalUnidades;

  const Venta({
    this.id,
    required this.numeroTicket,
    required this.fecha,
    required this.subtotal,
    required this.total,
    required this.metodoPago,
    required this.pagaCon,
    required this.cambio,
    required this.totalProductos,
    required this.totalUnidades,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'numero_ticket': numeroTicket,
      'fecha': fecha,
      'subtotal': subtotal,
      'total': total,
      'metodo_pago': metodoPago,
      'paga_con': pagaCon,
      'cambio': cambio,
      'total_productos': totalProductos,
      'total_unidades': totalUnidades,
    };
  }

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'] as int?,
      numeroTicket: map['numero_ticket'] as String,
      fecha: map['fecha'] as String,
      subtotal: (map['subtotal'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      metodoPago: map['metodo_pago'] as String,
      pagaCon: (map['paga_con'] as num).toDouble(),
      cambio: (map['cambio'] as num).toDouble(),
      totalProductos: (map['total_productos'] as num).toInt(),
      totalUnidades: (map['total_unidades'] as num).toInt(),
    );
  }
}

/// Modelo de linea de venta almacenada en la tabla `detalle_venta`.
class DetalleVenta {
  final int? id;
  final int ventaId;
  final int productoId;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  const DetalleVenta({
    this.id,
    required this.ventaId,
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'venta_id': ventaId,
      'producto_id': productoId,
      'nombre_producto': nombreProducto,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }

  factory DetalleVenta.fromMap(Map<String, dynamic> map) {
    return DetalleVenta(
      id: map['id'] as int?,
      ventaId: (map['venta_id'] as num).toInt(),
      productoId: (map['producto_id'] as num).toInt(),
      nombreProducto: map['nombre_producto'] as String,
      cantidad: (map['cantidad'] as num).toInt(),
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}
