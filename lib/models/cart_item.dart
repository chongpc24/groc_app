class CartItem {
  final String itemCode;      // 商品代码，例如 "eggs"
  final String itemName;      // 商品名字，例如 "鸡蛋"
  final String premiseCode;   // 店铺代码，例如 "nsk"
  final String storeName;     // 店铺名字，例如 "NSK"
  final double price;         // 价格，例如 6.00
  final String unit;          // 单位，例如 "1kg"
  final String category;      // 类别，例如 "Dairy & Eggs"
  final double distance;      // 店铺距离（公里）
  int quantity;               // 数量（可以改）

  CartItem({
    required this.itemCode,
    required this.itemName,
    required this.premiseCode,
    required this.storeName,
    required this.price,
    required this.unit,
    required this.category,
    required this.distance,
    required this.quantity,
  });

  /// 计算配送费
  double get deliveryFee {
    if (distance <= 3) {
      return 0;      // 免费
    } else if (distance <= 10) {
      return 5;      // RM5
    } else {
      return 10;     // RM10
    }
  }

  /// 这个商品的小计（不含配送费）
  double get itemSubtotal => price * quantity;

  /// 用来判断两个商品是否来自同一店铺
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CartItem &&
              runtimeType == other.runtimeType &&
              itemCode == other.itemCode &&
              premiseCode == other.premiseCode;

  @override
  int get hashCode => itemCode.hashCode ^ premiseCode.hashCode;

  /// 复制并修改某些字段
  CartItem copyWith({
    String? itemCode,
    String? itemName,
    String? premiseCode,
    String? storeName,
    double? price,
    String? unit,
    String? category,
    double? distance,
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
      distance: distance ?? this.distance,
      quantity: quantity ?? this.quantity,
    );
  }
}
