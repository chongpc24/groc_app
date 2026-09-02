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
  bool _loading = false;
  String? _error;

  final _currency = NumberFormat.currency(
    locale: 'ms_MY',
    symbol: 'RM ',
  );

  @override
  void initState() {
    super.initState();

    _subscription =
        AuthService.instance.authStateChanges.listen((_) {
          if (mounted) {
            _load();
          }
        });

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
      await ShoppingListService.instance.loadLists();

      if (mounted) {
        setState(() {
          _lists = lists;
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
    final loggedIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
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
      await ShoppingListService.instance.createList(
        name,
      );

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
      await ShoppingListService.instance.renameList(
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

  Future<void> _deleteList(
      ShoppingListSummary list,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
      await ShoppingListService.instance.deleteList(
        list.id,
      );

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
    String draftName = initialValue;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initialValue,
          autofocus: true,
          maxLength: 80,
          textCapitalization:
          TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'List name',
            hintText: 'e.g. Weekly Groceries',
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
              final clean = draftName.trim();

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
        title: const Text(
          'My Shopping Lists',
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        onPressed:
        _loading ? null : _createList,
        backgroundColor:
        Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New List'),
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
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border,
                size: 70,
                color:
                Colors.green.shade300,
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
    if (_loading && _lists.isEmpty) {
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
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
          const SizedBox(height: 110),
          Icon(
            Icons.playlist_add_outlined,
            size: 74,
            color: Colors.green.shade300,
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 7),
          Text(
            'Tap New List to create your first personalised list.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        100,
      ),
      itemCount: _lists.length,
      separatorBuilder:
          (context, index) =>
      const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final list = _lists[index];

        return Card(
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 7,
            ),
            leading: CircleAvatar(
              backgroundColor:
              Colors.green.shade50,
              child: Icon(
                Icons.shopping_bag_outlined,
                color:
                Colors.green.shade700,
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
            trailing:
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'rename') {
                  _renameList(list);
                }

                if (value == 'delete') {
                  _deleteList(list);
                }
              },
              itemBuilder:
                  (menuContext) =>
              const [
                PopupMenuItem(
                  value: 'rename',
                  child: Text('Rename'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ShoppingListDetailScreen(
                        listId: list.id,
                        listName: list.name,
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
