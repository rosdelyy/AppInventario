import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../state/inventory_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class NuevaVentaScreen extends StatefulWidget {
  final InventoryStore store;

  const NuevaVentaScreen({super.key, required this.store});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _tenderCtrl = TextEditingController(text: '50.00');

  final List<CartItem> _cart = [];
  String _searchQuery = '';
  MetodoPago _metodoPago = MetodoPago.efectivo;
  double? _selectedQuickBill;
  bool _processing = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tenderCtrl.dispose();
    super.dispose();
  }

  double get _totalCobrar =>
      _cart.fold<double>(0.0, (sum, item) => sum + item.subtotal);

  int get _totalUnidades =>
      _cart.fold<int>(0, (sum, item) => sum + item.cantidad);

  double get _pagaCon => double.tryParse(_tenderCtrl.text.trim()) ?? 0.0;

  double get _cambio => _pagaCon - _totalCobrar;

  List<double> _quickAmounts() {
    final total = _totalCobrar;
    final ceilAmount = total <= 0 ? 20.0 : total.ceilToDouble();
    final set = <double>{ceilAmount, 50.0, 100.0};
    final list = set.where((v) => v >= total || total == 0).toList()..sort();
    if (list.length < 3) {
      for (final extra in [20.0, 50.0, 100.0, 200.0]) {
        if (!list.contains(extra)) list.add(extra);
        if (list.length >= 3) break;
      }
      list.sort();
    }
    return list.take(3).toList();
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? AppColors.error : AppColors.inverseSurface,
          content: Row(
            children: [
              Icon(
                isError ? Icons.block : Icons.check_circle,
                color: isError ? AppColors.onError : AppColors.secondaryFixed,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  void _addProductToCart(Producto producto) {
    // Obtener el stock más reciente del store
    final liveProduct = widget.store.productos.firstWhere(
      (p) => p.id == producto.id,
      orElse: () => producto,
    );

    if (liveProduct.stock <= 0) {
      _showFeedback(
        'Venta bloqueada: "${liveProduct.nombre}" está agotado (0 unidades).',
        isError: true,
      );
      return;
    }

    final existingIdx =
        _cart.indexWhere((c) => c.producto.id == liveProduct.id);
    if (existingIdx >= 0) {
      final currentQty = _cart[existingIdx].cantidad;
      if (currentQty + 1 > liveProduct.stock) {
        _showFeedback(
          'Stock insuficiente para "${liveProduct.nombre}": máximo ${liveProduct.stock} u. disponibles.',
          isError: true,
        );
        return;
      }
      setState(() {
        _cart[existingIdx] = CartItem(
          producto: liveProduct,
          cantidad: currentQty + 1,
        );
      });
    } else {
      setState(() {
        _cart.add(CartItem(producto: liveProduct, cantidad: 1));
      });
    }
  }

  void _updateCartQty(int index, int delta) {
    final item = _cart[index];
    final liveProduct = widget.store.productos.firstWhere(
      (p) => p.id == item.producto.id,
      orElse: () => item.producto,
    );
    final newQty = item.cantidad + delta;

    if (newQty <= 0) {
      setState(() => _cart.removeAt(index));
      return;
    }

    if (newQty > liveProduct.stock) {
      _showFeedback(
        'Stock máximo alcanzado: solo hay ${liveProduct.stock} u. de "${liveProduct.nombre}".',
        isError: true,
      );
      return;
    }

    setState(() {
      _cart[index] = CartItem(producto: liveProduct, cantidad: newQty);
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  Future<void> _confirmarYCobrar() async {
    if (_cart.isEmpty) {
      _showFeedback('Agrega al menos un producto al ticket.', isError: true);
      return;
    }

    if (_metodoPago == MetodoPago.efectivo && _pagaCon + 0.001 < _totalCobrar) {
      _showFeedback(
        'El monto recibido (\$${_pagaCon.toStringAsFixed(2)}) no cubre el total (\$${_totalCobrar.toStringAsFixed(2)}).',
        isError: true,
      );
      return;
    }

    setState(() => _processing = true);
    try {
      final venta = await widget.store.confirmarVenta(
        items: List<CartItem>.from(_cart),
        metodoPago: _metodoPago,
        pagaCon: _pagaCon,
      );

      if (!mounted) return;
      final itemsVendidos = List<CartItem>.from(_cart);
      setState(() {
        _cart.clear();
        _searchCtrl.clear();
        _searchQuery = '';
      });

      await _showSuccessModal(venta, itemsVendidos);
    } on StockInsuficienteException catch (e) {
      _showFeedback('Venta bloqueada: ${e.toString()}', isError: true);
    } catch (e) {
      _showFeedback(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _showSuccessModal(Venta venta, List<CartItem> items) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.onSecondaryContainer,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '¡Venta Completada!',
                style: AppTheme.headlineMd(color: AppColors.onSurface),
              ),
              const SizedBox(height: 6),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTheme.bodyMd(color: AppColors.onSurfaceVariant),
                  children: [
                    const TextSpan(text: 'Cobro por '),
                    TextSpan(
                      text: AppFormatters.money(venta.total),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(
                      text: ' registrado con éxito. Inventario actualizado.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cambio entregado:',
                      style: AppTheme.bodySm(color: AppColors.outline),
                    ),
                    Text(
                      AppFormatters.money(venta.cambio),
                      style: AppTheme.titleMd(color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Nueva Venta'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showDigitalReceipt(venta, items);
                  },
                  child: Text(
                    'Ver Comprobante Digital',
                    style: AppTheme.labelMd(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDigitalReceipt(Venta venta, List<CartItem> items) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  venta.numeroTicket,
                  style: AppTheme.headlineMd(color: AppColors.onSurface),
                ),
                Text(
                  AppFormatters.shortTime(venta.fecha),
                  style: AppTheme.labelMd(color: AppColors.outline),
                ),
              ],
            ),
            Text(
              'Mi Tienda - Sucursal Centro • ${MetodoPago.fromDb(venta.metodoPago).label}',
              style: AppTheme.bodySm(color: AppColors.secondary),
            ),
            const Divider(height: 24),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.cantidad}x ${item.producto.nombre}',
                        style: AppTheme.bodyMd(color: AppColors.onSurface),
                      ),
                    ),
                    Text(
                      AppFormatters.money(item.subtotal),
                      style: AppTheme.titleMd(color: AppColors.onSurface),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL', style: AppTheme.titleMd(color: AppColors.primary)),
                Text(
                  AppFormatters.money(venta.total),
                  style: AppTheme.headlineMd(color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openCatalogPickerModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (ctx, scrollCtrl) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seleccionar Producto',
                          style: AppTheme.headlineMd(color: AppColors.onSurface),
                        ),
                        Text(
                          '${widget.store.productos.length} SKUs',
                          style: AppTheme.labelMd(color: AppColors.outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: widget.store.productos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final p = widget.store.productos[i];
                    final agotado = p.isAgotado;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: AppColors.surfaceContainerLow,
                      title: Text(
                        p.nombre,
                        style: AppTheme.titleMd(color: AppColors.onSurface),
                      ),
                      subtitle: Text(
                        '${p.sku} • ${agotado ? "Agotado" : "Stock: ${p.stock} u."}',
                        style: AppTheme.bodySm(
                          color: agotado ? AppColors.error : AppColors.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        AppFormatters.money(p.precioVenta),
                        style: AppTheme.titleMd(color: AppColors.primary),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _addProductToCart(p);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = widget.store.productos;
    final q = _searchQuery.trim().toLowerCase();
    final matchingProducts = q.isEmpty
        ? <Producto>[]
        : allProducts
            .where(
              (p) =>
                  p.nombre.toLowerCase().contains(q) ||
                  p.sku.toLowerCase().contains(q),
            )
            .toList();

    final quickBills = _quickAmounts();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Search & Barcode Quick Access Bar
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: AppTheme.bodyMd(color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto o SKU...',
                    hintStyle: AppTheme.bodyMd(color: AppColors.outline),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.outline,
                      size: 22,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              width: 54,
              child: ElevatedButton(
                onPressed: _openCatalogPickerModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Icon(Icons.qr_code_scanner, size: 22),
              ),
            ),
          ],
        ),

        // Resultados de busqueda instantanea para agregar al ticket
        if (matchingProducts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: matchingProducts.take(4).map((p) {
                final agotado = p.isAgotado;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: Text(
                    p.nombre,
                    style: AppTheme.titleMd(color: AppColors.onSurface),
                  ),
                  subtitle: Text(
                    '${p.sku} • ${agotado ? "Agotado" : "Disponible: ${p.stock} u."}',
                    style: AppTheme.bodySm(
                      color: agotado ? AppColors.error : AppColors.secondary,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: agotado
                          ? AppColors.errorContainer
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      agotado
                          ? 'Sin stock'
                          : '+ ${AppFormatters.money(p.precioVenta)}',
                      style: AppTheme.labelSm(
                        color: agotado
                            ? AppColors.onErrorContainer
                            : AppColors.onPrimary,
                      ),
                    ),
                  ),
                  onTap: () {
                    _addProductToCart(p);
                    if (!p.isAgotado) {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ] else if (allProducts.isNotEmpty) ...[
          // Acceso rapido horizontal cuando no hay texto de busqueda
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: allProducts.take(6).map((p) {
                final agotado = p.isAgotado;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: agotado
                        ? AppColors.errorContainer.withOpacity(0.5)
                        : AppColors.surfaceContainerLowest,
                    side: BorderSide.none,
                    avatar: Icon(
                      agotado ? Icons.block : Icons.add_circle,
                      size: 16,
                      color: agotado ? AppColors.error : AppColors.secondary,
                    ),
                    label: Text(
                      '${p.nombre} (${AppFormatters.money(p.precioVenta)})',
                      style: AppTheme.labelSm(
                        color: agotado
                            ? AppColors.onErrorContainer
                            : AppColors.onSurface,
                      ),
                    ),
                    onPressed: () => _addProductToCart(p),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Ticket de Venta Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ticket de Venta',
                            style: AppTheme.titleMd(color: AppColors.onSurface),
                          ),
                          Text(
                            '${_cart.length} ${_cart.length == 1 ? "producto registrado" : "productos registrados"}',
                            style: AppTheme.labelSm(color: AppColors.outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _cart.isEmpty ? null : _clearCart,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep,
                            size: 18,
                            color: _cart.isEmpty
                                ? AppColors.outline
                                : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Vaciar',
                            style: AppTheme.labelSm(
                              color: _cart.isEmpty
                                  ? AppColors.outline
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cart items
              if (_cart.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        size: 32,
                        color: AppColors.outline,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ticket vacío',
                        style: AppTheme.titleMd(color: AppColors.onSurface),
                      ),
                      Text(
                        'Busca arriba o toca el botón de catálogo para añadir productos.',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: List.generate(_cart.length, (i) {
                    final item = _cart[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.producto.nombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.titleMd(
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${AppFormatters.money(item.producto.precioVenta)} c/u • Disp: ${item.producto.stock} u.',
                                  style: AppTheme.bodySm(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                _CartQtyBtn(
                                  icon: Icons.remove,
                                  onTap: () => _updateCartQty(i, -1),
                                ),
                                SizedBox(
                                  width: 26,
                                  child: Text(
                                    '${item.cantidad}',
                                    textAlign: TextAlign.center,
                                    style: AppTheme.titleMd(
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ),
                                _CartQtyBtn(
                                  icon: Icons.add,
                                  onTap: () => _updateCartQty(i, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 64,
                            child: Text(
                              AppFormatters.money(item.subtotal),
                              textAlign: TextAlign.right,
                              style: AppTheme.titleMd(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),

              const SizedBox(height: 8),

              // Financial Calculation Matrix
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal (inc. IVA)',
                          style: AppTheme.bodySm(color: AppColors.outline),
                        ),
                        Text(
                          AppFormatters.money(_totalCobrar),
                          style: AppTheme.labelMd(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL A COBRAR',
                                style: AppTheme.labelSm(
                                  color: AppColors.outline,
                                ),
                              ),
                              Text(
                                '${_cart.length} productos • $_totalUnidades unidades',
                                style: AppTheme.labelSm(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            AppFormatters.money(_totalCobrar),
                            style: AppTheme.displayLgMobile(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Método de Pago
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'Método de Pago',
                  style: AppTheme.titleMd(color: AppColors.onSurface),
                ),
              ],
            ),
            Text(
              'Selección táctil',
              style: AppTheme.labelSm(color: AppColors.outline),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PaymentMethodBtn(
                label: 'Efectivo',
                icon: Icons.attach_money,
                isSelected: _metodoPago == MetodoPago.efectivo,
                onTap: () => setState(() => _metodoPago = MetodoPago.efectivo),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PaymentMethodBtn(
                label: 'Tarjeta',
                icon: Icons.credit_card,
                isSelected: _metodoPago == MetodoPago.tarjeta,
                onTap: () => setState(() => _metodoPago = MetodoPago.tarjeta),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PaymentMethodBtn(
                label: 'QR / Transf.',
                icon: Icons.qr_code_2,
                isSelected: _metodoPago == MetodoPago.qr,
                onTap: () => setState(() => _metodoPago = MetodoPago.qr),
              ),
            ),
          ],
        ),

        // Dynamic Cash Change Calculator Box
        if (_metodoPago == MetodoPago.efectivo) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: quickBills.map((amount) {
                    final isPicked = _selectedQuickBill == amount ||
                        (_pagaCon - amount).abs() < 0.01;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: amount == quickBills.last ? 0 : 6,
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedQuickBill = amount;
                              _tenderCtrl.text = amount.toStringAsFixed(2);
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isPicked
                                  ? AppColors.secondaryContainer
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '\$${amount.toStringAsFixed(0)}',
                              style: AppTheme.labelMd(
                                color: isPicked
                                    ? AppColors.onSecondaryContainer
                                    : AppColors.onSurface,
                                fontWeight:
                                    isPicked ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paga con:',
                              style: AppTheme.labelSm(color: AppColors.outline),
                            ),
                            Row(
                              children: [
                                Text(
                                  '\$',
                                  style: AppTheme.titleMd(
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: TextField(
                                    controller: _tenderCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: (_) => setState(
                                      () => _selectedQuickBill = null,
                                    ),
                                    style: AppTheme.titleMd(
                                      color: AppColors.primary,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppColors.outlineVariant.withOpacity(0.5),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Vuelto:',
                              style: AppTheme.labelSm(color: AppColors.outline),
                            ),
                            Text(
                              _cambio >= 0
                                  ? AppFormatters.money(_cambio)
                                  : 'Faltan ${AppFormatters.money(_cambio.abs())}',
                              style: AppTheme.titleLg(
                                color: _cambio >= 0
                                    ? AppColors.secondary
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Confirmar y Cobrar CTA
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _processing ? null : _confirmarYCobrar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (_processing)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onSecondary,
                        ),
                      )
                    else
                      const Icon(Icons.check_circle_outline, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      _processing ? 'Procesando...' : 'Confirmar y Cobrar',
                      style: AppTheme.titleMd(color: AppColors.onSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      AppFormatters.money(_totalCobrar),
                      style: AppTheme.headlineMd(color: AppColors.onSecondary),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Actualiza stock en tiempo real e imprime recibo digital',
          textAlign: TextAlign.center,
          style: AppTheme.labelSm(color: AppColors.outline),
        ),
      ],
    );
  }
}

class _CartQtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CartQtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Icon(icon, size: 18, color: AppColors.onSurface),
      ),
    );
  }
}

class _PaymentMethodBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodBtn({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppColors.onPrimary
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.labelMd(
                  color: isSelected
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
