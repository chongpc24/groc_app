class CartItem {
  final String itemCode;
  final String itemName;
  final String premiseCode;
  final String storeName;
  final double price;
  final String unit;
  final String category;
  int quantity;

  CartItem({
    required this.itemCode,
    required this.itemName,
    required this.premiseCode,
    required this.storeName,
    required this.price,
    required this.unit,
    required this.category,
    required this.quantity,
  });


  double get itemSubtotal => price * quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CartItem &&
              runtimeType == other.runtimeType &&
              itemCode == other.itemCode &&
              premiseCode == other.premiseCode;

  @override
  int get hashCode => itemCode.hashCode ^ premiseCode.hashCode;

  CartItem copyWith({
    String? itemCode,
    String? itemName,
    String? premiseCode,
    String? storeName,
    double? price,
    String? unit,
    String? category,
    int? quantity,
  }) {
    return CartItem(
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      premiseCode: premiseCode ?? this.premiseCode,
      storeName: storeName ?? this.storeName,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
    );
  }
}
