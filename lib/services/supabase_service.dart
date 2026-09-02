import 'package:supabase_flutter/supabase_flutter.dart';

import 'database_service.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance =
  SupabaseService._();

  static const int _pageSize = 1000;

  SupabaseClient get client =>
      Supabase.instance.client;

  String get requireUserId {
    final userId = client.auth.currentUser?.id;

    if (userId == null) {
      throw StateError(
        'Login is required for this action.',
      );
    }

    return userId;
  }

  static Future<int> syncFromSupabase() async {
    final client =
        Supabase.instance.client;

    final List<Map<String, dynamic>>
    localRows = [];

    int from = 0;

    while (true) {
      final page = await client
          .from('prices')
          .select(
        'item_code, price, date, store_name, '
            'premise_code, '
            'items(item_name, unit, category)',
      )
          .range(
        from,
        from + _pageSize - 1,
      );

      final List data = page;

      if (data.isEmpty) {
        break;
      }

      for (final row in data) {
        final itemInfo =
        row['items']
        as Map<String, dynamic>?;

        localRows.add({
          'itemCode':
          row['item_code'],
          'itemName':
          itemInfo?['item_name'] ??
              'Unknown item',
          'unit':
          itemInfo?['unit'] ?? '',
          'category':
          itemInfo?['category'] ??
              'Uncategorised',
          'premiseCode':
          row['premise_code'],
          'storeName':
          row['store_name'],
          'price':
          (row['price'] as num)
              .toDouble(),
          'date':
          row['date'],
        });
      }

      if (data.length < _pageSize) {
        break;
      }

      from += _pageSize;
    }

    await DatabaseService()
        .replaceAll(localRows);

    return localRows.length;
  }

  Future<Map<String, dynamic>>
  fetchMyProfile() async {
    final row = await client
        .from('profiles')
        .select()
        .eq(
      'id',
      requireUserId,
    )
        .single();

    return Map<String, dynamic>.from(
      row,
    );
  }

  Future<Map<String, dynamic>>
  updateMyProfile({
    required String fullName,
    required String phoneNumber,
    required String gender,
    required String address,
  }) async {
    final row = await client
        .from('profiles')
        .update({
      'full_name':
      fullName.trim(),
      'phone_number':
      phoneNumber.trim(),
      'gender':
      gender,
      'address':
      address.trim(),
    })
        .eq(
      'id',
      requireUserId,
    )
        .select()
        .single();

    return Map<String, dynamic>.from(
      row,
    );
  }

  Future<List<Map<String, dynamic>>>
  fetchShoppingLists() async {
    final data = await client
        .from('shopping_lists')
        .select()
        .eq(
      'user_id',
      requireUserId,
    )
        .order(
      'updated_at',
      ascending: false,
    );

    return _toMapList(data);
  }

  Future<List<Map<String, dynamic>>>
  fetchShoppingListItems(
      String listId,
      ) async {
    final data = await client
        .from('shopping_list_items')
        .select()
        .eq(
      'list_id',
      listId,
    )
        .order(
      'updated_at',
      ascending: false,
    );

    return _toMapList(data);
  }

  Future<List<Map<String, dynamic>>>
  fetchAllShoppingListItems()
  async {
    final lists =
    await fetchShoppingLists();

    if (lists.isEmpty) {
      return [];
    }

    final all =
    <Map<String, dynamic>>[];

    for (final list in lists) {
      all.addAll(
        await fetchShoppingListItems(
          list['id'].toString(),
        ),
      );
    }

    return all;
  }

  Future<Map<String, dynamic>>
  createShoppingList({
    required String id,
    required String name,
  }) async {
    final row = await client
        .from('shopping_lists')
        .insert({
      'id': id,
      'user_id':
      requireUserId,
      'name':
      name.trim(),
    })
        .select()
        .single();

    return Map<String, dynamic>.from(
      row,
    );
  }

  Future<Map<String, dynamic>>
  renameShoppingList({
    required String listId,
    required String name,
  }) async {
    final row = await client
        .from('shopping_lists')
        .update({
      'name':
      name.trim(),
    })
        .eq(
      'id',
      listId,
    )
        .select()
        .single();

    return Map<String, dynamic>.from(
      row,
    );
  }

  Future<void> deleteShoppingList(
      String listId,
      ) async {
    await client
        .from('shopping_lists')
        .delete()
        .eq(
      'id',
      listId,
    );
  }

  Future<Map<String, dynamic>?>
  findShoppingListItem({
    required String listId,
    required String itemCode,
    required String premiseCode,
  }) async {
    final data = await client
        .from('shopping_list_items')
        .select()
        .eq(
      'list_id',
      listId,
    )
        .eq(
      'item_code',
      itemCode,
    )
        .eq(
      'premise_code',
      premiseCode,
    )
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return Map<String, dynamic>.from(
      data,
    );
  }

  Future<Map<String, dynamic>>
  insertShoppingListItem(
      Map<String, dynamic> values,
      ) async {
    final row = await client
        .from('shopping_list_items')
        .insert(values)
        .select()
        .single();

    return Map<String, dynamic>.from(
      row,
    );
  }

  Future<Map<String, dynamic>>
  updateShoppingListItemQuantity({
    required String itemId,
    required int quantity,
  }) async {
    final row = await client
        .from('shopping_list_items')
        .update({
      'quantity':
      quantity,
    })
        .eq(
      'id',
      itemId,
    )
        .select()
        .single();

    return Map<String, dynamic>.from(
      row,
    );
  }

  Future<void>
  deleteShoppingListItem(
      String itemId,
      ) async {
    await client
        .from('shopping_list_items')
        .delete()
        .eq(
      'id',
      itemId,
    );
  }

  List<Map<String, dynamic>>
  _toMapList(
      dynamic data,
      ) {
    return (data as List)
        .map(
          (row) =>
      Map<String, dynamic>.from(
        row as Map,
      ),
    )
        .toList();
  }
}