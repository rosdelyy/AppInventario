import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/movimiento_inventario.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../state/inventory_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class HistorialScreen extends StatefulWidget {
  final InventoryStore store;

  const HistorialScreen({super.key, required this.store});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? AppColors.error : AppColors.inverseSurface,
          content: Text(message),
        ),
      );
  }

  Future<void> _openPeriodPicker() async {
    await showModalBottomSheet<void>(
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
                leading: const Icon(Icons.today, color: AppColors.primary),
                title: const Text('Hoy'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.store.actualizarFiltrosHistorial(fecha: DateTime.now());
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: AppColors.primary),
                title: const Text('Elegir una fecha específica'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: widget.store.historialFecha ?? DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) {
                    await widget.store.actualizarFiltrosHistorial(fecha: picked);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.all_inclusive, color: AppColors.primary),
                title: const Text('Todo el historial'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.store.actualizarFiltrosHistorial(limpiarFecha: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openExportReport() async {
    final grupos = widget.store.movimientos;
    final resumen = widget.store.resumen;
    final buffer = StringBuffer()
      ..writeln('REPORTE DE MOVIMIENTOS - MI TIENDA SUCURSAL CENTRO')
      ..writeln(
        'Periodo: ${widget.store.historialFecha != null ? AppFormatters.spanishDate(widget.store.historialFecha!) : "Todo el historial"}',
      )
      ..writeln(
        'Ventas: ${resumen.totalVentasCount} (${AppFormatters.money(resumen.totalVentasMonto)}) | Entradas: +${resumen.totalEntradasUnidades} uds | Mermas: -${resumen.totalMermasUnidades} uds',
      )
      ..writeln('----------------------------------------');

    for (final g in grupos) {
      buffer.writeln(
        '${g.titulo} [${AppFormatters.shortTime(g.fecha)}]${g.montoVenta != null ? " +${AppFormatters.money(g.montoVenta!)}" : ""}',
      );
      for (final item in g.items) {
        final sign = item.cantidad > 0 ? '+' : '';
        buffer.writeln('  - ${item.nombreProducto}: $sign${item.cantidad} u.');
      }
    }

    final text = buffer.toString();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Resumen Exportable',
          style: AppTheme.titleMd(color: AppColors.onSurface),
        ),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              text,
              style: AppTheme.bodySm(color: AppColors.onSurface)
                  .copyWith(fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (ctx.mounted) Navigator.pop(ctx);
              _showToast('Reporte copiado al portapapeles');
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openNuevoAjusteSheet() async {
    final productos = widget.store.productos;
    if (productos.isEmpty) {
      _showToast('No hay productos registrados para ajustar.', isError: true);
      return;
    }

    Producto selectedProd = productos.first;
    TipoMovimiento selectedTipo = TipoMovimiento.entrada;
    final qtyCtrl = TextEditingController(text: '1');
    final refCtrl = TextEditingController(text: 'OC #OC-303');
    final notaCtrl = TextEditingController();

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
                Text(
                  'Nuevo Ajuste de Almacén',
                  style: AppTheme.headlineMd(color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Producto>(
                  value: selectedProd,
                  isExpanded: true,
                  decoration: _modalDecoration('Producto'),
                  items: productos
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.nombre} (Stock: ${p.stock})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (p) {
                    if (p != null) setModalState(() => selectedProd = p);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TipoMovimiento>(
                  value: selectedTipo,
                  decoration: _modalDecoration('Tipo de Movimiento'),
                  items: const [
                    DropdownMenuItem(
                      value: TipoMovimiento.entrada,
                      child: Text('Entrada Proveedor (+)'),
                    ),
                    DropdownMenuItem(
                      value: TipoMovimiento.merma,
                      child: Text('Merma / Daño (-)'),
                    ),
                    DropdownMenuItem(
                      value: TipoMovimiento.ajuste,
                      child: Text('Ajuste Positivo (+)'),
                    ),
                  ],
                  onChanged: (t) {
                    if (t != null) {
                      setModalState(() {
                        selectedTipo = t;
                        if (t == TipoMovimiento.merma) {
                          refCtrl.text = 'Ajuste por Merma';
                        } else if (t == TipoMovimiento.entrada) {
                          refCtrl.text = 'OC #OC-303';
                        } else {
                          refCtrl.text = 'Ajuste Manual';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _modalDecoration('Cantidad (uds)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: refCtrl,
                        decoration: _modalDecoration('Referencia'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notaCtrl,
                  decoration: _modalDecoration('Motivo / Nota (opcional)'),
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
                      final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                      if (qty <= 0) {
                        _showToast('Ingresa una cantidad mayor a 0', isError: true);
                        return;
                      }
                      final delta =
                          selectedTipo == TipoMovimiento.merma ? -qty : qty;

                      try {
                        await widget.store.ajustarStockRapido(
                          producto: selectedProd,
                          delta: delta,
                          tipoExplicito: selectedTipo,
                          referencia: refCtrl.text.trim().isEmpty
                              ? selectedTipo.filterLabel
                              : refCtrl.text.trim(),
                          nota: notaCtrl.text.trim().isEmpty
                              ? null
                              : notaCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showToast('Movimiento registrado en Kardex');
                      } on StockInsuficienteException catch (e) {
                        _showToast(e.toString(), isError: true);
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Registrar Movimiento'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _modalDecoration(String label) {
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

  Future<void> _openSaleDetails(int ventaId) async {
    final data = await widget.store.obtenerComprobante(ventaId);
    if (data == null || !mounted) return;

    final (Venta venta, List<DetalleVenta> detalles) = data;

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
              'Pago: ${MetodoPago.fromDb(venta.metodoPago).label}',
              style: AppTheme.bodySm(color: AppColors.secondary),
            ),
            const Divider(height: 22),
            ...detalles.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${d.cantidad}x ${d.nombreProducto}',
                        style: AppTheme.bodyMd(color: AppColors.onSurface),
                      ),
                    ),
                    Text(
                      AppFormatters.money(d.subtotal),
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
                Text('Total Cobrado', style: AppTheme.titleMd(color: AppColors.primary)),
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

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final resumen = store.resumen;
    final grupos = store.movimientos;

    final dateLabel = store.historialFecha != null
        ? AppFormatters.spanishDate(store.historialFecha!)
        : 'Todo el historial';

    return RefreshIndicator(
      onRefresh: store.cargarTodo,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Selector de Fecha
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: AppColors.outline,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.titleMd(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _openPeriodPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Cambiar',
                      style: AppTheme.labelSm(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3 Tarjetas Metricas: Resumen Operativo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Ventas',
                        style: AppTheme.labelSm(color: AppColors.outline),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: '+${resumen.totalVentasCount} ',
                          style: AppTheme.titleMd(color: AppColors.secondary),
                          children: [
                            TextSpan(
                              text: '(${AppFormatters.money(resumen.totalVentasMonto)})',
                              style: AppTheme.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.surfaceContainer),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Entradas',
                        style: AppTheme.labelSm(color: AppColors.outline),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: '+${resumen.totalEntradasUnidades} ',
                          style: AppTheme.titleMd(color: AppColors.primary),
                          children: [
                            TextSpan(
                              text: 'uds',
                              style: AppTheme.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.surfaceContainer),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Mermas',
                        style: AppTheme.labelSm(color: AppColors.outline),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: '-${resumen.totalMermasUnidades} ',
                          style: AppTheme.titleMd(color: AppColors.error),
                          children: [
                            TextSpan(
                              text: 'uds',
                              style: AppTheme.bodySm(
                                color: AppColors.onSurfaceVariant,
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
          const SizedBox(height: 12),

          // Acciones Primarias: Exportar & Ajuste Rapido
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _openExportReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainer,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: Text(
                      'Exportar Reporte',
                      style: AppTheme.labelMd(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _openNuevoAjusteSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.tune, size: 18),
                    label: Text(
                      'Nuevo Ajuste',
                      style: AppTheme.labelMd(color: AppColors.onPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Header Movimientos de Almacen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Movimientos de Almacén',
                style: AppTheme.titleMd(color: AppColors.onSurface),
              ),
              Text(
                '${grupos.length} registros',
                style: AppTheme.labelSm(color: AppColors.outline),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _HistoryFilterChip(
                  label: 'Todos',
                  count: store.historialTipo == null ? grupos.length : null,
                  isActive: store.historialTipo == null,
                  onTap: () => store.actualizarFiltrosHistorial(limpiarTipo: true),
                ),
                for (final t in TipoMovimiento.values) ...[
                  const SizedBox(width: 8),
                  _HistoryFilterChip(
                    label: t.filterLabel,
                    isActive: store.historialTipo == t,
                    onTap: () => store.actualizarFiltrosHistorial(tipo: t),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Kardex Cards
          if (grupos.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.history_toggle_off,
                    size: 36,
                    color: AppColors.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sin movimientos en este filtro',
                    style: AppTheme.titleMd(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Las ventas, recepciones y ajustes aparecerán aquí automáticamente.',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            ...grupos.map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MovimientoGroupCard(
                  grupo: g,
                  onTapSale:
                      g.ventaId != null ? () => _openSaleDetails(g.ventaId!) : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryFilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool isActive;
  final VoidCallback onTap;

  const _HistoryFilterChip({
    required this.label,
    this.count,
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
          color: isActive ? AppColors.primary : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.labelSm(
                color: isActive ? AppColors.onPrimary : AppColors.onSurface,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: AppTheme.labelSm(color: AppColors.onPrimary)
                      .copyWith(fontSize: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MovimientoGroupCard extends StatelessWidget {
  final MovimientoGrupo grupo;
  final VoidCallback? onTapSale;

  const _MovimientoGroupCard({
    required this.grupo,
    this.onTapSale,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = TipoMovimiento.fromDb(grupo.tipo);

    return InkWell(
      onTap: onTapSale,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          grupo.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.titleMd(color: AppColors.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppFormatters.shortTime(grupo.fecha),
                        style: AppTheme.labelSm(color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (tipo == TipoMovimiento.venta && grupo.montoVenta != null)
                  Text(
                    '+${AppFormatters.money(grupo.montoVenta!)}',
                    style: AppTheme.titleMd(color: AppColors.secondary),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: switch (tipo) {
                        TipoMovimiento.entrada => AppColors.surfaceContainer,
                        TipoMovimiento.merma => AppColors.errorContainer,
                        TipoMovimiento.ajuste => AppColors.tertiaryFixed,
                        TipoMovimiento.venta => AppColors.secondaryContainer,
                      },
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      switch (tipo) {
                        TipoMovimiento.entrada => 'Recepción',
                        TipoMovimiento.merma => 'Merma',
                        TipoMovimiento.ajuste => 'Ajuste',
                        TipoMovimiento.venta => 'Venta',
                      },
                      style: AppTheme.labelSm(
                        color: switch (tipo) {
                          TipoMovimiento.entrada => AppColors.primary,
                          TipoMovimiento.merma => AppColors.error,
                          TipoMovimiento.ajuste => AppColors.tertiary,
                          TipoMovimiento.venta => AppColors.secondary,
                        },
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...grupo.items.map((item) {
              final isPositive = item.cantidad > 0;
              final qtyText =
                  '${isPositive ? "+" : ""}${item.cantidad} u.';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.nombreProducto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySm(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      qtyText,
                      style: AppTheme.bodySm(
                        color: isPositive
                            ? AppColors.secondary
                            : AppColors.error,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
