import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import 'cart_service.dart';

class CartCloudService {
  CartCloudService._();

  static final CartCloudService instance =
  CartCloudService._();

  SupabaseClient get _client =>
      Supabase.instance.client;

  Future<void> _cloudQueue =
  Future<void>.value();

  String get _userId {
    final id =
        _client.auth.currentUser?.id;

    if (id == null) {
      throw StateError(
        'Login is required for cart actions.',
      );
    }

    return id;
  }

  Future<void> syncFromLocal(
      CartService cartService,
      ) {
    final previous = _cloudQueue;
    final gate = Completer<void>();
    _cloudQueue = gate.future;

    return _runSerializedSync(
      previous: previous,
      gate: gate,
      cartService: cartService,
    );
  }

  Future<void> _runSerializedSync({
    required Future<void> previous,
    required Completer<void> gate,
    required CartService cartService,
  }) async {
    try {
      try {
        await previous;
      } catch (_) {}

      await _syncNow(cartService);
    } finally {
      if (!gate.isCompleted) {
        gate.complete();
      }
    }
  }

  Future<void> _syncNow(
      CartService cartService,
      ) async {
    final userId = _userId;
    final cart = cartService.cart;

    final rows =
    <Map<String, dynamic>>[];

    for (final premiseCode
    in cart.storeList) {
      for (final item
      in cart.getStoreItems(
        premiseCode,
      )) {
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
        .eq(
      'user_id',
      userId,
    );

    if (rows.isNotEmpty) {
      await _client
          .from('user_cart_items')
          .insert(rows);
    }
  }

  Future<void> restoreToLocalIfEmpty(
      CartService cartService,
      ) async {
    if (!cartService.cart.isEmpty) {
      return;
    }

    final data = await _client
        .from('user_cart_items')
        .select()
        .eq(
      'user_id',
      _userId,
    )
        .order('updated_at');

    final items = <CartItem>[];

    for (final raw in data as List) {
      final row =
      Map<String, dynamic>.from(
        raw as Map,
      );

      items.add(
        CartItem(
          itemCode:
          row['item_code'].toString(),
          itemName:
          row['item_name'].toString(),
          premiseCode:
          row['premise_code'].toString(),
          storeName:
          row['store_name'].toString(),
          price:
          (row['price'] as num).toDouble(),
          unit:
          row['unit']?.toString() ?? '',
          category:
          row['category']?.toString() ?? '',
          quantity:
          (row['quantity'] as num?)
              ?.toInt() ??
              1,
        ),
      );
    }

    if (items.isNotEmpty) {
      await cartService
          .setMultipleItemsExact(items);
    }
  }

  Future<String> placeOrderFromLocal(
      CartService cartService,
      ) async {
    try {
      await _cloudQueue;
    } catch (_) {}

    final cart = cartService.cart;

    if (cart.isEmpty) {
      throw StateError(
        'Cart is empty.',
      );
    }

    final orderItems =
    <Map<String, dynamic>>[];

    for (final premiseCode
    in cart.storeList) {
      for (final item
      in cart.getStoreItems(
        premiseCode,
      )) {
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

    final result =
    await _client.rpc(
      'place_user_order',
      params: {
        'p_total_amount':
        cart.getGrandTotal(),
        'p_item_count':
        cart.totalItemCount,
        'p_delivery_address':
        cartService.userLocation,
        'p_items': orderItems,
      },
    );

    return result.toString();
  }

  Future<void> safeSync(
      CartService cartService,
      ) async {
    try {
      await syncFromLocal(
        cartService,
      );
    } catch (error) {
      debugPrint(
        'Cart cloud sync failed: $error',
      );
    }
  }
}
