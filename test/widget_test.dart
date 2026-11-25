import 'package:flutter_test/flutter_test.dart';

import 'package:app_inventario/models/producto.dart';
import 'package:app_inventario/models/venta.dart';

void main() {
  test('Producto calcula correctamente estados de stock y valor total', () {
    const normal = Producto(
      id: 1,
      nombre: 'Aceite',
      sku: 'ABA-108',
      categoria: 'Abarrotes',
      presentacion: '1L',
      costoCompra: 8.20,
      precioVenta: 12.00,
      stock: 10,
      stockMinimo: 5,
      fechaCreacion: '2026-11-25T00:00:00.000',
    );
    expect(normal.isAgotado, isFalse);
    expect(normal.isStockBajo, isFalse);
    expect(normal.valorTotal, 120.00);

    final bajo = normal.copyWith(stock: 5);
    expect(bajo.isStockBajo, isTrue);
    expect(bajo.isAgotado, isFalse);

    final agotado = normal.copyWith(stock: 0);
    expect(agotado.isAgotado, isTrue);
    expect(agotado.isStockBajo, isFalse);
  });

  test('CartItem calcula subtotal por cantidad', () {
    const prod = Producto(
      id: 2,
      nombre: 'Café Colombiano',
      sku: 'BEB-042',
      categoria: 'Bebidas',
      presentacion: '500g',
      costoCompra: 5.40,
      precioVenta: 8.50,
      stock: 4,
      stockMinimo: 6,
      fechaCreacion: '2026-11-25T00:00:00.000',
    );
    final item = CartItem(producto: prod, cantidad: 3);
    expect(item.subtotal, 25.50);
  });
}
