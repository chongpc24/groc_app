import 'cart_item.dart';

class Cart {

  Map<String, List<CartItem>> _itemsByStore = {};

  Cart();


  List<String> get storeList => _itemsByStore.keys.toList();


  List<CartItem> getStoreItems(String premiseCode) {
    return _itemsByStore[premiseCode] ?? [];
  }


  List<CartItem> getAllItems() {
    return _itemsByStore.values.expand((items) => items).toList();
  }


  void addItem(CartItem item) {
    final premiseCode = item.premiseCode;

    if (_itemsByStore.containsKey(premiseCode)) {

      final storeItems = _itemsByStore[premiseCode]!;


      final existingIndex = storeItems.indexWhere(
            (cartItem) => cartItem.itemCode == item.itemCode,
      );

      if (existingIndex >= 0) {

        final existing = storeItems[existingIndex];
        storeItems[existingIndex] = existing.copyWith(
          quantity: existing.quantity + 1,
        );
      } else {

        storeItems.add(item);
      }
    } else {

      _itemsByStore[premiseCode] = [item];
    }
  }

  /// 从购物车移除商品
  void removeItem(String premiseCode, String itemCode) {
    if (_itemsByStore.containsKey(premiseCode)) {
      final storeItems = _itemsByStore[premiseCode]!;
      storeItems.removeWhere((item) => item.itemCode == itemCode);

      // 如果店铺没有商品了，删除这个店铺
      if (storeItems.isEmpty) {
        _itemsByStore.remove(premiseCode);
      }
    }
  }

  /// 更新商品数量
  void updateQuantity(String premiseCode, String itemCode, int newQuantity) {
    if (newQuantity <= 0) {
      // 如果数量<=0，就移除
      removeItem(premiseCode, itemCode);
    } else {
      final storeItems = _itemsByStore[premiseCode];
      if (storeItems != null) {
        final index = storeItems.indexWhere((item) => item.itemCode == itemCode);
        if (index >= 0) {
          storeItems[index] = storeItems[index].copyWith(quantity: newQuantity);
        }
      }
    }
  }

  /// 清空购物车
  void clear() {
    _itemsByStore.clear();
  }

  /// 获取某个店铺的商品小计（不含配送费）
  double getStoreItemsSubtotal(String premiseCode) {
    final items = getStoreItems(premiseCode);
    return items.fold(0, (sum, item) => sum + item.itemSubtotal);
  }

  /// 获取某个店铺的配送费（所有商品的配送费都一样，因为同一店铺）
  double getStoreDeliveryFee(String premiseCode) {
    final items = getStoreItems(premiseCode);
    if (items.isEmpty) return 0;
    return items.first.deliveryFee;
  }

  /// 获取某个店铺的总计（商品+配送费）
  double getStoreTotal(String premiseCode) {
    return getStoreItemsSubtotal(premiseCode) + getStoreDeliveryFee(premiseCode);
  }

  /// 获取所有商品的小计（所有店铺，不含配送费）
  double getItemsSubtotal() {
    return _itemsByStore.values.fold(
      0,
          (sum, storeItems) => sum + storeItems.fold(0, (s, item) => s + item.itemSubtotal),
    );
  }

  /// 获取总配送费（所有店铺的配送费之和）
  double getTotalDeliveryFee() {
    return _itemsByStore.keys.fold(0, (sum, premiseCode) => sum + getStoreDeliveryFee(premiseCode));
  }

  /// 获取购物车总计
  double getGrandTotal() {
    return getItemsSubtotal() + getTotalDeliveryFee();
  }

  /// 购物车是否为空
  bool get isEmpty => _itemsByStore.isEmpty;

  /// 购物车中的总商品数（数量之和）
  int get totalItemCount {
    return getAllItems().fold(0, (sum, item) => sum + item.quantity);
  }

  /// 购物车中的总SKU数（不同商品种类数）
  int get totalSKU {
    return getAllItems().length;
  }
}
