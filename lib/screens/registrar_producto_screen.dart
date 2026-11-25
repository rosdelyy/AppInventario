import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/producto.dart';
import '../state/inventory_store.dart';
import '../theme/app_theme.dart';

class RegistrarProductoScreen extends StatefulWidget {
  final InventoryStore store;
  final VoidCallback onSavedGoInventory;

  const RegistrarProductoScreen({
    super.key,
    required this.store,
    required this.onSavedGoInventory,
  });

  @override
  State<RegistrarProductoScreen> createState() =>
      _RegistrarProductoScreenState();
}

class _RegistrarProductoScreenState extends State<RegistrarProductoScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _skuCtrl = TextEditingController();
  final TextEditingController _presentacionCtrl =
      TextEditingController(text: '1 pz');
  final TextEditingController _costCtrl = TextEditingController(text: '0.00');
  final TextEditingController _priceCtrl = TextEditingController(text: '0.00');
  final TextEditingController _stockCtrl = TextEditingController(text: '10');
  final TextEditingController _minStockCtrl = TextEditingController(text: '5');

  String _selectedCategory = CategoriasCatalogo.todas.first;
  bool _alertaReposicion = true;
  String? _imagePath;
  bool _saving = false;
  bool _showSuccessBanner = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _presentacionCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  int get _stockMinimo => int.tryParse(_minStockCtrl.text.trim()) ?? 5;

  void _stepStock(TextEditingController ctrl, int delta, {int min = 0}) {
    final current = int.tryParse(ctrl.text.trim()) ?? min;
    final next = (current + delta).clamp(min, 99999);
    setState(() {
      ctrl.text = '$next';
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _imagePath = picked.path);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo acceder a la cámara o galería.'),
        ),
      );
    }
  }

  void _showPhotoPickerOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.primary),
                title: const Text('Tomar fotografía'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Seleccionar de la galería'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarProducto() async {
    final nombre = _nameCtrl.text.trim();
    final costo = double.tryParse(_costCtrl.text.trim()) ?? 0.0;
    final precio = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    final stockMin = (int.tryParse(_minStockCtrl.text.trim()) ?? 1).clamp(1, 9999);

    if (nombre.isEmpty) {
      _showError('Ingresa el nombre comercial del producto.');
      return;
    }
    if (precio <= 0) {
      _showError('Ingresa un precio de venta mayor a \$0.00.');
      return;
    }
    if (stock < 0) {
      _showError('El stock inicial no puede ser negativo.');
      return;
    }

    setState(() => _saving = true);
    try {
      final nuevo = Producto(
        nombre: nombre,
        sku: _skuCtrl.text.trim(),
        categoria: _selectedCategory,
        presentacion: _presentacionCtrl.text.trim().isEmpty
            ? '1 pz'
            : _presentacionCtrl.text.trim(),
        costoCompra: costo < 0 ? 0 : costo,
        precioVenta: precio,
        stock: stock,
        stockMinimo: stockMin,
        alertaReposicion: _alertaReposicion,
        imagenPath: _imagePath,
        fechaCreacion: DateTime.now().toIso8601String(),
      );

      await widget.store.registrarProducto(nuevo);

      if (!mounted) return;
      setState(() {
        _showSuccessBanner = true;
        _nameCtrl.clear();
        _skuCtrl.clear();
        _presentacionCtrl.text = '1 pz';
        _costCtrl.text = '0.00';
        _priceCtrl.text = '0.00';
        _stockCtrl.text = '10';
        _minStockCtrl.text = '5';
        _imagePath = null;
      });
    } catch (e) {
      _showError('No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(msg),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Top Visual & Header Context
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_circle_outline,
                size: 18,
                color: AppColors.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ALTA RÁPIDA DE INVENTARIO',
              style: AppTheme.labelMd(color: AppColors.secondary)
                  .copyWith(letterSpacing: 0.8),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Nuevo Producto en Catálogo',
          style: AppTheme.headlineLg(color: AppColors.onSurface),
        ),
        const SizedBox(height: 2),
        Text(
          'Ingresa los datos para control de stock y precio de venta.',
          style: AppTheme.bodyMd(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),

        // SECCIÓN 1: DATOS GENERALES
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '1. Datos Generales',
                        style: AppTheme.titleMd(color: AppColors.onSurface),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Requerido',
                      style: AppTheme.labelSm(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Fotografia del producto
              Text(
                'Fotografía del Producto',
                style: AppTheme.labelMd(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _showPhotoPickerOptions,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imagePath == null
                      ? Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.photo_camera_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Añadir foto del producto',
                                    style: AppTheme.titleMd(
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Toca para seleccionar o capturar',
                                    style: AppTheme.bodySm(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_imagePath!),
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _imagePath!.split(Platform.pathSeparator).last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.bodySm(
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => setState(() => _imagePath = null),
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.error,
                              ),
                              label: Text(
                                'Quitar',
                                style: AppTheme.labelSm(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // Nombre Comercial *
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Nombre Comercial ',
                      style: AppTheme.labelMd(color: AppColors.onSurfaceVariant),
                      children: const [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Máx 60 car.',
                    style: AppTheme.labelSm(color: AppColors.outline),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _nameCtrl,
                  maxLength: 60,
                  style: AppTheme.bodyLg(color: AppColors.onSurface),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Ej. Galletas de Avena con Miel 200g',
                    hintStyle: AppTheme.bodyMd(color: AppColors.outline),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Categoría
              Text(
                'Categoría',
                style: AppTheme.labelMd(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.expand_more,
                      color: AppColors.onSurfaceVariant,
                    ),
                    items: CategoriasCatalogo.todas.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              size: 20,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              cat,
                              style: AppTheme.bodyLg(color: AppColors.onSurface),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // SKU y Presentación compactos
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SKU / Código (opcional)',
                          style: AppTheme.labelMd(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _skuCtrl,
                            textCapitalization: TextCapitalization.characters,
                            style: AppTheme.bodyMd(color: AppColors.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Auto (ej. SNK-101)',
                              hintStyle: AppTheme.bodySm(color: AppColors.outline),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Presentación',
                          style: AppTheme.labelMd(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _presentacionCtrl,
                            style: AppTheme.bodyMd(color: AppColors.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Ej. 200g, 1L',
                              hintStyle: AppTheme.bodySm(color: AppColors.outline),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // SECCIÓN 2: PRECIOS Y RENTABILIDAD
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '2. Precios y Rentabilidad',
                    style: AppTheme.titleMd(color: AppColors.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Costo Compra',
                          style: AppTheme.labelMd(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '\$',
                                style: AppTheme.titleLg(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextField(
                                  controller: _costCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  style: AppTheme.titleMd(
                                    color: AppColors.onSurface,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Por pieza / prov.',
                          style: AppTheme.bodySm(color: AppColors.outline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Precio Venta (PVP)',
                          style: AppTheme.labelMd(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '\$',
                                style: AppTheme.titleLg(
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextField(
                                  controller: _priceCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  style: AppTheme.headlineMd(
                                    color: AppColors.onSurface,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mostrador',
                          style: AppTheme.bodySm(color: AppColors.secondary)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // SECCIÓN 3: EXISTENCIAS Y ALERTAS
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warehouse_outlined,
                        color: AppColors.tertiaryContainer,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '3. Existencias y Alertas',
                        style: AppTheme.titleMd(color: AppColors.onSurface),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Almacén',
                      style: AppTheme.labelSm(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StepperFormField(
                      label: 'Stock Inicial',
                      helper: 'Piezas recibidas',
                      controller: _stockCtrl,
                      onDecrement: () => _stepStock(_stockCtrl, -1, min: 0),
                      onIncrement: () => _stepStock(_stockCtrl, 1, min: 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StepperFormField(
                      label: 'Stock Mínimo',
                      helper: 'Dispara aviso',
                      controller: _minStockCtrl,
                      onDecrement: () => _stepStock(_minStockCtrl, -1, min: 1),
                      onIncrement: () => _stepStock(_minStockCtrl, 1, min: 1),
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alerta de reposición',
                            style: AppTheme.titleMd(color: AppColors.onSurface),
                          ),
                          Text(
                            'Notificar cuando baje de $_stockMinimo unidades',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodySm(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _alertaReposicion,
                      activeColor: AppColors.onPrimary,
                      activeTrackColor: AppColors.primary,
                      onChanged: (v) => setState(() => _alertaReposicion = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Feedback Toast Banner
        if (_showSuccessBanner) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.inverseSurface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.task_alt,
                  color: AppColors.secondaryFixed,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Producto Guardado!',
                        style: AppTheme.titleMd(
                          color: AppColors.inverseOnSurface,
                        ),
                      ),
                      Text(
                        'Añadido al inventario de Sucursal Centro',
                        style: AppTheme.bodySm(
                          color: AppColors.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _showSuccessBanner = false);
                    widget.onSavedGoInventory();
                  },
                  child: Text(
                    'Ver',
                    style: AppTheme.labelMd(color: AppColors.secondaryFixed),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _showSuccessBanner = false),
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.inverseOnSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Primary CTA: Guardar Producto
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _guardarProducto,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Icon(Icons.check, size: 22),
            label: Text(
              _saving ? 'Guardando...' : 'Guardar Producto',
              style: AppTheme.labelLg(color: AppColors.onPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );
  }
}

class _StepperFormField extends StatelessWidget {
  final String label;
  final String helper;
  final TextEditingController controller;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback? onChanged;

  const _StepperFormField({
    required this.label,
    required this.helper,
    required this.controller,
    required this.onDecrement,
    required this.onIncrement,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelMd(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _MiniBtn(icon: Icons.remove, onTap: onDecrement),
              Expanded(
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged?.call(),
                  style: AppTheme.titleLg(color: AppColors.onSurface),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              _MiniBtn(icon: Icons.add, onTap: onIncrement),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helper,
          style: AppTheme.bodySm(color: AppColors.outline),
        ),
      ],
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 18, color: AppColors.onSurface),
        ),
      ),
    );
  }
}
