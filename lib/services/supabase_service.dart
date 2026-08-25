import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

class SupabaseService {
  static const int _pageSize = 1000;

  // ============= PRODUCTS (保持现有功能) =============

  static Future<int> syncFromSupabase() async {
    final client = Supabase.instance.client;
    final List<Map<String, dynamic>> localRows = [];

    int from = 0;
    while (true) {
      final page = await client
          .from('prices')
          .select(
        'item_code, price, date, store_name, premise_code, items(item_name, unit, category)',
      )
          .range(from, from + _pageSize - 1);

      final List data = page as List;
      if (data.isEmpty) break;

      for (final row in data) {
        final itemInfo = row['items'] as Map<String, dynamic>?;
        localRows.add({
          'itemCode': row['item_code'],
          'itemName': itemInfo?['item_name'] ?? 'Unknown item',
          'unit': itemInfo?['unit'] ?? '',
          'category': itemInfo?['category'] ?? 'Uncategorised',
          'premiseCode': row['premise_code'],
          'storeName': row['store_name'],
          'price': (row['price'] as num).toDouble(),
          'date': row['date'],
        });
      }

      if (data.length < _pageSize) break; // last page
      from += _pageSize;
    }

    await DatabaseService().replaceAll(localRows);
    return localRows.length;
  }

  // ============= CART OPERATIONS (NEW) =============

  /// 将本地购物车同步到Supabase
  static Future<void> syncCartToSupabase() async {
    final dbService = DatabaseService();
    final client = Supabase.instance.client;

    try {
      // 获取待同步的购物车项目
      final pendingItems = await dbService.getPendingSyncCart();

      if (pendingItems.isEmpty) {
        print('✅ No pending cart items to sync');
        return;
      }

      // 获取当前用户
      final user = client.auth.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        return;
      }

      // 同步到Supabase
      for (final item in pendingItems) {
        await client.from('user_carts').upsert({
          'id': item['id'],
          'user_id': user.id,
          'item_code': item['itemCode'],
          'item_name': item['itemName'],
          'premise_code': item['premiseCode'],
          'store_name': item['storeName'],
          'price': item['price'],
          'quantity': item['quantity'],
          'added_at': item['addedAt'],
          'synced_at': DateTime.now().toIso8601String(),
        });
      }

      // 标记为已同步
      await dbService.markCartAsSynced(
        pendingItems.map((e) => e['id'] as int).toList(),
      );

      print('✅ Synced ${pendingItems.length} cart items to Supabase');
    } catch (e) {
      print('❌ Error syncing cart: $e');
      rethrow;
    }
  }

  /// 从Supabase下载购物车
  static Future<void> syncCartFromSupabase() async {
    final dbService = DatabaseService();
    final client = Supabase.instance.client;

    try {
      final user = client.auth.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        return;
      }

      // 从Supabase获取购物车
      final response = await client
          .from('user_carts')
          .select()
          .eq('user_id', user.id);

      if (response.isEmpty) {
        print('✅ No items in cloud cart');
        return;
      }

      // 清空本地购物车（或者合并策略）
      // 选项1: 覆盖
      await dbService.clearCart();

      // 选项2: 合并（如果需要）
      // 获取本地购物车，与云端合并

      // 添加云端购物车到本地
      for (final item in response) {
        await dbService.addToCart({
          'itemCode': item['item_code'],
          'itemName': item['item_name'],
          'premiseCode': item['premise_code'],
          'storeName': item['store_name'],
          'price': item['price'],
          'quantity': item['quantity'],
          'syncStatus': 'synced',
        });
      }

      print('✅ Synced ${response.length} items from Supabase');
    } catch (e) {
      print('❌ Error syncing cart from cloud: $e');
      rethrow;
    }
  }

  /// 双向同步（本地 ↔ Supabase）
  static Future<void> syncCartBothWays() async {
    try {
      print('🔄 Starting bi-directional cart sync...');

      // 先上传本地待同步的
      await syncCartToSupabase();

      // 再下载云端的
      await syncCartFromSupabase();

      print('✅ Cart sync completed');
    } catch (e) {
      print('❌ Bi-directional sync failed: $e');
      rethrow;
    }
  }

  // ============= ORDER OPERATIONS (NEW) =============

  /// 保存订单到Supabase
  static Future<String> saveOrderToSupabase({
    required String premiseCode,
    required String storeName,
    required double totalAmount,
    required int itemCount,
    required String deliveryAddress,
  }) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // 生成订单ID
      final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}_${user.id.substring(0, 8)}';

      // 保存到Supabase
      await client.from('orders').insert({
        'order_id': orderId,
        'user_id': user.id,
        'premise_code': premiseCode,
        'store_name': storeName,
        'total_amount': totalAmount,
        'item_count': itemCount,
        'delivery_address': deliveryAddress,
        'order_date': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      print('✅ Order saved to Supabase: $orderId');
      return orderId;
    } catch (e) {
      print('❌ Error saving order: $e');
      rethrow;
    }
  }

  /// 从Supabase获取订单历史
  static Future<List<Map<String, dynamic>>> getOrdersFromSupabase() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await client
          .from('orders')
          .select()
          .eq('user_id', user.id)
          .order('order_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching orders: $e');
      rethrow;
    }
  }

  /// 同步订单到Supabase
  static Future<void> syncOrdersToSupabase() async {
    final dbService = DatabaseService();
    final client = Supabase.instance.client;

    try {
      final pendingOrders = await dbService.getPendingSyncOrders();

      if (pendingOrders.isEmpty) {
        print('✅ No pending orders to sync');
        return;
      }

      final user = client.auth.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        return;
      }

      for (final order in pendingOrders) {
        await client.from('orders').upsert({
          'order_id': order['orderId'],
          'user_id': user.id,
          'premise_code': order['premiseCode'],
          'store_name': order['storeName'],
          'total_amount': order['totalAmount'],
          'item_count': order['itemCount'],
          'delivery_address': order['deliveryAddress'],
          'order_date': order['orderDate'],
          'status': 'completed',
        });

        await dbService.markOrderAsSynced(order['orderId']);
      }

      print('✅ Synced ${pendingOrders.length} orders');
    } catch (e) {
      print('❌ Error syncing orders: $e');
      rethrow;
    }
  }
}