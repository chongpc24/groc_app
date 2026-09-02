class ShoppingListSummary {
  final String id;
  final String userId;
  final String name;
  final int itemCount;
  final double estimatedTotal;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShoppingListSummary({
    required this.id,
    required this.userId,
    required this.name,
    required this.itemCount,
    required this.estimatedTotal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingListSummary.fromMap(Map<String, dynamic> map) {
    return ShoppingListSummary(
      id: map['id'].toString(),
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Shopping List',
      itemCount: (map['item_count'] as num?)?.toInt() ?? 0,
      estimatedTotal: (map['estimated_total'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ShoppingListItemModel {
  final String id;
  final String listId;
  final String itemCode;
  final String itemName;
  final String premiseCode;
  final String storeName;
  final double price;
  final String unit;
  final String category;
  final int quantity;

  const ShoppingListItemModel({
    required this.id,
    required this.listId,
    required this.itemCode,
    required this.itemName,
    required this.premiseCode,
    required this.storeName,
    required this.price,
    required this.unit,
    required this.category,
    required this.quantity,
  });

  double get lineTotal => price * quantity;

  factory ShoppingListItemModel.fromMap(Map<String, dynamic> map) {
    return ShoppingListItemModel(
      id: map['id'].toString(),
      listId: map['list_id'].toString(),
      itemCode: map['item_code']?.toString() ?? '',
      itemName: map['item_name']?.toString() ?? '',
      premiseCode: map['premise_code']?.toString() ?? '',
      storeName: map['store_name']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      unit: map['unit']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
