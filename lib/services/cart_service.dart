import 'database_service.dart';
import 'supabase_service.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class CartService {
  static final CartService _instance = CartService._internal();

  factory CartService() {
    return _instance;
  }

  CartService._internal();

  final DatabaseService _dbService = DatabaseService();

  String _userLocation = 'Klang';

  String get userLocation => _userLocation;

  void setUserLocation(String location) {
    _userLocation = location;
  }

  late Cart _cart;

  Future<void> initialize() async {
    _cart = Cart();
    await _loadCartFromLocalDatabase();
  }

  Cart get cart => _cart;

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

  void removeFromCart(String premiseCode, String itemCode) {
    _cart.removeItem(premiseCode, itemCode);
    _saveCartToLocalDatabase();
  }

  void updateQuantity(String premiseCode, String itemCode, int newQuantity) {
    _cart.updateQuantity(premiseCode, itemCode, newQuantity);
    _saveCartToLocalDatabase();
  }

  void clearCart() {
    _cart.clear();
    _saveCartToLocalDatabase();
  }

  Future<void> saveOrderToHistory() async {
    final items = _cart.getAllItems().map((item) => item.copyWith()).toList();

    if (items.isEmpty) return;

    final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
    final total = _cart.getGrandTotal();
    final premiseCode = _cart.storeList.isNotEmpty ? _cart.storeList.first : 'unknown';
    final storeName = items.isNotEmpty ? items.first.storeName : 'Store';

    try {
      await _dbService.saveOrder({
        'orderId': orderId,
        'premiseCode': premiseCode,
        'storeName': storeName,
        'totalAmount': total,
        'itemCount': items.length,
        'deliveryAddress': _userLocation,
      });

      try {
        await SupabaseService.saveOrderToSupabase(
          premiseCode: premiseCode,
          storeName: storeName,
          totalAmount: total,
          itemCount: items.length,
          deliveryAddress: _userLocation,
        );
      } catch (e) {
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Order>> getOrderHistory() async {
    try {
      final orders = await _dbService.getOrderHistory();

      List<Order> orderList = [];
      for (final orderData in orders) {
        final order = Order(
          id: orderData['orderId'],
          date: DateTime.parse(orderData['orderDate']),
          items: [],
          total: orderData['totalAmount'],
        );
        orderList.add(order);
      }
      return orderList;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRawOrderHistory() async {
    try {
      return await _dbService.getOrderHistory();
    } catch (e) {
      return [];
    }
  }

  Future<void> syncToCloud() async {
    try {
      await SupabaseService.syncCartToSupabase();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncFromCloud() async {
    try {
      await SupabaseService.syncCartFromSupabase();
      await _loadCartFromLocalDatabase();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncBothWays() async {
    try {
      await SupabaseService.syncCartBothWays();
      await _loadCartFromLocalDatabase();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveCartToLocalDatabase() async {
    try {
      await _dbService.clearCart();

      for (final premiseCode in _cart.storeList) {
        final items = _cart.getStoreItems(premiseCode);
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
    } catch (e) {
    }
  }

  Future<void> _loadCartFromLocalDatabase() async {
    try {
      _cart = Cart();
      final cartItems = await _dbService.getAllCartItems();

      for (final itemData in cartItems) {
        final item = CartItem(
          itemCode: itemData['itemCode'],
          itemName: itemData['itemName'],
          premiseCode: itemData['premiseCode'],
          storeName: itemData['storeName'],
          price: itemData['price'],
          unit: '',
          category: '',
          quantity: itemData['quantity'],
        );
        _cart.addItem(item);
      }
    } catch (e) {
      _cart = Cart();
    }
  }
}