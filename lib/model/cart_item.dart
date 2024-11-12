// cart_item.dart
class CartItem {
  final String id; // Unique identifier (ISBN)
  final String title;
  final String imageUrl;
  final String price;
  final int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });
}
