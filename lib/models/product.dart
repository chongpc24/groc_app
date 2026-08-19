import '../services/database_service.dart';
import '../services/supabase_service.dart';

class Product {
  final String itemCode;
  final String itemName;
  final String unit;
  final String category;
  final String premiseCode;
  final String storeName;
  final double price;
  final DateTime date;

  Product({
    required this.itemCode,
    required this.itemName,
    required this.unit,
    required this.category,
    required this.premiseCode,
    required this.storeName,
    required this.price,
    required this.date,
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
    );
  }
}

class ProductRepository {
  static Future<int> sync() => SupabaseService.syncFromSupabase();

  static Future<bool> hasLocalData() async =>
      (await DatabaseService().rowCount()) > 0;

  static Future<List<String>> getCategories() =>
      DatabaseService().getCategories();

  static Future<List<Product>> byCategory(String category) async {
    final rows = await DatabaseService().getByCategory(category);
    return rows.map((r) => Product.fromJson(r)).toList();
  }

  static Future<List<Product>> search(String query, {String? category}) async {
    final rows = await DatabaseService().search(query, category: category);
    return rows.map((r) => Product.fromJson(r)).toList();
  }

  static Future<List<Product>> byItemCode(String itemCode) async {
    final rows = await DatabaseService().getByItemCode(itemCode);
    return rows.map((r) => Product.fromJson(r)).toList();
  }

  static Future<List<Product>> loadAll() async {
    final rows = await DatabaseService().getAll();
    return rows.map((r) => Product.fromJson(r)).toList();
  }
}