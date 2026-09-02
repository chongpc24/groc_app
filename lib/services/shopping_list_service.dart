import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/shopping_list_models.dart';
import 'database_service.dart';
import 'supabase_service.dart';

class ShoppingListService {
  ShoppingListService._();

  static final ShoppingListService instance = ShoppingListService._();

  final DatabaseService _database = DatabaseService();
  final SupabaseService _cloud = SupabaseService.instance;
  final Uuid _uuid = const Uuid();

  String get _userId => _cloud.requireUserId;

  Future<List<ShoppingListSummary>> loadLists() async {
    final userId = _userId;
    try {
      final lists = await _cloud.fetchShoppingLists();
      final items = await _cloud.fetchAllShoppingListItems();
      await _database.replaceShoppingListCache(userId, lists, items);
    } catch (error) {
      debugPrint('Shopping list cloud refresh failed: $error');
    }

    final rows = await _database.getShoppingListSummaries(userId);
    return rows.map(ShoppingListSummary.fromMap).toList();
  }

  Future<List<ShoppingListItemModel>> loadItems(String listId) async {
    final userId = _userId;
    try {
      final items = await _cloud.fetchShoppingListItems(listId);
      await _database.replaceSingleListItemsCache(userId, listId, items);
    } catch (error) {
      debugPrint('Shopping list item cloud refresh failed: $error');
    }

    final rows = await _database.getShoppingListItems(userId, listId);
    return rows.map(ShoppingListItemModel.fromMap).toList();
  }

  Future<ShoppingListSummary> createList(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('List name cannot be empty.');
    }
    final row = await _cloud.createShoppingList(
      id: _uuid.v4(),
      name: cleanName,
    );
    await _database.upsertShoppingListCache(_userId, row);
    final rows = await _database.getShoppingListSummaries(_userId);
    return ShoppingListSummary.fromMap(
      rows.firstWhere((item) => item['id'].toString() == row['id'].toString()),
    );
  }

  Future<void> renameList(String listId, String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('List name cannot be empty.');
    }
    final row = await _cloud.renameShoppingList(
      listId: listId,
      name: cleanName,
    );
    await _database.upsertShoppingListCache(_userId, row);
  }

  Future<void> deleteList(String listId) async {
    await _cloud.deleteShoppingList(listId);
    await _database.deleteShoppingListCache(listId);
  }

  Future<void> addProductToList({
    required String listId,
    required Product product,
  }) async {
    final existing = await _cloud.findShoppingListItem(
      listId: listId,
      itemCode: product.itemCode,
      premiseCode: product.premiseCode,
    );

    Map<String, dynamic> row;
    if (existing == null) {
      row = await _cloud.insertShoppingListItem({
        'id': _uuid.v4(),
        'list_id': listId,
        'item_code': product.itemCode,
        'item_name': product.itemName,
        'premise_code': product.premiseCode,
        'store_name': product.storeName,
        'price': product.price,
        'unit': product.unit,
        'category': product.category,
        'quantity': 1,
      });
    } else {
      final nextQuantity = ((existing['quantity'] as num?)?.toInt() ?? 1) + 1;
      row = await _cloud.updateShoppingListItemQuantity(
        itemId: existing['id'].toString(),
        quantity: nextQuantity,
      );
    }

    await _database.upsertShoppingListItemCache(_userId, row);
  }

  Future<void> updateQuantity(
      ShoppingListItemModel item,
      int quantity,
      ) async {
    if (quantity <= 0) {
      await removeItem(item.id);
      return;
    }
    final row = await _cloud.updateShoppingListItemQuantity(
      itemId: item.id,
      quantity: quantity,
    );
    await _database.upsertShoppingListItemCache(_userId, row);
  }

  Future<void> removeItem(String itemId) async {
    await _cloud.deleteShoppingListItem(itemId);
    await _database.deleteShoppingListItemCache(itemId);
  }
}
