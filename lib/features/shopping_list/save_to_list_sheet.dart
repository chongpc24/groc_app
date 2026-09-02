import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/product.dart';
import '../../models/shopping_list_models.dart';
import '../../services/shopping_list_service.dart';
import '../account/auth_required.dart';

class SaveToListSheet {
  static Future<void> show(
      BuildContext context,
      List<Product> storeOptions,
      ) async {
    final allowed =
    await AuthRequired.ensureLoggedIn(
      context,
    );

    if (!context.mounted ||
        !allowed) {
      return;
    }

    if (storeOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No store option is available for this product.',
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _SaveToListContent(
        storeOptions: storeOptions,
      ),
    );
  }
}

class _SaveToListContent
    extends StatefulWidget {
  final List<Product> storeOptions;

  const _SaveToListContent({
    required this.storeOptions,
  });

  @override
  State<_SaveToListContent> createState() =>
      _SaveToListContentState();
}

class _SaveToListContentState
    extends State<_SaveToListContent> {
  late Future<List<ShoppingListSummary>>
  _future;

  Product? _selectedProduct;
  String? _savingListId;

  final _currency = NumberFormat.currency(
    locale: 'ms_MY',
    symbol: 'RM ',
  );

  @override
  void initState() {
    super.initState();

    _future =
        ShoppingListService.instance.loadLists();

    if (widget.storeOptions.length == 1) {
      _selectedProduct =
          widget.storeOptions.first;
    }
  }

  Future<void> _saveTo(
      ShoppingListSummary list,
      ) async {
    final product = _selectedProduct;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose a store first.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _savingListId = list.id;
    });

    try {
      await ShoppingListService.instance
          .addProductToList(
        listId: list.id,
        product: product,
      );

      if (!mounted) {
        return;
      }

      final messenger =
      ScaffoldMessenger.of(context);

      Navigator.pop(context);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${product.itemName} from ${product.storeName} saved to ${list.name}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _savingListId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save item: $error',
          ),
        ),
      );
    }
  }

  Future<void> _createAndSave() async {
    final product = _selectedProduct;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose a store first.',
          ),
        ),
      );
      return;
    }

    String draftName = '';

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'New Shopping List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextFormField(
          autofocus: true,
          maxLength: 80,
          textCapitalization:
          TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'List name',
            hintText:
            'e.g. Bakery Suppliers',
          ),
          onChanged: (value) {
            draftName = value;
          },
          onFieldSubmitted: (value) {
            final clean = value.trim();

            if (clean.isNotEmpty) {
              Navigator.pop(
                dialogContext,
                clean,
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final clean =
              draftName.trim();

              if (clean.isNotEmpty) {
                Navigator.pop(
                  dialogContext,
                  clean,
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (!mounted ||
        name == null) {
      return;
    }

    try {
      final list =
      await ShoppingListService.instance
          .createList(name);

      if (!mounted) {
        return;
      }

      await _saveTo(list);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to create list: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemName =
        widget.storeOptions.first.itemName;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 +
              MediaQuery.of(context)
                  .viewInsets
                  .bottom,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            Text(
              'Save to Shopping List',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              itemName,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
              style: TextStyle(
                color:
                Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Choose Store',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxHeight: 230,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount:
                widget.storeOptions.length,
                separatorBuilder:
                    (context, index) =>
                const SizedBox(
                  height: 6,
                ),
                itemBuilder:
                    (context, index) {
                  final product = widget
                      .storeOptions[index];

                  final selected =
                      _selectedProduct
                          ?.premiseCode ==
                          product.premiseCode;

                  return Material(
                    color: selected
                        ? Colors.green.shade50
                        : Colors.grey.shade50,
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedProduct =
                              product;
                        });
                      },
                      child: Padding(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons
                                  .radio_button_checked
                                  : Icons
                                  .radio_button_off,
                              color: selected
                                  ? Colors
                                  .green
                                  .shade700
                                  : Colors.grey,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  Text(
                                    product
                                        .storeName,
                                    style:
                                    const TextStyle(
                                      fontWeight:
                                      FontWeight
                                          .w600,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 2,
                                  ),
                                  Text(
                                    '${_currency.format(product.price)}${product.unit.isEmpty ? '' : ' • ${product.unit}'}',
                                  ),
                                ],
                              ),
                            ),
                            if (index == 0)
                              Container(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration:
                                BoxDecoration(
                                  color: Colors
                                      .green
                                      .shade100,
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    20,
                                  ),
                                ),
                                child: Text(
                                  'Lowest',
                                  style:
                                  TextStyle(
                                    color: Colors
                                        .green
                                        .shade800,
                                    fontSize: 11,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '2. Choose Shopping List',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedProduct == null)
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  vertical: 10,
                ),
                child: Text(
                  'Select one store above before choosing a shopping list.',
                  style: TextStyle(
                    color:
                    Colors.orange.shade800,
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed:
              _selectedProduct == null
                  ? null
                  : _createAndSave,
              icon: const Icon(Icons.add),
              label: const Text(
                'Create New List',
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxHeight: 300,
              ),
              child: FutureBuilder<
                  List<
                      ShoppingListSummary>>(
                future: _future,
                builder:
                    (context, snapshot) {
                  if (snapshot
                      .connectionState ==
                      ConnectionState
                          .waiting) {
                    return const Padding(
                      padding:
                      EdgeInsets.all(
                        24,
                      ),
                      child: Center(
                        child:
                        CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding:
                      const EdgeInsets
                          .all(14),
                      child: Text(
                        'Unable to load lists: ${snapshot.error}',
                      ),
                    );
                  }

                  final lists =
                      snapshot.data ?? [];

                  if (lists.isEmpty) {
                    return const Padding(
                      padding:
                      EdgeInsets.all(
                        14,
                      ),
                      child: Text(
                        'No lists yet. Create one above.',
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount:
                    lists.length,
                    separatorBuilder:
                        (context, index) =>
                    const Divider(
                      height: 1,
                    ),
                    itemBuilder:
                        (context, index) {
                      final list =
                      lists[index];

                      final saving =
                          _savingListId ==
                              list.id;

                      return ListTile(
                        enabled:
                        _selectedProduct !=
                            null,
                        leading: const Icon(
                          Icons
                              .shopping_bag_outlined,
                        ),
                        title:
                        Text(list.name),
                        subtitle: Text(
                          '${list.itemCount} item${list.itemCount == 1 ? '' : 's'}',
                        ),
                        trailing: saving
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth:
                            2,
                          ),
                        )
                            : const Icon(
                          Icons
                              .chevron_right,
                        ),
                        onTap:
                        _selectedProduct ==
                            null ||
                            saving
                            ? null
                            : () {
                          _saveTo(
                            list,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
