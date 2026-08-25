import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class CartService {
  static final CartService _instance = CartService._internal();

  factory CartService() {
    return _instance;
  }

  CartService._internal();

  // Store names mapping (full names)
  static const Map<String, String> storeNames = {
    'nsk': 'Noonan Supermarket Klang',
    'aeon': 'AEON Big Klang',
    'lotus': 'Lotus\'s Klang',
    'giant': 'Giant Hypermarket Klang',
    'hero': 'Hero Market Klang',
    'tesco': 'Tesco Klang',
  };

  String _userLocation = 'Klang';

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

  /// Get the full store name
  String? getStoreName(String premiseCode) {
    return storeNames[premiseCode];
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
    final cartItem = CartItem(
      itemCode: itemCode,
      itemName: itemName,
      premiseCode: premiseCode,
      storeName: storeName,
      price: price,
      unit: unit,
      category: category,
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

  /// Snapshots the current cart contents as a completed [Order] and saves
  /// it to the locally persisted order history (most recent first).
  Future<void> saveOrderToHistory() async {
    final items = _cart
        .getAllItems()
        .map((item) => item.copyWith())
        .toList();

    if (items.isEmpty) return;

    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      items: items,
      total: _cart.getGrandTotal(),
    );

    final prefs = await SharedPreferences.getInstance();
    final historyJsonString = prefs.getString('order_history');

    List<dynamic> historyList = [];
    if (historyJsonString != null) {
      try {
        historyList = jsonDecode(historyJsonString) as List<dynamic>;
      } catch (e) {
        historyList = [];
      }
    }

    historyList.insert(0, order.toJson());
    await prefs.setString('order_history', jsonEncode(historyList));
  }

  Future<List<Order>> getOrderHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJsonString = prefs.getString('order_history');

    if (historyJsonString == null) return [];

    try {
      final historyList = jsonDecode(historyJsonString) as List<dynamic>;
      return historyList
          .map((data) => Order.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading order history: $e');
      return [];
    }
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
          quantity: itemData['quantity'],
        );
        _cart.addItem(item);
      }
    }
  }
}