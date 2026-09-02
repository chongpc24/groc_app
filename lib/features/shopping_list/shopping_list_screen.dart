import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/shopping_list_models.dart';
import '../../services/auth_service.dart';
import '../../services/shopping_list_service.dart';
import '../account/login_screen.dart';
import 'shopping_list_detail_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() =>
      _ShoppingListScreenState();
}

class _ShoppingListScreenState
    extends State<ShoppingListScreen> {
  StreamSubscription<AuthState>? _subscription;

  List<ShoppingListSummary> _lists = [];
  final Set<String> _selectedIds = {};

  bool _loading = false;
  bool _selectionMode = false;
  String? _error;

  final NumberFormat _currency =
  NumberFormat.currency(
    locale: 'ms_MY',
    symbol: 'RM ',
  );

  @override
  void initState() {
    super.initState();

    _subscription =
        AuthService.instance.authStateChanges.listen(
              (_) {
            if (mounted) {
              _load();
            }
          },
        );

    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!AuthService.instance.isLoggedIn) {
      if (mounted) {
        setState(() {
          _lists = [];
          _selectedIds.clear();
          _selectionMode = false;
          _loading = false;
          _error = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final lists =
      await ShoppingListService.instance
          .loadLists();

      if (mounted) {
        setState(() {
          _lists = lists;

          _selectedIds.removeWhere(
                (id) => !_lists.any(
                  (list) => list.id == id,
            ),
          );

          if (_selectedIds.isEmpty) {
            _selectionMode = false;
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    final loggedIn =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const LoginScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (loggedIn == true) {
      await _load();
    }
  }

  Future<void> _createList() async {
    final name = await _askForName(
      title: 'New Shopping List',
      initialValue: '',
      buttonText: 'Create',
    );

    if (name == null) {
      return;
    }

    try {
      await ShoppingListService.instance
          .createList(name);

      await _load();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Created "$name".',
          ),
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
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

  Future<void> _renameList(
      ShoppingListSummary list,
      ) async {
    final name = await _askForName(
      title: 'Rename List',
      initialValue: list.name,
      buttonText: 'Save',
    );

    if (name == null ||
        name == list.name) {
      return;
    }

    try {
      await ShoppingListService.instance
          .renameList(
        list.id,
        name,
      );

      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to rename list: $error',
          ),
        ),
      );
    }
  }

  void _startSelection(
      String id,
      ) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(
      String id,
      ) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }

      _selectionMode =
          _selectedIds.isNotEmpty;
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length ==
          _lists.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectionMode = true;
        _selectedIds
          ..clear()
          ..addAll(
            _lists.map(
                  (list) => list.id,
            ),
          );
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final count =
        _selectedIds.length;

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Text(
              'Delete selected lists?',
            ),
            content: Text(
              'Delete $count selected shopping list${count == 1 ? '' : 's'} and all items inside?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    final ids =
    _selectedIds.toList();

    try {
      for (final id in ids) {
        await ShoppingListService.instance
            .deleteList(id);
      }

      _cancelSelection();
      await _load();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$count list${count == 1 ? '' : 's'} deleted.',
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
            'Unable to delete selected lists: $error',
          ),
        ),
      );
    }
  }

  Future<void> _clearAllLists() async {
    if (_lists.isEmpty) {
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Text(
              'Clear all shopping lists?',
            ),
            content: const Text(
              'This will delete every shopping list and every item saved inside them.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text(
                  'Clear All',
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final ids =
      _lists.map(
            (list) => list.id,
      ).toList();

      for (final id in ids) {
        await ShoppingListService.instance
            .deleteList(id);
      }

      _cancelSelection();
      await _load();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All shopping lists cleared.',
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
            'Unable to clear lists: $error',
          ),
        ),
      );
    }
  }

  Future<void> _deleteSingleList(
      ShoppingListSummary list,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Text(
              'Delete shopping list?',
            ),
            content: Text(
              'Delete "${list.name}" and all items inside it?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ShoppingListService.instance
          .deleteList(list.id);

      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete list: $error',
          ),
        ),
      );
    }
  }

  Future<String?> _askForName({
    required String title,
    required String initialValue,
    required String buttonText,
  }) {
    String draftName =
        initialValue;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: Text(title),
            content: TextFormField(
              initialValue:
              initialValue,
              autofocus: true,
              maxLength: 80,
              textCapitalization:
              TextCapitalization.words,
              decoration:
              const InputDecoration(
                labelText: 'List name',
                hintText:
                'e.g. Weekly Groceries',
              ),
              onChanged: (value) {
                draftName = value;
              },
              onFieldSubmitted:
                  (value) {
                final clean =
                value.trim();

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
                  Navigator.pop(
                    dialogContext,
                  );
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
                child: Text(buttonText),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.instance.isLoggedIn) {
      return _buildGuestState();
    }

    return Scaffold(
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
          onPressed:
          _cancelSelection,
          icon: const Icon(
            Icons.close,
          ),
        )
            : null,
        title: Text(
          _selectionMode
              ? '${_selectedIds.length} selected'
              : 'My Shopping Lists',
        ),
        actions: _selectionMode
            ? [
          IconButton(
            onPressed:
            _selectAll,
            tooltip:
            'Select all',
            icon: Icon(
              _selectedIds.length ==
                  _lists.length
                  ? Icons
                  .deselect
                  : Icons
                  .select_all,
            ),
          ),
          IconButton(
            onPressed:
            _selectedIds.isEmpty
                ? null
                : _deleteSelected,
            tooltip:
            'Delete selected',
            icon: const Icon(
              Icons
                  .delete_outline,
            ),
          ),
        ]
            : [
          if (_lists.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  _selectionMode =
                  true;
                });
              },
              tooltip:
              'Select lists',
              icon: const Icon(
                Icons
                    .checklist_outlined,
              ),
            ),
          if (_lists.isNotEmpty)
            IconButton(
              onPressed:
              _clearAllLists,
              tooltip:
              'Clear all lists',
              icon: const Icon(
                Icons
                    .delete_sweep_outlined,
              ),
            ),
          IconButton(
            onPressed: _loading
                ? null
                : _load,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
      floatingActionButton:
      _selectionMode
          ? null
          : FloatingActionButton
          .extended(
        onPressed: _loading
            ? null
            : _createList,
        backgroundColor:
        Colors.green.shade700,
        foregroundColor:
        Colors.white,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'New List',
        ),
      ),
    );
  }

  Widget _buildGuestState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Shopping Lists',
        ),
      ),
      body: Center(
        child: Padding(
          padding:
          const EdgeInsets.all(28),
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
              const SizedBox(height: 16),
              Text(
                'Login to create shopping lists',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                  fontWeight:
                  FontWeight.bold,
                ),
                textAlign:
                TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Create separate lists such as Bakery Suppliers, Weekly Groceries or Party Shopping.',
                style: TextStyle(
                  color:
                  Colors.grey.shade600,
                ),
                textAlign:
                TextAlign.center,
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _login,
                icon:
                const Icon(Icons.login),
                label:
                const Text('Login'),
                style:
                FilledButton.styleFrom(
                  backgroundColor:
                  Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading &&
        _lists.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(
            child:
            CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_error != null &&
        _lists.isEmpty) {
      return ListView(
        padding:
        const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.cloud_off_outlined,
            size: 54,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign:
            TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(
            child:
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(
                Icons.refresh,
              ),
              label:
              const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (_lists.isEmpty) {
      return ListView(
        padding:
        const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 90),
          Center(
            child: Image.asset(
              'assets/images/grocery.png',
              width: 110,
              height: 110,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No shopping lists yet',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
              fontWeight:
              FontWeight.bold,
            ),
            textAlign:
            TextAlign.center,
          ),
          const SizedBox(height: 7),
          Text(
            'Tap New List to create your first personalised list.',
            style: TextStyle(
              color:
              Colors.grey.shade600,
            ),
            textAlign:
            TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      padding:
      const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        100,
      ),
      itemCount: _lists.length,
      separatorBuilder:
          (context, index) =>
      const SizedBox(
        height: 8,
      ),
      itemBuilder: (context, index) {
        final list =
        _lists[index];

        final selected =
        _selectedIds.contains(
          list.id,
        );

        return Card(
          color: selected
              ? Colors.green.shade50
              : null,
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            leading: _selectionMode
                ? Checkbox(
              value: selected,
              onChanged: (_) {
                _toggleSelection(
                  list.id,
                );
              },
            )
                : ClipRRect(
              borderRadius:
              BorderRadius.circular(
                10,
              ),
              child: Image.asset(
                'assets/images/grocery.png',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              list.name,
              style: const TextStyle(
                fontWeight:
                FontWeight.w700,
              ),
            ),
            subtitle: Padding(
              padding:
              const EdgeInsets.only(
                top: 4,
              ),
              child: Text(
                '${list.itemCount} item${list.itemCount == 1 ? '' : 's'} • ${_currency.format(list.estimatedTotal)}',
              ),
            ),
            trailing: _selectionMode
                ? null
                : PopupMenuButton<
                String>(
              onSelected:
                  (value) {
                if (value ==
                    'rename') {
                  _renameList(
                    list,
                  );
                }

                if (value ==
                    'delete') {
                  _deleteSingleList(
                    list,
                  );
                }
              },
              itemBuilder:
                  (menuContext) =>
              const [
                PopupMenuItem(
                  value:
                  'rename',
                  child: Text(
                    'Rename',
                  ),
                ),
                PopupMenuItem(
                  value:
                  'delete',
                  child: Text(
                    'Delete',
                  ),
                ),
              ],
            ),
            onLongPress: () {
              if (!_selectionMode) {
                _startSelection(
                  list.id,
                );
              }
            },
            onTap: () async {
              if (_selectionMode) {
                _toggleSelection(
                  list.id,
                );
                return;
              }

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ShoppingListDetailScreen(
                        listId:
                        list.id,
                        listName:
                        list.name,
                      ),
                ),
              );

              if (!mounted) {
                return;
              }

              await _load();
            },
          ),
        );
      },
    );
  }
}
