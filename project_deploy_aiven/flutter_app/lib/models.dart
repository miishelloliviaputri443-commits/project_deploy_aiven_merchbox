class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final int id;
  final String name;
  final String email;
  final String role;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: _asInt(json['id']),
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? 'customer',
      );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    required this.isPublished,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String description;
  final String category;
  final int price;
  final int stock;
  final String? imageUrl;
  final bool isPublished;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: _asInt(json['id']),
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Gantungan Kunci',
        price: _asInt(json['price']),
        stock: _asInt(json['stock']),
        imageUrl: _optionalString(json['imageUrl']),
        isPublished: _asBool(json['isPublished']),
      );

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'description': description.trim(),
        'category': category,
        'price': price,
        'stock': stock,
        'imageUrl': imageUrl?.trim() ?? '',
        'isPublished': isPublished,
      };
}

class CartItem {
  const CartItem({
    required this.productId,
    required this.quantity,
    required this.name,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  final int productId;
  final int quantity;
  final String name;
  final int price;
  final int stock;
  final String? imageUrl;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: _asInt(json['productId']),
        quantity: _asInt(json['quantity']),
        name: json['name']?.toString() ?? '',
        price: _asInt(json['price']),
        stock: _asInt(json['stock']),
        imageUrl: _optionalString(json['imageUrl']),
      );
}

class ProductRequest {
  const ProductRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.productName,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final String productName;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  factory ProductRequest.fromJson(Map<String, dynamic> json) =>
      ProductRequest(
        id: _asInt(json['id']),
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        productName: json['productName']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        isRead: _asBool(json['isRead']),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

int _asInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString() == '1' || value?.toString().toLowerCase() == 'true';
}

String? _optionalString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
