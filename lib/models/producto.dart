/// Modelo de producto almacenado en la tabla `productos`.
class Producto {
  final int? id;
  final String nombre;
  final String sku;
  final String categoria;
  final String presentacion;
  final double costoCompra;
  final double precioVenta;
  final int stock;
  final int stockMinimo;
  final bool alertaReposicion;
  final String? imagenPath;
  final String fechaCreacion;

  const Producto({
    this.id,
    required this.nombre,
    required this.sku,
    required this.categoria,
    this.presentacion = '1 pz',
    required this.costoCompra,
    required this.precioVenta,
    required this.stock,
    required this.stockMinimo,
    this.alertaReposicion = true,
    this.imagenPath,
    required this.fechaCreacion,
  });

  bool get isAgotado => stock <= 0;

  bool get isStockBajo => stock > 0 && stock <= stockMinimo;

  bool get isStockNormal => stock > stockMinimo;

  double get valorTotal => precioVenta * stock;

  Producto copyWith({
    int? id,
    String? nombre,
    String? sku,
    String? categoria,
    String? presentacion,
    double? costoCompra,
    double? precioVenta,
    int? stock,
    int? stockMinimo,
    bool? alertaReposicion,
    String? imagenPath,
    bool clearImagen = false,
    String? fechaCreacion,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      sku: sku ?? this.sku,
      categoria: categoria ?? this.categoria,
      presentacion: presentacion ?? this.presentacion,
      costoCompra: costoCompra ?? this.costoCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      stock: stock ?? this.stock,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      alertaReposicion: alertaReposicion ?? this.alertaReposicion,
      imagenPath: clearImagen ? null : (imagenPath ?? this.imagenPath),
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'sku': sku,
      'categoria': categoria,
      'presentacion': presentacion,
      'costo_compra': costoCompra,
      'precio_venta': precioVenta,
      'stock': stock,
      'stock_minimo': stockMinimo,
      'alerta_reposicion': alertaReposicion ? 1 : 0,
      'imagen_path': imagenPath,
      'fecha_creacion': fechaCreacion,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      sku: map['sku'] as String,
      categoria: map['categoria'] as String,
      presentacion: (map['presentacion'] as String?) ?? '1 pz',
      costoCompra: (map['costo_compra'] as num).toDouble(),
      precioVenta: (map['precio_venta'] as num).toDouble(),
      stock: (map['stock'] as num).toInt(),
      stockMinimo: (map['stock_minimo'] as num).toInt(),
      alertaReposicion: ((map['alerta_reposicion'] as int?) ?? 1) == 1,
      imagenPath: map['imagen_path'] as String?,
      fechaCreacion: map['fecha_creacion'] as String,
    );
  }
}

/// Categorias disponibles en el catalogo y registro.
class CategoriasCatalogo {
  CategoriasCatalogo._();

  static const List<String> todas = [
    'Snacks y Botanas',
    'Bebidas',
    'Abarrotes',
    'Lácteos',
    'Limpieza',
    'Golosinas y Dulces',
    'Cuidado Personal',
  ];
}
