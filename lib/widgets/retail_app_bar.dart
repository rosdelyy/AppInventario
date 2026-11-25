import 'package:flutter/material.dart';

import '../state/inventory_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class RetailAppBar extends StatelessWidget {
  final String title;
  final InventoryStore store;

  const RetailAppBar({
    super.key,
    required this.title,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Logo de tienda
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mi Tienda - Sucursal Centro',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.labelSm(color: AppColors.secondary),
                      ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.titleMd(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _mostrarEstadoCaja(context),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.point_of_sale,
                      size: 22,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'MT',
                    style: AppTheme.labelSm(color: AppColors.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarEstadoCaja(BuildContext context) async {
    final resumen = await store.obtenerResumenCajaHoy();
    if (!context.mounted) return;

    final ventasCount = resumen['ventasCount'] as int;
    final totalDia = resumen['totalDia'] as double;
    final efectivo = resumen['efectivo'] as double;
    final tarjeta = resumen['tarjeta'] as double;
    final qr = resumen['qr'] as double;

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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.point_of_sale,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de Caja — Hoy',
                      style: AppTheme.titleMd(color: AppColors.onSurface),
                    ),
                    Text(
                      '$ventasCount ventas registradas',
                      style: AppTheme.bodySm(color: AppColors.outline),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL RECAUDADO',
                    style: AppTheme.labelSm(color: AppColors.onPrimaryContainer),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.money(totalDia),
                    style: AppTheme.displayLgMobile(color: AppColors.onPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _CajaRow(label: 'Efectivo', amount: efectivo, icon: Icons.attach_money),
            _CajaRow(label: 'Tarjeta', amount: tarjeta, icon: Icons.credit_card),
            _CajaRow(label: 'QR / Transferencia', amount: qr, icon: Icons.qr_code_2),
          ],
        ),
      ),
    );
  }
}

class _CajaRow extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;

  const _CajaRow({
    required this.label,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodyMd(color: AppColors.onSurface),
            ),
          ),
          Text(
            AppFormatters.money(amount),
            style: AppTheme.titleMd(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}
