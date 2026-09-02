import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/cart_item.dart';
import '../../models/shopping_list_models.dart';
import '../../services/cart_cloud_service.dart';
import '../../services/cart_service.dart';
import '../../services/shopping_list_service.dart';
import '../search/product_icon_tile.dart';

class ShoppingListDetailScreen
    extends StatefulWidget {
  final String listId;
  final String listName;

  const ShoppingListDetailScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<ShoppingListDetailScreen>
  createState() =>
      _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState
    extends State<ShoppingListDetailScreen> {
  final NumberFormat _currency =
  NumberFormat.currency(
    locale: 'ms_MY',
    symbol: 'RM ',
  );

  List<ShoppingListItemModel> _items =
  [];

  bool _loading = true;
  bool _addingToCart = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final items =
      await ShoppingListService.instance
          .loadItems(
        widget.listId,
      );

      if (mounted) {
        setState(() {
          _items = items;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load list: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _changeQuantity(
      ShoppingListItemModel item,
      int quantity,
      ) async {
    try {
      await ShoppingListService.instance
          .updateQuantity(
        item,
        quantity,
      );

      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update quantity: $error',
          ),
        ),
      );
    }
  }

  Future<void> _removeItem(
      ShoppingListItemModel item,
      ) async {
    try {
      await ShoppingListService.instance
          .removeItem(item.id);

      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to remove item: $error',
          ),
        ),
      );
    }
  }

  Future<void> _addWholeListToCart() async {
    if (_items.isEmpty ||
        _addingToCart) {
      return;
    }

    setState(() {
      _addingToCart = true;
    });

    try {
      final cartService =
      CartService();

      await cartService.initialize();

      final exactItems =
      _items
          .map(
            (item) => CartItem(
          itemCode:
          item.itemCode,
          itemName:
          item.itemName,
          premiseCode:
          item.premiseCode,
          storeName:
          item.storeName,
          price:
          item.price,
          unit: item.unit,
          category:
          item.category,
          quantity:
          item.quantity,
        ),
      )
          .toList();

      await cartService
          .setMultipleItemsExact(
        exactItems,
      );

      await CartCloudService.instance
          .syncFromLocal(
        cartService,
      );

      if (!mounted) {
        return;
      }

      final totalQuantity =
      _items.fold<int>(
        0,
            (sum, item) =>
        sum + item.quantity,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${_items.length} product${_items.length == 1 ? '' : 's'} ($totalQuantity total item${totalQuantity == 1 ? '' : 's'}) to cart.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to add list to cart: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _addingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total =
    _items.fold<double>(
      0,
          (sum, item) =>
      sum + item.lineTotal,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.listName,
        ),
        actions: [
          IconButton(
            onPressed:
            _loading ? null : _load,
            icon:
            const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading &&
          _items.isEmpty
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _items.isEmpty
          ? Center(
        child: Padding(
          padding:
          const EdgeInsets.all(
            28,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/grocery.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(
                height: 14,
              ),
              const Text(
                'This list is empty',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 7,
              ),
              Text(
                'Open a product, choose a store, then choose this shopping list.',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color:
                  Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      )
          : ListView.separated(
        padding:
        const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          120,
        ),
        itemCount:
        _items.length + 1,
        separatorBuilder:
            (context, index) =>
        const SizedBox(
          height: 8,
        ),
        itemBuilder:
            (context, index) {
          if (index ==
              _items.length) {
            return Card(
              child: Padding(
                padding:
                const EdgeInsets.all(
                  16,
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    const Text(
                      'Estimated total',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                    Text(
                      _currency.format(
                        total,
                      ),
                      style:
                      const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final item =
          _items[index];

          return Card(
            child: Padding(
              padding:
              const EdgeInsets.all(
                12,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      ClipRRect(
                        borderRadius:
                        BorderRadius
                            .circular(
                          10,
                        ),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child:
                          ProductIconTile(
                            itemName:
                            item.itemName,
                            category:
                            item.category,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              item.itemName,
                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              item.storeName,
                              style:
                              TextStyle(
                                color: Colors
                                    .grey.shade700,
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              '${_currency.format(item.price)}${item.unit.isEmpty ? '' : ' • ${item.unit}'}',
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _removeItem(
                            item,
                          );
                        },
                        icon:
                        const Icon(
                          Icons.delete_outline,
                        ),
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton
                          .filledTonal(
                        onPressed: () {
                          _changeQuantity(
                            item,
                            item.quantity -
                                1,
                          );
                        },
                        icon:
                        const Icon(
                          Icons.remove,
                          size: 18,
                        ),
                      ),
                      Padding(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 10,
                        ),
                        child: Text(
                          '${item.quantity}',
                          style:
                          const TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton
                          .filledTonal(
                        onPressed: () {
                          _changeQuantity(
                            item,
                            item.quantity +
                                1,
                          );
                        },
                        icon:
                        const Icon(
                          Icons.add,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar:
      _items.isEmpty
          ? null
          : SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          child: FilledButton.icon(
            onPressed:
            _addingToCart
                ? null
                : _addWholeListToCart,
            style:
            FilledButton.styleFrom(
              backgroundColor:
              Colors.green.shade700,
              padding:
              const EdgeInsets.symmetric(
                vertical: 15,
              ),
            ),
            icon: _addingToCart
                ? const SizedBox(
              width: 18,
              height: 18,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(
              Icons.add_shopping_cart,
            ),
            label: Text(
              _addingToCart
                  ? 'Adding...'
                  : 'Add Entire List to Cart',
            ),
          ),
        ),
      ),
    );
  }
}
