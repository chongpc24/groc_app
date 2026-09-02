import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cart_service.dart';

class CartCloudService {
  CartCloudService._();

  static final CartCloudService instance = CartCloudService._();

  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Login is required for cart actions.');
    }
    return id;
  }

  Future<void> syncFromLocal(CartService cartService) async {
    final userId = _userId;
    final cart = cartService.cart;
    final rows = <Map<String, dynamic>>[];

    for (final premiseCode in cart.storeList) {
      for (final item in cart.getStoreItems(premiseCode)) {
        rows.add({
          'user_id': userId,
          'item_code': item.itemCode,
          'item_name': item.itemName,
          'premise_code': premiseCode,
          'store_name': item.storeName,
          'price': item.price,
          'unit': item.unit,
          'category': item.category,
          'quantity': item.quantity,
        });
      }
    }

    await _client
        .from('user_cart_items')
        .delete()
        .eq('user_id', userId);

    if (rows.isNotEmpty) {
      await _client.from('user_cart_items').insert(rows);
    }
  }

  Future<void> restoreToLocalIfEmpty(CartService cartService) async {
    if (!cartService.cart.isEmpty) {
      return;
    }

    final data = await _client
        .from('user_cart_items')
        .select()
        .eq('user_id', _userId)
        .order('updated_at');

    for (final raw in data as List) {
      final row = Map<String, dynamic>.from(raw as Map);

      cartService.addToCart(
        itemCode: row['item_code'].toString(),
        itemName: row['item_name'].toString(),
        premiseCode: row['premise_code'].toString(),
        storeName: row['store_name'].toString(),
        price: (row['price'] as num).toDouble(),
        unit: row['unit']?.toString() ?? '',
        category: row['category']?.toString() ?? '',
        quantity: (row['quantity'] as num?)?.toInt() ?? 1,
      );
    }
  }

  Future<String> placeOrderFromLocal(CartService cartService) async {
    final cart = cartService.cart;

    if (cart.isEmpty) {
      throw StateError('Cart is empty.');
    }

    final orderItems = <Map<String, dynamic>>[];

    for (final premiseCode in cart.storeList) {
      for (final item in cart.getStoreItems(premiseCode)) {
        orderItems.add({
          'item_code': item.itemCode,
          'item_name': item.itemName,
          'premise_code': premiseCode,
          'store_name': item.storeName,
          'price': item.price,
          'unit': item.unit,
          'category': item.category,
          'quantity': item.quantity,
        });
      }
    }

    final result = await _client.rpc(
      'place_user_order',
      params: {
        'p_total_amount': cart.getGrandTotal(),
        'p_item_count': cart.totalItemCount,
        'p_delivery_address': cartService.userLocation,
        'p_items': orderItems,
      },
    );

    return result.toString();
  }

  Future<void> safeSync(CartService cartService) async {
    try {
      await syncFromLocal(cartService);
    } catch (error) {
      debugPrint('Cart cloud sync failed: $error');
    }
  }
}
