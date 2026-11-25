import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/movimiento_inventario.dart';
import '../models/producto.dart';
import '../state/inventory_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/product_thumbnail.dart';

enum _InventoryFilter {
  todos,
  stockBajo,
  agotados,
  categoria,
}

enum _InventorySort {
  recientes('Recientes'),
  nombreAsc('Nombre A-Z'),
  menorStock('Menor Stock'),
  mayorPrecio('Mayor Precio');

  final String label;
  const _InventorySort(this.label);
}

class InventarioScreen extends StatefulWidget {
  final InventoryStore store;
  final VoidCallback onGoToRegister;

  const InventarioScreen({
    super.key,
    required this.store,
    required this.onGoToRegister,
  });

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _InventoryFilter _activeFilter = _InventoryFilter.todos;
  String? _selectedCategory;
  _InventorySort _sortMode = _InventorySort.recientes;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Producto> _filteredProducts() {
    final q = _searchQuery.trim().toLowerCase();
    var list = widget.store.productos.where((p) {
      final matchesSearch = q.isEmpty ||
          p.nombre.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.categoria.toLowerCase().contains(q);
      if (!matchesSearch) return false;

      return switch (_activeFilter) {
        _InventoryFilter.todos => true,
        _InventoryFilter.stockBajo => p.isStockBajo,
        _InventoryFilter.agotados => p.isAgotado,
        _InventoryFilter.categoria =>
          _selectedCategory == null || p.categoria == _selectedCategory,
      };
    }).toList();

    switch (_sortMode) {
      case _InventorySort.recientes:
        list.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      case _InventorySort.nombreAsc:
        list.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      case _InventorySort.menorStock:
        list.sort((a, b) => a.stock.compareTo(b.stock));
      case _InventorySort.mayorPrecio:
        list.sort((a, b) => b.precioVenta.compareTo(a.precioVenta));
    }

    return list;
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? AppColors.error : AppColors.inverseSurface,
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle,
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

  Future<void> _adjustStock(Producto p, int delta) async {
    try {
      await widget.store.ajustarStockRapido(producto: p, delta: delta);
      final nuevo = p.stock + delta;
      _showToast(
        delta > 0
            ? 'Stock aumentado a $nuevo u.'
            : 'Stock reducido a $nuevo u.',
      );
    } on StockInsuficienteException catch (e) {
      _showToast(e.toString(), isError: true);
    } catch (e) {
      _showToast('Error al actualizar stock: $e', isError: true);
    }
  }

  void _cycleSort() {
    const values = _InventorySort.values;
    final next = values[(_sortMode.index + 1) % values.length];
    setState(() => _sortMode = next);
    _showToast('Ordenado por: ${next.label}');
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final visibleProducts = _filteredProducts();

    if (store.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: store.cargarTodo,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Top Quick Stats Hero Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VALOR EN ALMACÉN',
                          style: AppTheme.labelSm(
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.money(store.valorTotalAlmacen),
                          style: AppTheme.headlineLg(color: AppColors.onPrimary),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'SKUS',
                            style: AppTheme.labelSm(
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            '${store.totalSkus}',
                            style: AppTheme.titleLg(color: AppColors.onPrimary),
                          ),
                        ],
                      ),
                      Container(
                        height: 32,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: AppColors.onPrimary.withOpacity(0.2),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            _activeFilter = _InventoryFilter.stockBajo;
                            _selectedCategory = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.tertiaryFixedDim,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${store.totalStockBajo} bajos',
                                style: AppTheme.labelSm(
                                  color: AppColors.tertiaryFixed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: AppTheme.bodyMd(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o SKU...',
                  hintStyle: AppTheme.bodyMd(color: AppColors.outline),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.onSurfaceVariant,
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
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

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _FilterChipPill(
                  label: 'Todos',
                  count: store.totalSkus,
                  isActive: _activeFilter == _InventoryFilter.todos,
                  onTap: () => setState(() {
                    _activeFilter = _InventoryFilter.todos;
                    _selectedCategory = null;
                  }),
                ),
                const SizedBox(width: 8),
                _FilterChipPill(
                  label: 'Stock Bajo',
                  dotColor: AppColors.tertiaryFixedDim,
                  count: store.totalStockBajo,
                  countBg: AppColors.tertiaryFixed.withOpacity(0.5),
                  countFg: AppColors.tertiary,
                  isActive: _activeFilter == _InventoryFilter.stockBajo,
                  onTap: () => setState(() {
                    _activeFilter = _InventoryFilter.stockBajo;
                    _selectedCategory = null;
                  }),
                ),
                const SizedBox(width: 8),
                _FilterChipPill(
                  label: 'Agotados',
                  dotColor: AppColors.error,
                  count: store.totalAgotados,
                  countBg: AppColors.errorContainer,
                  countFg: AppColors.onErrorContainer,
                  isActive: _activeFilter == _InventoryFilter.agotados,
                  onTap: () => setState(() {
                    _activeFilter = _InventoryFilter.agotados;
                    _selectedCategory = null;
                  }),
                ),
                for (final cat in ['Bebidas', 'Abarrotes', 'Lácteos', 'Limpieza', 'Snacks y Botanas']) ...[
                  const SizedBox(width: 8),
                  _FilterChipPill(
                    label: cat,
                    isActive: _activeFilter == _InventoryFilter.categoria &&
                        _selectedCategory == cat,
                    onTap: () => setState(() {
                      _activeFilter = _InventoryFilter.categoria;
                      _selectedCategory = cat;
                    }),
                  ),
                ],
              ],
            ),
          ),

          // Catalog Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Catálogo de Almacén',
                      style: AppTheme.titleMd(color: AppColors.onSurface),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${visibleProducts.length} visibles',
                        style: AppTheme.labelSm(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _cycleSort,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.swap_vert,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _sortMode == _InventorySort.recientes
                              ? 'Ordenar'
                              : _sortMode.label,
                          style: AppTheme.labelSm(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Empty state or Product Cards
          if (visibleProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 42,
                      color: AppColors.outline,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sin productos en esta vista',
                      style: AppTheme.titleMd(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cambia el filtro o registra un nuevo producto en el catálogo.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: widget.onGoToRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Registrar Producto'),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: visibleProducts
                    .map(
                      (producto) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProductInventoryCard(
                          producto: producto,
                          onEdit: () => _openEditSheet(producto),
                          onIncrement: () => _adjustStock(producto, 1),
                          onDecrement: () => _adjustStock(producto, -1),
                          onRestock: () => _openRestockDialog(producto),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openRestockDialog(Producto producto) async {
    final qtyController = TextEditingController(text: '12');
    final refController = TextEditingController(text: 'Pedido Proveedor');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reabastecer "${producto.nombre}"',
          style: AppTheme.titleMd(color: AppColors.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Unidades recibidas',
                filled: true,
                fillColor: AppColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: refController,
              decoration: InputDecoration(
                labelText: 'Referencia / Orden de Compra',
                filled: true,
                fillColor: AppColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Registrar Entrada'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final qty = int.tryParse(qtyController.text.trim()) ?? 0;
      if (qty <= 0) {
        _showToast('Ingresa una cantidad mayor a 0', isError: true);
        return;
      }
      await widget.store.ajustarStockRapido(
        producto: producto,
        delta: qty,
        tipoExplicito: TipoMovimiento.entrada,
        referencia: refController.text.trim().isEmpty
            ? 'Pedido Proveedor'
            : refController.text.trim(),
        nota: 'Reposición desde agotado',
      );
      _showToast('+$qty u. añadidas a ${producto.nombre}');
    }
  }

  Future<void> _openEditSheet(Producto producto) async {
    final nameCtrl = TextEditingController(text: producto.nombre);
    final skuCtrl = TextEditingController(text: producto.sku);
    final presCtrl = TextEditingController(text: producto.presentacion);
    final costCtrl =
        TextEditingController(text: producto.costoCompra.toStringAsFixed(2));
    final priceCtrl =
        TextEditingController(text: producto.precioVenta.toStringAsFixed(2));
    final stockCtrl = TextEditingController(text: '${producto.stock}');
    final minCtrl = TextEditingController(text: '${producto.stockMinimo}');
    var categoria = CategoriasCatalogo.todas.contains(producto.categoria)
        ? producto.categoria
        : CategoriasCatalogo.todas.first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
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
                      'Editar Producto',
                      style: AppTheme.headlineMd(color: AppColors.onSurface),
                    ),
                    IconButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await widget.store.eliminarProducto(producto.id!);
                        _showToast('Producto eliminado del catálogo');
                      },
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      tooltip: 'Eliminar producto',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: _modalInputDecoration('Nombre Comercial'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: skuCtrl,
                        decoration: _modalInputDecoration('SKU'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: presCtrl,
                        decoration: _modalInputDecoration('Presentación'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: categoria,
                  decoration: _modalInputDecoration('Categoría'),
                  items: CategoriasCatalogo.todas
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => categoria = v);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _modalInputDecoration('Costo Compra (\$)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _modalInputDecoration('Precio Venta (\$)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _modalInputDecoration('Stock Actual'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: minCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _modalInputDecoration('Stock Mínimo'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final nombre = nameCtrl.text.trim();
                      final precio = double.tryParse(priceCtrl.text.trim()) ?? -1;
                      final costo = double.tryParse(costCtrl.text.trim()) ?? 0;
                      final stock = int.tryParse(stockCtrl.text.trim()) ?? -1;
                      final minStock = int.tryParse(minCtrl.text.trim()) ?? 1;

                      if (nombre.isEmpty || precio <= 0 || stock < 0) {
                        _showToast('Verifica nombre, precio y stock válidos', isError: true);
                        return;
                      }

                      await widget.store.actualizarProducto(
                        producto.copyWith(
                          nombre: nombre,
                          sku: skuCtrl.text.trim().isEmpty
                              ? producto.sku
                              : skuCtrl.text.trim().toUpperCase(),
                          presentacion: presCtrl.text.trim().isEmpty
                              ? '1 pz'
                              : presCtrl.text.trim(),
                          categoria: categoria,
                          costoCompra: costo,
                          precioVenta: precio,
                          stock: stock,
                          stockMinimo: minStock < 1 ? 1 : minStock,
                        ),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _showToast('Producto actualizado');
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Guardar Cambios'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _modalInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final int? count;
  final Color? dotColor;
  final Color? countBg;
  final Color? countFg;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    this.count,
    this.dotColor,
    this.countBg,
    this.countFg,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(999),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTheme.labelMd(
                color: isActive
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.onPrimary.withOpacity(0.2)
                      : (countBg ?? AppColors.surfaceContainer),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: AppTheme.labelSm(
                    color: isActive
                        ? AppColors.onPrimary
                        : (countFg ?? AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductInventoryCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onEdit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRestock;

  const _ProductInventoryCard({
    required this.producto,
    required this.onEdit,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRestock,
  });

  @override
  Widget build(BuildContext context) {
    final Color badgeBg;
    final Color badgeFg;
    final String badgeText;

    if (producto.isAgotado) {
      badgeBg = AppColors.errorContainer;
      badgeFg = AppColors.onErrorContainer;
      badgeText = 'Agotado';
    } else if (producto.isStockBajo) {
      badgeBg = AppColors.tertiaryFixed;
      badgeFg = AppColors.tertiary;
      badgeText = 'Bajo: ${producto.stock} u.';
    } else {
      badgeBg = AppColors.secondaryFixed;
      badgeFg = AppColors.onSecondaryFixed;
      badgeText = '${producto.stock} u.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              ProductThumbnail(producto: producto, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            producto.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.titleMd(color: AppColors.onSurface),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badgeText,
                            style: AppTheme.labelSm(color: badgeFg),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppFormatters.money(producto.precioVenta),
                          style: AppTheme.titleLg(
                            color: producto.isAgotado
                                ? AppColors.error
                                : AppColors.onSurface,
                          ),
                        ),
                        Text(
                          producto.sku,
                          style: AppTheme.labelSm(color: AppColors.outline)
                              .copyWith(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.surfaceContainerLow, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit,
                          size: 18,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Editar',
                          style: AppTheme.labelSm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (producto.isAgotado)
                  ElevatedButton.icon(
                    onPressed: onRestock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.onError,
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.shopping_cart, size: 16),
                    label: Text(
                      'Pedir',
                      style: AppTheme.labelSm(color: AppColors.onError),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _StepperIconBtn(
                          icon: Icons.remove,
                          bgColor: Colors.transparent,
                          fgColor: AppColors.onSurface,
                          onTap: onDecrement,
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 32),
                          child: Text(
                            '${producto.stock}',
                            textAlign: TextAlign.center,
                            style: AppTheme.titleMd(color: AppColors.onSurface)
                                .copyWith(fontFamily: 'monospace'),
                          ),
                        ),
                        _StepperIconBtn(
                          icon: Icons.add,
                          bgColor: AppColors.primary,
                          fgColor: AppColors.onPrimary,
                          onTap: onIncrement,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperIconBtn extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback onTap;

  const _StepperIconBtn({
    required this.icon,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 16, color: fgColor),
        ),
      ),
    );
  }
}
