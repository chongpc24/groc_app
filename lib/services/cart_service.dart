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

  // ============= 购物车操作 =============

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

  // ============= 订单历史 (使用SQLite) =============

  /// 保存订单到本地数据库和云端
  Future<void> saveOrderToHistory() async {
    final items = _cart.getAllItems().map((item) => item.copyWith()).toList();

    if (items.isEmpty) return;

    final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
    final total = _cart.getGrandTotal();

    try {
      // 保存到本地SQLite
      await _dbService.saveOrder({
        'orderId': orderId,
        'premiseCode': _cart.storeList.isNotEmpty ? _cart.storeList.first : 'unknown',
        'storeName': items.isNotEmpty ? items.first.storeName : 'Store',
        'totalAmount': total,
        'itemCount': items.length,
        'deliveryAddress': _userLocation,
      });

      // 同时保存到Supabase
      try {
        await SupabaseService.saveOrderToSupabase(
          premiseCode: _cart.storeList.isNotEmpty ? _cart.storeList.first : 'unknown',
          storeName: items.isNotEmpty ? items.first.storeName : 'Store',
          totalAmount: total,
          itemCount: items.length,
          deliveryAddress: _userLocation,
        );
      } catch (e) {
        // 云端保存失败，但本地已保存
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 获取订单历史
  Future<List<Order>> getOrderHistory() async {
    try {
      final orders = await _dbService.getOrderHistory();
      return orders.map((orderData) {
        return Order(
          id: orderData['orderId'],
          date: DateTime.parse(orderData['orderDate']),
          items: [],
          total: orderData['totalAmount'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ============= 同步操作 =============

  /// 同步购物车到Supabase
  Future<void> syncToCloud() async {
    try {
      await SupabaseService.syncCartToSupabase();
    } catch (e) {
      rethrow;
    }
  }

  /// 从Supabase下载购物车
  Future<void> syncFromCloud() async {
    try {
      await SupabaseService.syncCartFromSupabase();
      await _loadCartFromLocalDatabase();
    } catch (e) {
      rethrow;
    }
  }

  /// 双向同步
  Future<void> syncBothWays() async {
    try {
      await SupabaseService.syncCartBothWays();
      await _loadCartFromLocalDatabase();
    } catch (e) {
      rethrow;
    }
  }

  // ============= 本地数据库操作 =============

  /// 保存购物车到本地SQLite
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
      // 错误处理
    }
  }

  /// 从本地SQLite加载购物车
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