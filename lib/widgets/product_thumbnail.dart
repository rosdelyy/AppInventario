import 'dart:io';

import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../theme/app_theme.dart';

class ProductThumbnail extends StatelessWidget {
  final Producto producto;
  final double size;

  const ProductThumbnail({
    super.key,
    required this.producto,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final isAgotado = producto.isAgotado;

    Widget content;
    if (producto.imagenPath != null &&
        producto.imagenPath!.isNotEmpty &&
        File(producto.imagenPath!).existsSync()) {
      content = Image.file(
        File(producto.imagenPath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else {
      content = _CategoryVisual(categoria: producto.categoria, size: size);
    }

    if (isAgotado) {
      content = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 0.75, 0,
        ]),
        child: content,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.surfaceContainer, child: content),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.inverseSurface.withOpacity(0.82),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  producto.presentacion,
                  style: AppTheme.labelSm(color: AppColors.inverseOnSurface)
                      .copyWith(fontSize: 10, height: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryVisual extends StatelessWidget {
  final String categoria;
  final double size;

  const _CategoryVisual({required this.categoria, required this.size});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color bg, Color fg) = switch (categoria.toLowerCase()) {
      final c when c.contains('bebida') => (
          Icons.local_cafe_rounded,
          const Color(0xFFEFE6DD),
          const Color(0xFF5D4037),
        ),
      final c when c.contains('lácteo') || c.contains('lacteo') => (
          Icons.egg_alt_rounded,
          const Color(0xFFE8EEF5),
          const Color(0xFF334155),
        ),
      final c when c.contains('limpieza') => (
          Icons.cleaning_services_rounded,
          const Color(0xFFE0F2FE),
          const Color(0xFF0369A1),
        ),
      final c when c.contains('snack') || c.contains('golosina') => (
          Icons.cookie_rounded,
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
        ),
      final c when c.contains('abarrote') => (
          Icons.shopping_basket_rounded,
          const Color(0xFFECFDF5),
          const Color(0xFF047857),
        ),
      _ => (
          Icons.inventory_2_rounded,
          AppColors.surfaceContainer,
          AppColors.primary,
        ),
    };

    return Container(
      width: size,
      height: size,
      color: bg,
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.44, color: fg),
    );
  }
}
