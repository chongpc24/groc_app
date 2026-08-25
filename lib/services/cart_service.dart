import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart.dart';
import '../models/cart_item.dart';


class StoreInfo {
  final String premiseCode;
  final String storeName;
  final double distance;

  StoreInfo({
    required this.premiseCode,
    required this.storeName,
    required this.distance,
  });
}

class CartService {
  static final CartService _instance = CartService._internal();

  factory CartService() {
    return _instance;
  }

  CartService._internal();

  String _userLocation = 'Klang';
  double _userLatitude = 3.0455;
  double _userLongitude = 101.5247;

  static final Map<String, StoreInfo> storeDistances = {
    'nsk': StoreInfo(
      premiseCode: 'nsk',
      storeName: 'NSK',
      distance: 3.5,
    ),
    'aeon': StoreInfo(
      premiseCode: 'aeon',
      storeName: 'Aeon',
      distance: 7.0,
    ),
    'lotus': StoreInfo(
      premiseCode: 'lotus',
      storeName: 'Lotus',
      distance: 15.0,
    ),
    'giant': StoreInfo(
      premiseCode: 'giant',
      storeName: 'Giant',
      distance: 2.0,
    ),
    'hero': StoreInfo(
      premiseCode: 'hero',
      storeName: 'Hero',
      distance: 8.5,
    ),
    'tesco': StoreInfo(
      premiseCode: 'tesco',
      storeName: 'Tesco',
      distance: 5.0,
    ),
  };

  String get userLocation => _userLocation;

  void setUserLocation(String location) {
    _userLocation = location;
  }

  late Cart _cart;

  Future<void> initialize() async {
    _cart = Cart();
    await _loadCart();
  }

  Cart get cart => _cart;

  double getStoreDistance(String premiseCode) {
    return storeDistances[premiseCode]?.distance ?? 0;
  }

  StoreInfo? getStoreInfo(String premiseCode) {
    final normalizedCode = _normalizeCode(premiseCode);
    return storeDistances[normalizedCode];
  }

  String _normalizeCode(String code) {
    if (code == '136') return 'the_store';
    if (code == '176') return 'lotus';
    if (code == '183') return 'giant';
    if (code == '330') return 'tesco';
    return code;
  }
  void addToCart({
    required String itemCode,
    required String itemName,
    required String premiseCode,
    required String storeName,
    required double price,
    required String unit,
    required String category,
    int quantity = 1,
  }) {
    final distance = getStoreDistance(premiseCode);

    final cartItem = CartItem(
      itemCode: itemCode,
      itemName: itemName,
      premiseCode: premiseCode,
      storeName: storeName,
      price: price,
      unit: unit,
      category: category,
      distance: distance,
      quantity: quantity,
    );

    _cart.addItem(cartItem);
    _saveCart();
  }

  void removeFromCart(String premiseCode, String itemCode) {
    _cart.removeItem(premiseCode, itemCode);
    _saveCart();
  }

  void updateQuantity(String premiseCode, String itemCode, int newQuantity) {
    _cart.updateQuantity(premiseCode, itemCode, newQuantity);
    _saveCart();
  }

  void clearCart() {
    _cart.clear();
    _saveCart();
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();

    final cartData = _cartToJson();
    await prefs.setString('cart_data', jsonEncode(cartData));
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJsonString = prefs.getString('cart_data');

    if (cartJsonString != null) {
      try {
        final cartData = jsonDecode(cartJsonString) as Map<String, dynamic>;
        _cartFromJson(cartData);
      } catch (e) {
        print('Error loading cart: $e');
        _cart = Cart();
      }
    } else {
      _cart = Cart();
    }
  }

  Map<String, dynamic> _cartToJson() {
    final itemsByStore = <String, dynamic>{};

    for (final premiseCode in _cart.storeList) {
      final items = _cart.getStoreItems(premiseCode);
      itemsByStore[premiseCode] = items.map((item) {
        return {
          'itemCode': item.itemCode,
          'itemName': item.itemName,
          'premiseCode': item.premiseCode,
          'storeName': item.storeName,
          'price': item.price,
          'unit': item.unit,
          'category': item.category,
          'distance': item.distance,
          'quantity': item.quantity,
        };
      }).toList();
    }

    return {'itemsByStore': itemsByStore};
  }

  void _cartFromJson(Map<String, dynamic> data) {
    _cart = Cart();

    final itemsByStore = data['itemsByStore'] as Map<String, dynamic>? ?? {};

    for (final entry in itemsByStore.entries) {
      final premiseCode = entry.key;
      final itemsData = entry.value as List<dynamic>;

      for (final itemData in itemsData) {
        final item = CartItem(
          itemCode: itemData['itemCode'],
          itemName: itemData['itemName'],
          premiseCode: itemData['premiseCode'],
          storeName: itemData['storeName'],
          price: (itemData['price'] as num).toDouble(),
          unit: itemData['unit'],
          category: itemData['category'],
          distance: (itemData['distance'] as num).toDouble(),
          quantity: itemData['quantity'],
        );
        _cart.addItem(item);
      }
    }
  }
}
