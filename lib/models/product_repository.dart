import 'dart:convert';
import 'package:flutter/services.dart';
import 'product.dart';

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