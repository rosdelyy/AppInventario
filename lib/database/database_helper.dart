import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/movimiento_inventario.dart';
import '../models/producto.dart';
import '../models/venta.dart';

class StockInsuficienteException implements Exception {
  final String nombreProducto;
  final int stockDisponible;
  final int cantidadSolicitada;

  const StockInsuficienteException({
    required this.nombreProducto,
    required this.stockDisponible,
    required this.cantidadSolicitada,
  });

  @override
  String toString() {
    if (stockDisponible <= 0) {
      return 'Sin existencia de "$nombreProducto" (stock: 0).';
    }
    return 'Stock insuficiente para "$nombreProducto": disponible $stockDisponible u., solicitado $cantidadSolicitada u.';
  }
}

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'app_inventario_pos.db';
  static const int _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        sku TEXT NOT NULL UNIQUE,
        categoria TEXT NOT NULL,
        presentacion TEXT NOT NULL DEFAULT '1 pz',
        costo_compra REAL NOT NULL DEFAULT 0.0,
        precio_venta REAL NOT NULL DEFAULT 0.0,
        stock INTEGER NOT NULL DEFAULT 0,
        stock_minimo INTEGER NOT NULL DEFAULT 5,
        alerta_reposicion INTEGER NOT NULL DEFAULT 1,
        imagen_path TEXT,
        fecha_creacion TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero_ticket TEXT NOT NULL,
        fecha TEXT NOT NULL,
        subtotal REAL NOT NULL,
        total REAL NOT NULL,
        metodo_pago TEXT NOT NULL,
        paga_con REAL NOT NULL DEFAULT 0.0,
        cambio REAL NOT NULL DEFAULT 0.0,
        total_productos INTEGER NOT NULL,
        total_unidades INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE detalle_venta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        nombre_producto TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (venta_id) REFERENCES ventas (id) ON DELETE CASCADE,
        FOREIGN KEY (producto_id) REFERENCES productos (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE movimientos_inventario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        nombre_producto TEXT NOT NULL,
        venta_id INTEGER,
        tipo TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        stock_anterior INTEGER NOT NULL,
        stock_nuevo INTEGER NOT NULL,
        referencia TEXT NOT NULL,
        nota TEXT,
        fecha TEXT NOT NULL,
        FOREIGN KEY (producto_id) REFERENCES productos (id),
        FOREIGN KEY (venta_id) REFERENCES ventas (id) ON DELETE SET NULL
      )
    ''');

    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();
    final hoyIso = now.toIso8601String();

    final seedProducts = <Map<String, dynamic>>[
      {
        'nombre': 'Café Colombiano',
        'sku': 'BEB-042',
        'categoria': 'Bebidas',
        'presentacion': '500g',
        'costo_compra': 5.40,
        'precio_venta': 8.50,
        'stock': 4,
        'stock_minimo': 6,
        'alerta_reposicion': 1,
        'imagen_path': null,
        'fecha_creacion': hoyIso,
      },
      {
        'nombre': 'Aceite de Oliva Extra',
        'sku': 'ABA-108',
        'categoria': 'Abarrotes',
        'presentacion': '1L',
        'costo_compra': 8.20,
        'precio_venta': 12.00,
        'stock': 28,
        'stock_minimo': 8,
        'alerta_reposicion': 1,
        'imagen_path': null,
        'fecha_creacion': hoyIso,
      },
      {
        'nombre': 'Leche Entera Larga Vida',
        'sku': 'LAC-015',
        'categoria': 'Lácteos',
        'presentacion': '1L',
        'costo_compra': 1.15,
        'precio_venta': 1.80,
        'stock': 0,
        'stock_minimo': 10,
        'alerta_reposicion': 1,
        'imagen_path': null,
        'fecha_creacion': hoyIso,
      },
      {
        'nombre': 'Arroz Extra Selección',
        'sku': 'ABA-004',
        'categoria': 'Abarrotes',
        'presentacion': '1 kg',
        'costo_compra': 1.40,
        'precio_venta': 2.20,
        'stock': 65,
        'stock_minimo': 12,
        'alerta_reposicion': 1,
        'imagen_path': null,
        'fecha_creacion': hoyIso,
      },
      {
        'nombre': 'Detergente Multiuso',
        'sku': 'LIM-210',
        'categoria': 'Limpieza',
        'presentacion': '2L',
        'costo_compra': 4.50,
        'precio_venta': 6.90,
        'stock': 3,
        'stock_minimo': 5,
        'alerta_reposicion': 1,
        'imagen_path': null,
        'fecha_creacion': hoyIso,
      },
      {
        'nombre': 'Galletas de Avena con Miel',
        'sku': 'SNK-301',
        'categoria': 'Snacks y Botanas',
        'presentacion': '200g',
        'costo_compra': 3.20,
        'precio_venta': 5.50,
        'stock': 24,
        'stock_minimo': 6,
        'alerta_reposicion': 1,
        'imagen_path': null,
        'fecha_creacion': hoyIso,
      },
    ];

    final productIds = <String, int>{};
    for (final prod in seedProducts) {
      final id = await db.insert('productos', prod);
      productIds[prod['sku'] as String] = id;
    }

    // Venta inicial de ejemplo en el historial de hoy
    final sale1Time = now.subtract(const Duration(hours: 2)).toIso8601String();
    final venta1Id = await db.insert('ventas', {
      'numero_ticket': 'Ticket #1084',
      'fecha': sale1Time,
      'subtotal': 16.50,
      'total': 16.50,
      'metodo_pago': 'efectivo',
      'paga_con': 20.00,
      'cambio': 3.50,
      'total_productos': 1,
      'total_unidades': 3,
    });

    final galletasId = productIds['SNK-301']!;
    await db.insert('detalle_venta', {
      'venta_id': venta1Id,
      'producto_id': galletasId,
      'nombre_producto': 'Galletas de Avena con Miel',
      'cantidad': 3,
      'precio_unitario': 5.50,
      'subtotal': 16.50,
    });

    await db.insert('movimientos_inventario', {
      'producto_id': galletasId,
      'nombre_producto': 'Galletas de Avena con Miel',
      'venta_id': venta1Id,
      'tipo': TipoMovimiento.venta.dbValue,
      'cantidad': -3,
      'stock_anterior': 27,
      'stock_nuevo': 24,
      'referencia': 'Ticket #1084',
      'nota': 'Venta en mostrador (Efectivo)',
      'fecha': sale1Time,
    });

    // Recepcion de proveedor inicial
    final recTime = now.subtract(const Duration(hours: 4)).toIso8601String();
    final arrozId = productIds['ABA-004']!;
    final aceiteId = productIds['ABA-108']!;

    await db.insert('movimientos_inventario', {
      'producto_id': arrozId,
      'nombre_producto': 'Arroz Extra Selección',
      'venta_id': null,
      'tipo': TipoMovimiento.entrada.dbValue,
      'cantidad': 50,
      'stock_anterior': 15,
      'stock_nuevo': 65,
      'referencia': 'OC #OC-302',
      'nota': 'Recepción de proveedor',
      'fecha': recTime,
    });

    await db.insert('movimientos_inventario', {
      'producto_id': aceiteId,
      'nombre_producto': 'Aceite de Oliva Extra',
      'venta_id': null,
      'tipo': TipoMovimiento.entrada.dbValue,
      'cantidad': 24,
      'stock_anterior': 4,
      'stock_nuevo': 28,
      'referencia': 'OC #OC-302',
      'nota': 'Recepción de proveedor',
      'fecha': recTime,
    });

    // Merma inicial de ejemplo
    final mermaTime = now.subtract(const Duration(hours: 5)).toIso8601String();
    final detId = productIds['LIM-210']!;
    await db.insert('movimientos_inventario', {
      'producto_id': detId,
      'nombre_producto': 'Detergente Multiuso',
      'venta_id': null,
      'tipo': TipoMovimiento.merma.dbValue,
      'cantidad': -1,
      'stock_anterior': 4,
      'stock_nuevo': 3,
      'referencia': 'Ajuste por Merma',
      'nota': 'Envase dañado en almacén',
      'fecha': mermaTime,
    });
  }

  // ==================== PRODUCTOS ====================

  Future<List<Producto>> obtenerProductos() async {
    final db = await database;
    final rows = await db.query('productos', orderBy: 'id DESC');
    return rows.map(Producto.fromMap).toList();
  }

  Future<Producto?> obtenerProductoPorId(int id) async {
    final db = await database;
    final rows = await db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Producto.fromMap(rows.first);
  }

  Future<String> generarSkuAutomatico(String categoria) async {
    final db = await database;
    final clean = categoria.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final prefix = clean.length >= 3 ? clean.substring(0, 3) : 'PRD';
    final countResult = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM productos'),
        ) ??
        0;
    var seq = countResult + 101;
    while (true) {
      final candidate = '$prefix-$seq';
      final existing = await db.query(
        'productos',
        columns: ['id'],
        where: 'sku = ?',
        whereArgs: [candidate],
        limit: 1,
      );
      if (existing.isEmpty) return candidate;
      seq++;
    }
  }

  Future<int> insertarProducto(Producto producto) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert('productos', producto.toMap());
      if (producto.stock > 0) {
        await txn.insert('movimientos_inventario', {
          'producto_id': id,
          'nombre_producto': producto.nombre,
          'venta_id': null,
          'tipo': TipoMovimiento.entrada.dbValue,
          'cantidad': producto.stock,
          'stock_anterior': 0,
          'stock_nuevo': producto.stock,
          'referencia': 'Alta Inicial',
          'nota': 'Registro de nuevo producto (${producto.sku})',
          'fecha': DateTime.now().toIso8601String(),
        });
      }
      return id;
    });
  }

  Future<void> actualizarProducto(Producto producto) async {
    if (producto.id == null) return;
    final db = await database;
    await db.transaction((txn) async {
      final prevRows = await txn.query(
        'productos',
        where: 'id = ?',
        whereArgs: [producto.id],
        limit: 1,
      );
      final prevStock =
          prevRows.isNotEmpty ? (prevRows.first['stock'] as num).toInt() : producto.stock;

      await txn.update(
        'productos',
        producto.toMap(),
        where: 'id = ?',
        whereArgs: [producto.id],
      );

      final delta = producto.stock - prevStock;
      if (delta != 0) {
        await txn.insert('movimientos_inventario', {
          'producto_id': producto.id,
          'nombre_producto': producto.nombre,
          'venta_id': null,
          'tipo': TipoMovimiento.ajuste.dbValue,
          'cantidad': delta,
          'stock_anterior': prevStock,
          'stock_nuevo': producto.stock,
          'referencia': 'Edición de Producto',
          'nota': 'Ajuste directo al editar ficha',
          'fecha': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<void> eliminarProducto(int productoId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'movimientos_inventario',
        where: 'producto_id = ?',
        whereArgs: [productoId],
      );
      await txn.delete(
        'detalle_venta',
        where: 'producto_id = ?',
        whereArgs: [productoId],
      );
      await txn.delete(
        'productos',
        where: 'id = ?',
        whereArgs: [productoId],
      );
    });
  }

  /// Ajusta el stock de un producto en +/- delta o mediante un movimiento explicito.
  Future<void> registrarMovimientoManual({
    required int productoId,
    required TipoMovimiento tipo,
    required int cantidadDelta,
    required String referencia,
    String? nota,
  }) async {
    if (cantidadDelta == 0) return;
    final db = await database;

    await db.transaction((txn) async {
      final rows = await txn.query(
        'productos',
        where: 'id = ?',
        whereArgs: [productoId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw Exception('Producto no encontrado.');
      }

      final producto = Producto.fromMap(rows.first);
      final stockNuevo = producto.stock + cantidadDelta;

      if (stockNuevo < 0) {
        throw StockInsuficienteException(
          nombreProducto: producto.nombre,
          stockDisponible: producto.stock,
          cantidadSolicitada: cantidadDelta.abs(),
        );
      }

      await txn.update(
        'productos',
        {'stock': stockNuevo},
        where: 'id = ?',
        whereArgs: [productoId],
      );

      await txn.insert('movimientos_inventario', {
        'producto_id': productoId,
        'nombre_producto': producto.nombre,
        'venta_id': null,
        'tipo': tipo.dbValue,
        'cantidad': cantidadDelta,
        'stock_anterior': producto.stock,
        'stock_nuevo': stockNuevo,
        'referencia': referencia,
        'nota': nota,
        'fecha': DateTime.now().toIso8601String(),
      });
    });
  }

  // ==================== VENTAS ====================

  /// Registra una venta atomica: verifica stock disponible, inserta en `ventas`
  /// y `detalle_venta`, descuenta `productos.stock` y crea registros en `movimientos_inventario`.
  Future<Venta> registrarVenta({
    required List<CartItem> items,
    required MetodoPago metodoPago,
    required double pagaCon,
  }) async {
    if (items.isEmpty) {
      throw Exception('El ticket no tiene productos.');
    }

    final db = await database;

    return db.transaction((txn) async {
      double total = 0;
      int totalUnidades = 0;
      final verifiedItems = <({Producto producto, int cantidad})>[];

      // 1. Verificar existencia real en SQLite antes de descontar
      for (final item in items) {
        final pid = item.producto.id;
        if (pid == null) {
          throw Exception('Producto inválido en el carrito.');
        }

        final rows = await txn.query(
          'productos',
          where: 'id = ?',
          whereArgs: [pid],
          limit: 1,
        );
        if (rows.isEmpty) {
          throw Exception('El producto "${item.producto.nombre}" ya no existe.');
        }

        final dbProd = Producto.fromMap(rows.first);
        if (dbProd.stock < item.cantidad) {
          throw StockInsuficienteException(
            nombreProducto: dbProd.nombre,
            stockDisponible: dbProd.stock,
            cantidadSolicitada: item.cantidad,
          );
        }

        verifiedItems.add((producto: dbProd, cantidad: item.cantidad));
        total += dbProd.precioVenta * item.cantidad;
        totalUnidades += item.cantidad;
      }

      final montoPagado = metodoPago == MetodoPago.efectivo ? pagaCon : total;
      if (metodoPago == MetodoPago.efectivo && montoPagado + 0.001 < total) {
        throw Exception(
          'El monto recibido (\$${montoPagado.toStringAsFixed(2)}) es menor al total (\$${total.toStringAsFixed(2)}).',
        );
      }

      final cambio =
          metodoPago == MetodoPago.efectivo ? (montoPagado - total).clamp(0.0, double.infinity) : 0.0;

      // Generar numero de ticket consecutivo
      final maxIdResult = Sqflite.firstIntValue(
            await txn.rawQuery('SELECT COALESCE(MAX(id), 0) FROM ventas'),
          ) ??
          0;
      final numeroTicket = 'Ticket #${1084 + maxIdResult + 1}';
      final fechaIso = DateTime.now().toIso8601String();

      // 2. Insertar cabecera en `ventas`
      final ventaId = await txn.insert('ventas', {
        'numero_ticket': numeroTicket,
        'fecha': fechaIso,
        'subtotal': total,
        'total': total,
        'metodo_pago': metodoPago.dbValue,
        'paga_con': montoPagado,
        'cambio': cambio,
        'total_productos': verifiedItems.length,
        'total_unidades': totalUnidades,
      });

      // 3. Insertar detalle, descontar stock y registrar movimiento Kardex
      for (final entry in verifiedItems) {
        final prod = entry.producto;
        final qty = entry.cantidad;
        final lineSubtotal = prod.precioVenta * qty;
        final stockNuevo = prod.stock - qty;

        await txn.insert('detalle_venta', {
          'venta_id': ventaId,
          'producto_id': prod.id!,
          'nombre_producto': prod.nombre,
          'cantidad': qty,
          'precio_unitario': prod.precioVenta,
          'subtotal': lineSubtotal,
        });

        await txn.update(
          'productos',
          {'stock': stockNuevo},
          where: 'id = ?',
          whereArgs: [prod.id!],
        );

        await txn.insert('movimientos_inventario', {
          'producto_id': prod.id!,
          'nombre_producto': prod.nombre,
          'venta_id': ventaId,
          'tipo': TipoMovimiento.venta.dbValue,
          'cantidad': -qty,
          'stock_anterior': prod.stock,
          'stock_nuevo': stockNuevo,
          'referencia': numeroTicket,
          'nota': 'Venta (${metodoPago.label})',
          'fecha': fechaIso,
        });
      }

      return Venta(
        id: ventaId,
        numeroTicket: numeroTicket,
        fecha: fechaIso,
        subtotal: total,
        total: total,
        metodoPago: metodoPago.dbValue,
        pagaCon: montoPagado,
        cambio: cambio,
        totalProductos: verifiedItems.length,
        totalUnidades: totalUnidades,
      );
    });
  }

  Future<(Venta, List<DetalleVenta>)?> obtenerComprobanteVenta(int ventaId) async {
    final db = await database;
    final ventasRows = await db.query(
      'ventas',
      where: 'id = ?',
      whereArgs: [ventaId],
      limit: 1,
    );
    if (ventasRows.isEmpty) return null;

    final detalleRows = await db.query(
      'detalle_venta',
      where: 'venta_id = ?',
      whereArgs: [ventaId],
      orderBy: 'id ASC',
    );

    return (
      Venta.fromMap(ventasRows.first),
      detalleRows.map(DetalleVenta.fromMap).toList(),
    );
  }

  // ==================== HISTORIAL Y KARDEX ====================

  String? _datePrefix(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<ResumenMovimientos> obtenerResumenMovimientos({DateTime? fecha}) async {
    final db = await database;
    final prefix = _datePrefix(fecha);

    final ventasQuery = prefix != null
        ? await db.rawQuery(
            'SELECT COUNT(*) as cnt, COALESCE(SUM(total), 0) as monto FROM ventas WHERE substr(fecha, 1, 10) = ?',
            [prefix],
          )
        : await db.rawQuery(
            'SELECT COUNT(*) as cnt, COALESCE(SUM(total), 0) as monto FROM ventas',
          );

    final entradasQuery = prefix != null
        ? await db.rawQuery(
            'SELECT COALESCE(SUM(cantidad), 0) as uds FROM movimientos_inventario WHERE tipo = ? AND substr(fecha, 1, 10) = ?',
            [TipoMovimiento.entrada.dbValue, prefix],
          )
        : await db.rawQuery(
            'SELECT COALESCE(SUM(cantidad), 0) as uds FROM movimientos_inventario WHERE tipo = ?',
            [TipoMovimiento.entrada.dbValue],
          );

    final mermasQuery = prefix != null
        ? await db.rawQuery(
            'SELECT COALESCE(SUM(ABS(cantidad)), 0) as uds FROM movimientos_inventario WHERE tipo = ? AND substr(fecha, 1, 10) = ?',
            [TipoMovimiento.merma.dbValue, prefix],
          )
        : await db.rawQuery(
            'SELECT COALESCE(SUM(ABS(cantidad)), 0) as uds FROM movimientos_inventario WHERE tipo = ?',
            [TipoMovimiento.merma.dbValue],
          );

    return ResumenMovimientos(
      totalVentasCount: (ventasQuery.first['cnt'] as num?)?.toInt() ?? 0,
      totalVentasMonto: (ventasQuery.first['monto'] as num?)?.toDouble() ?? 0.0,
      totalEntradasUnidades: (entradasQuery.first['uds'] as num?)?.toInt() ?? 0,
      totalMermasUnidades: (mermasQuery.first['uds'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<MovimientoGrupo>> obtenerMovimientosAgrupados({
    DateTime? fecha,
    TipoMovimiento? tipoFiltro,
  }) async {
    final db = await database;
    final prefix = _datePrefix(fecha);

    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (prefix != null) {
      whereClauses.add('substr(m.fecha, 1, 10) = ?');
      whereArgs.add(prefix);
    }
    if (tipoFiltro != null) {
      whereClauses.add('m.tipo = ?');
      whereArgs.add(tipoFiltro.dbValue);
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final rows = await db.rawQuery('''
      SELECT m.*, v.total as venta_total, v.metodo_pago as venta_metodo_pago
      FROM movimientos_inventario m
      LEFT JOIN ventas v ON m.venta_id = v.id
      $whereSql
      ORDER BY m.fecha DESC, m.id DESC
    ''', whereArgs);

    final grupos = <MovimientoGrupo>[];
    final Map<String, int> groupIndex = {};

    for (final row in rows) {
      final mov = MovimientoInventario.fromMap(row);
      final ventaTotal = (row['venta_total'] as num?)?.toDouble();
      final metodoPago = row['venta_metodo_pago'] as String?;

      // Agrupa items de una misma venta o de una misma recepcion (misma referencia + minuto)
      final key = mov.ventaId != null
          ? 'venta_${mov.ventaId}'
          : '${mov.tipo}_${mov.referencia}_${mov.fecha.substring(0, mov.fecha.length >= 16 ? 16 : mov.fecha.length)}';

      if (groupIndex.containsKey(key)) {
        final idx = groupIndex[key]!;
        grupos[idx].items.add(mov);
      } else {
        groupIndex[key] = grupos.length;
        grupos.add(
          MovimientoGrupo(
            titulo: mov.referencia,
            tipo: mov.tipo,
            fecha: mov.fecha,
            ventaId: mov.ventaId,
            montoVenta: ventaTotal,
            metodoPago: metodoPago,
            items: [mov],
          ),
        );
      }
    }

    return grupos;
  }

  Future<Map<String, dynamic>> obtenerResumenCajaHoy() async {
    final db = await database;
    final prefix = _datePrefix(DateTime.now())!;

    final totalRow = await db.rawQuery(
      'SELECT COUNT(*) as ventas_count, COALESCE(SUM(total), 0) as total_dia FROM ventas WHERE substr(fecha, 1, 10) = ?',
      [prefix],
    );

    final porMetodo = await db.rawQuery(
      'SELECT metodo_pago, COALESCE(SUM(total), 0) as monto, COUNT(*) as cnt FROM ventas WHERE substr(fecha, 1, 10) = ? GROUP BY metodo_pago',
      [prefix],
    );

    final breakdown = <String, double>{'efectivo': 0, 'tarjeta': 0, 'qr': 0};
    for (final row in porMetodo) {
      final metodo = row['metodo_pago'] as String;
      breakdown[metodo] = (row['monto'] as num?)?.toDouble() ?? 0.0;
    }

    return {
      'ventasCount': (totalRow.first['ventas_count'] as num?)?.toInt() ?? 0,
      'totalDia': (totalRow.first['total_dia'] as num?)?.toDouble() ?? 0.0,
      'efectivo': breakdown['efectivo'] ?? 0.0,
      'tarjeta': breakdown['tarjeta'] ?? 0.0,
      'qr': breakdown['qr'] ?? 0.0,
    };
  }
}
