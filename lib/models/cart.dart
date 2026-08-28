import 'cart_item.dart';

class Cart {

  final Map<String, List<CartItem>> _itemsByStore = {};

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

  void removeItem(String premiseCode, String itemCode) {
    if (_itemsByStore.containsKey(premiseCode)) {
      final storeItems = _itemsByStore[premiseCode]!;
      storeItems.removeWhere((item) => item.itemCode == itemCode);

      if (storeItems.isEmpty) {
        _itemsByStore.remove(premiseCode);
      }
    }
  }

  void updateQuantity(String premiseCode, String itemCode, int newQuantity) {
    if (newQuantity <= 0) {
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

  void clear() {
    _itemsByStore.clear();
  }

  double getStoreItemsSubtotal(String premiseCode) {
    final items = getStoreItems(premiseCode);
    return items.fold(0, (sum, item) => sum + item.itemSubtotal);
  }




  double getItemsSubtotal() {
    return _itemsByStore.values.fold(
      0,
          (sum, storeItems) => sum + storeItems.fold(0, (s, item) => s + item.itemSubtotal),
    );
  }


  double getGrandTotal() {
    return getItemsSubtotal() ;
  }

  bool get isEmpty => _itemsByStore.isEmpty;

  int get totalItemCount {
    return getAllItems().fold(0, (sum, item) => sum + item.quantity);
  }

  int get totalSKU {
    return getAllItems().length;
  }
}
