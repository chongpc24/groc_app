import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import 'database_service.dart';

class CartService {
  static final CartService _instance = CartService._internal();

  factory CartService() {
    return _instance;
  }

  CartService._internal();

  final DatabaseService _dbService = DatabaseService();

  String _userLocation = 'Klang';
  Cart _cart = Cart();

  String get userLocation => _userLocation;

  Cart get cart => _cart;

  void setUserLocation(String location) {
    _userLocation = location;
  }

  Future<void> initialize() async {
    await _loadCartFromLocalDatabase();
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
    _saveCartToLocalDatabase();
  }

  Future<void> setMultipleItemsExact(
      List<CartItem> items,
      ) async {
    for (final item in items) {
      _cart.setItem(item);
    }

    await _saveCartToLocalDatabase();
  }

  void removeFromCart(
      String premiseCode,
      String itemCode,
      ) {
    _cart.removeItem(
      premiseCode,
      itemCode,
    );
    _saveCartToLocalDatabase();
  }

  void updateQuantity(
      String premiseCode,
      String itemCode,
      int newQuantity,
      ) {
    _cart.updateQuantity(
      premiseCode,
      itemCode,
      newQuantity,
    );
    _saveCartToLocalDatabase();
  }

  void clearCart() {
    _cart.clear();
    _saveCartToLocalDatabase();
  }

  Future<void> saveOrderToHistory() async {
    final items = _cart
        .getAllItems()
        .map(
          (item) => item.copyWith(),
    )
        .toList();

    if (items.isEmpty) {
      return;
    }

    final orderId =
        'ORD_${DateTime.now().millisecondsSinceEpoch}';

    final total = _cart.getGrandTotal();

    final premiseCode = _cart.storeList.isNotEmpty
        ? _cart.storeList.first
        : 'unknown';

    final storeName = items.isNotEmpty
        ? items.first.storeName
        : 'Store';

    await _dbService.saveOrder({
      'orderId': orderId,
      'premiseCode': premiseCode,
      'storeName': storeName,
      'totalAmount': total,
      'itemCount': items.length,
      'deliveryAddress': _userLocation,
    });
  }

  Future<List<Order>> getOrderHistory() async {
    try {
      final orders = await _dbService.getOrderHistory();
      final List<Order> orderList = [];

      for (final orderData in orders) {
        orderList.add(
          Order(
            id: orderData['orderId'],
            date: DateTime.parse(
              orderData['orderDate'],
            ),
            items: [],
            total: (orderData['totalAmount'] as num).toDouble(),
          ),
        );
      }

      return orderList;
    } catch (error) {
      debugPrint(
        'Unable to load order history: $error',
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRawOrderHistory() async {
    try {
      return await _dbService.getOrderHistory();
    } catch (error) {
      debugPrint(
        'Unable to load raw order history: $error',
      );
      return [];
    }
  }

  Future<void> syncToCloud() async {}

  Future<void> syncFromCloud() async {}

  Future<void> syncBothWays() async {}

  Future<void> _saveCartToLocalDatabase() async {
    try {
      await _dbService.clearCart();

      for (final premiseCode in _cart.storeList) {
        final items = _cart.getStoreItems(
          premiseCode,
        );

        for (final item in items) {
          await _dbService.addToCart({
            'itemCode': item.itemCode,
            'itemName': item.itemName,
            'premiseCode': item.premiseCode,
            'storeName': item.storeName,
            'price': item.price,
            'quantity': item.quantity,
          });
        }
      }
    } catch (error) {
      debugPrint(
        'Unable to save cart locally: $error',
      );
    }
  }

  Future<void> _loadCartFromLocalDatabase() async {
    try {
      final loadedCart = Cart();
      final cartItems = await _dbService.getAllCartItems();

      for (final itemData in cartItems) {
        final item = CartItem(
          itemCode: itemData['itemCode'].toString(),
          itemName: itemData['itemName'].toString(),
          premiseCode: itemData['premiseCode'].toString(),
          storeName: itemData['storeName'].toString(),
          price: (itemData['price'] as num).toDouble(),
          unit: '',
          category: '',
          quantity: (itemData['quantity'] as num).toInt(),
        );

        loadedCart.setItem(item);
      }

      _cart = loadedCart;
    } catch (error) {
      debugPrint(
        'Unable to load local cart: $error',
      );
      _cart = Cart();
    }
  }
}
