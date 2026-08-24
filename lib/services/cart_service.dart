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

  // 假设用户住在 Klang（巴生）
  // 这里硬编码各店铺的距离
  static final Map<String, StoreInfo> storeDistances = {
    'nsk': StoreInfo(
      premiseCode: 'nsk',
      storeName: 'NSK',
      distance: 3.5,  // 3.5km
    ),
    'aeon': StoreInfo(
      premiseCode: 'aeon',
      storeName: 'Aeon',
      distance: 7.0,  // 7km
    ),
    'lotus': StoreInfo(
      premiseCode: 'lotus',
      storeName: 'Lotus',
      distance: 15.0,  // 15km
    ),
    'giant': StoreInfo(
      premiseCode: 'giant',
      storeName: 'Giant',
      distance: 2.0,  // 2km
    ),
    'hero': StoreInfo(
      premiseCode: 'hero',
      storeName: 'Hero',
      distance: 8.5,  // 8.5km
    ),
    'tesco': StoreInfo(
      premiseCode: 'tesco',
      storeName: 'Tesco',
      distance: 5.0,  // 5km
    ),
  };

  late Cart _cart;

  /// 初始化购物车
  Future<void> initialize() async {
    _cart = Cart();
    await _loadCart();
  }

  /// 获取购物车实例
  Cart get cart => _cart;

  /// 获取店铺的距离（公里）
  double getStoreDistance(String premiseCode) {
    return storeDistances[premiseCode]?.distance ?? 0;
  }

  /// 获取店铺信息
  StoreInfo? getStoreInfo(String premiseCode) {
    return storeDistances[premiseCode];
  }

  /// 添加商品到购物车
  /// Product 是来自 search 功能的数据
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

  /// 从购物车移除商品
  void removeFromCart(String premiseCode, String itemCode) {
    _cart.removeItem(premiseCode, itemCode);
    _saveCart();
  }

  /// 更新商品数量
  void updateQuantity(String premiseCode, String itemCode, int newQuantity) {
    _cart.updateQuantity(premiseCode, itemCode, newQuantity);
    _saveCart();
  }

  /// 清空购物车
  void clearCart() {
    _cart.clear();
    _saveCart();
  }

  /// 保存购物车到本地存储（SharedPreferences）
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();

    // 将购物车转换为JSON
    final cartData = _cartToJson();
    await prefs.setString('cart_data', jsonEncode(cartData));
  }

  /// 从本地存储加载购物车
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

  /// 将购物车转为JSON格式
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

  /// 从JSON格式加载购物车
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
