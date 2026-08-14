class Product {
  final String itemCode;
  final String itemName;
  final String unit;
  final String category;
  final String premiseCode;
  final String storeName;
  final double price;
  final DateTime date;
  final String imagePath;

  Product({
    required this.itemCode,
    required this.itemName,
    required this.unit,
    required this.category,
    required this.premiseCode,
    required this.storeName,
    required this.price,
    required this.date,
    this.imagePath = 'assets/images/grocery.png',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      itemCode: json['itemCode'],
      itemName: json['itemName'],
      unit: json['unit'],
      category: json['category'],
      premiseCode: json['premiseCode'],
      storeName: json['storeName'],
      price: (json['price'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      imagePath: json['imagePath'] ?? 'assets/images/grocery.png',
    );
  }
}