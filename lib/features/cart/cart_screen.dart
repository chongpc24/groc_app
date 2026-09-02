import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/cart_cloud_service.dart';
import '../../services/cart_service.dart';
import '../../services/database_service.dart';
import '../../services/supabase_service.dart';
import '../account/login_screen.dart';
import '../account/my_details.dart';
import 'cart_item_tile.dart';
import 'order_history_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final NumberFormat myCurrency =
  NumberFormat('MYR #,##0.00', 'ms_MY');

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    if (!AuthService.instance.isLoggedIn) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    try {
      await _cartService.initialize();
      await CartCloudService.instance
          .restoreToLocalIfEmpty(_cartService);
      await _loadRegisteredAddress();
    } catch (error) {
      debugPrint('Cart initialization failed: $error');
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadRegisteredAddress() async {
    final user = AuthService.instance.currentUser;

    if (user == null) {
      return;
    }

    Map<String, dynamic>? profile;

    try {
      profile = await SupabaseService.instance.fetchMyProfile();
      await DatabaseService().upsertProfileCache(profile);
    } catch (error) {
      debugPrint('Cloud profile address load failed: $error');
      profile = await DatabaseService().getProfileCache(user.id);
    }

    final address = profile?['address']?.toString().trim() ?? '';

    if (address.isNotEmpty) {
      _cartService.setUserLocation(address);
    }
  }

  Future<void> _openMyDetailsForAddress() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const MyDetailsScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (changed == true) {
      await _loadRegisteredAddress();

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _syncCloud() async {
    if (!AuthService.instance.isLoggedIn) {
      return;
    }

    await CartCloudService.instance.safeSync(
      _cartService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = AuthService.instance.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (loggedIn)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Order history',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const OrderHistoryScreen(),
                  ),
                );
              },
            ),
          if (loggedIn &&
              !_cartService.cart.isEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
              ),
              tooltip: 'Clear cart',
              onPressed: _showClearCartDialog,
            ),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : !loggedIn
          ? _buildLoginRequired(context)
          : _cartService.cart.isEmpty
          ? _buildEmptyCart(context)
          : _buildCartContent(context),
      bottomNavigationBar:
      !loggedIn ||
          _loading ||
          _cartService.cart.isEmpty
          ? null
          : _buildBottomSummary(context),
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 90,
              height: 90,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            const Text(
              'Login required for cart',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can browse as a guest, but cart and order information are available only after login.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
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
                  setState(() {
                    _loading = true;
                  });
                  await _initializeCart();
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/grocery.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style:
            Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style:
            TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(
      BuildContext context,
      ) {
    final cart = _cartService.cart;
    final storeList = cart.storeList;

    final address =
    _cartService.userLocation.trim().isEmpty
        ? 'No delivery address set'
        : _cartService.userLocation;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadRegisteredAddress();
        await _syncCloud();

        if (mounted) {
          setState(() {});
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding:
                    EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery To:',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          address,
                          maxLines: 3,
                          overflow:
                          TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed:
                    _openMyDetailsForAddress,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final premiseCode
          in storeList) ...[
            _buildStoreSection(
              context,
              premiseCode,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStoreSection(
      BuildContext context,
      String premiseCode,
      ) {
    final cart = _cartService.cart;
    final storeItems =
    cart.getStoreItems(premiseCode);

    final storeName = storeItems.isNotEmpty
        ? storeItems.first.storeName
        : 'Store';

    final subtotal =
    cart.getStoreItemsSubtotal(
      premiseCode,
    );

    return Card(
      child: Column(
        children: [
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(
                  Icons.storefront,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    storeName,
                    style: const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                  ),
                  onPressed: () {
                    if (premiseCode.isNotEmpty) {
                      _showRemoveStoreDialog(
                        context,
                        premiseCode,
                        storeName,
                      );
                    }
                  },
                  tooltip: 'Remove this store',
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics:
            const NeverScrollableScrollPhysics(),
            itemCount: storeItems.length,
            separatorBuilder:
                (context, index) =>
            const Divider(height: 1),
            itemBuilder: (context, index) {
              final item =
              storeItems[index];

              return CartItemTile(
                item: item,
                onQuantityChanged:
                    (newQuantity) {
                  setState(() {
                    _cartService
                        .updateQuantity(
                      premiseCode,
                      item.itemCode,
                      newQuantity,
                    );
                  });

                  _syncCloud();
                },
                onRemove: () {
                  setState(() {
                    _cartService
                        .removeFromCart(
                      premiseCode,
                      item.itemCode,
                    );
                  });

                  _syncCloud();
                },
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.end,
              children: [
                _buildSummaryRow(
                  'Subtotal:',
                  myCurrency.format(
                    subtotal,
                  ),
                ),
                const SizedBox(height: 4),
                _buildSummaryRow(
                  'Delivery:',
                  'FREE',
                  isFree: true,
                ),
                const Divider(height: 12),
                _buildSummaryRow(
                  'Store Total:',
                  myCurrency.format(
                    subtotal,
                  ),
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      String value, {
        bool isBold = false,
        bool isFree = false,
      }) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold
                ? FontWeight.bold
                : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold
                ? FontWeight.bold
                : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
            color:
            isFree ? Colors.green : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSummary(
      BuildContext context,
      ) {
    final cart = _cartService.cart;
    final itemsSubtotal =
    cart.getItemsSubtotal();
    final grandTotal =
    cart.getGrandTotal();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cart.totalItemCount} items',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      myCurrency.format(
                        itemsSubtotal,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.green,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 14,
                  ),
                ),
                onPressed: () {
                  _showCheckoutDialog(
                    context,
                    grandTotal,
                  );
                },
                child: Text(
                  'Checkout - ${myCurrency.format(grandTotal)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveStoreDialog(
      BuildContext context,
      String premiseCode,
      String storeName,
      ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Text(
              'Remove Store',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
            content: Text(
              'Remove all items from $storeName?',
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
              TextButton(
                onPressed: () {
                  final items = _cartService
                      .cart
                      .getStoreItems(
                    premiseCode,
                  );

                  for (final item
                  in items.toList()) {
                    _cartService
                        .removeFromCart(
                      premiseCode,
                      item.itemCode,
                    );
                  }

                  Navigator.pop(
                    dialogContext,
                  );

                  if (mounted) {
                    setState(() {});
                  }

                  _syncCloud();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  void _showClearCartDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Text(
              'Clear Cart',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
            content: const Text(
              'Are you sure you want to clear your cart?',
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
              TextButton(
                onPressed: () {
                  _cartService.clearCart();

                  Navigator.pop(
                    dialogContext,
                  );

                  if (mounted) {
                    setState(() {});
                  }

                  _syncCloud();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  void _showCheckoutDialog(
      BuildContext context,
      double total,
      ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Text(
              'Checkout',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text('Order Summary:'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                    ),
                    Text(
                      myCurrency.format(total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Delivery address:',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _cartService.userLocation,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Proceed to payment?',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
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
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                  _processPayment();
                },
                child:
                const Text('Pay Now'),
              ),
            ],
          ),
    );
  }

  Future<void> _processPayment() async {
    if (!AuthService.instance.isLoggedIn) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Payment processing...',
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.black87,
      ),
    );

    try {
      await CartCloudService.instance
          .placeOrderFromLocal(
        _cartService,
      );

      await _cartService
          .saveOrderToHistory();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order could not be saved: $error',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _cartService.clearCart();

    if (mounted) {
      setState(() {});
    }

    if (!mounted) {
      return;
    }

    _showOrderPlacedDialog();
  }

  void _showOrderPlacedDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                Text(
                  'Order Placed!',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Your parcel is on the way!',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
