import 'package:flutter_test/flutter_test.dart';
import 'package:merchbox_flutter/models.dart';

void main() {
  test('Product parses API numeric and boolean values', () {
    final product = Product.fromJson({
      'id': 42,
      'name': 'Acrylic charm',
      'description': 'Custom item',
      'category': 'Gantungan Kunci',
      'price': '12000',
      'stock': 7,
      'imageUrl': '',
      'isPublished': 1,
    });

    expect(product.id, 42);
    expect(product.price, 12000);
    expect(product.stock, 7);
    expect(product.imageUrl, isNull);
    expect(product.isPublished, isTrue);
    expect(product.toJson()['isPublished'], isTrue);
  });

  test('Cart item accepts numeric strings from API', () {
    final item = CartItem.fromJson({
      'productId': '6',
      'quantity': '2',
      'name': 'Pin',
      'price': '8000',
      'stock': 4,
    });

    expect(item.productId, 6);
    expect(item.quantity, 2);
    expect(item.price, 8000);
  });
}
