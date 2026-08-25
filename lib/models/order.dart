import 'cart_item.dart';

class Order {
  final String id;
  final DateTime date;
  final List<CartItem> items;
  final double total;

  Order({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
  });

  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  List<String> get storeNames =>
      items.map((item) => item.storeName).toSet().toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'total': total,
    'items': items
        .map((item) => {
      'itemCode': item.itemCode,
      'itemName': item.itemName,
      'premiseCode': item.premiseCode,
      'storeName': item.storeName,
      'price': item.price,
      'unit': item.unit,
      'category': item.category,
      'quantity': item.quantity,
    })
        .toList(),
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsData = json['items'] as List<dynamic>? ?? [];

    return Order(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      total: (json['total'] as num).toDouble(),
      items: itemsData.map((itemData) {
        final data = itemData as Map<String, dynamic>;
        return CartItem(
          itemCode: data['itemCode'],
          itemName: data['itemName'],
          premiseCode: data['premiseCode'],
          storeName: data['storeName'],
          price: (data['price'] as num).toDouble(),
          unit: data['unit'],
          category: data['category'],
          quantity: data['quantity'] as int,
        );
      }).toList(),
    );
  }
}