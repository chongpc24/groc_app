import 'dart:convert';
import 'package:flutter/services.dart';

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
  static List<Product>? _cache;

  static Future<List<Product>> loadAll() async {
    if (_cache != null) return _cache!;

    final jsonString = await rootBundle.loadString('assets/data/products.json');
    final List<dynamic> jsonList = json.decode(jsonString);

    _cache = jsonList.map((item) => Product.fromJson(item)).toList();
    return _cache!;
  }
}