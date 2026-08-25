import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cart.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import 'cart_item_tile.dart';
import 'order_history_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final myCurrency = NumberFormat('MYR #,##0.00', 'ms_MY');

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    await _cartService.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Order history',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          if (!_cartService.cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _showClearCartDialog();
              },
            ),
        ],
      ),
      body: _cartService.cart.isEmpty
          ? _buildEmptyCart(context)
          : _buildCartContent(context),
      bottomNavigationBar: _cartService.cart.isEmpty
          ? null
          : _buildBottomSummary(context),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context) {
    final cart = _cartService.cart;
    final storeList = cart.storeList;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery To:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(_cartService.userLocation),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _showChangeAddressDialog();
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          for (final premiseCode in storeList) ...[
            _buildStoreSection(context, premiseCode),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStoreSection(BuildContext context, String premiseCode) {
    final cart = _cartService.cart;
    final storeItems = cart.getStoreItems(premiseCode);
    final storeName = storeItems.isNotEmpty
        ? storeItems.first.storeName
        : 'Store';  // ✅
    final subtotal = cart.getStoreItemsSubtotal(premiseCode);

    return Card(
      child: Column(
        children: [
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.storefront, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    storeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    if (premiseCode.isNotEmpty) {
                      _showRemoveStoreDialog(context, premiseCode, storeName);
                    }
                  },
                  tooltip: 'Remove this store',
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: storeItems.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = storeItems[index];
              return CartItemTile(
                item: item,
                onQuantityChanged: (newQuantity) {
                  setState(() {
                    _cartService.updateQuantity(
                      premiseCode,
                      item.itemCode,
                      newQuantity,
                    );
                  });
                },
                onRemove: () {
                  setState(() {
                    _cartService.removeFromCart(premiseCode, item.itemCode);
                  });
                },
              );
            },
          ),

          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSummaryRow(
                  'Subtotal:',
                  '${myCurrency.format(subtotal)}',
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
                  '${myCurrency.format(subtotal)}',
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 16, // ✅ 改大了
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 28 : 18, // ✅ 改大了！28pt BOLD！
            color: isFree ? Colors.green : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSummary(BuildContext context) {
    final cart = _cartService.cart;
    final itemsSubtotal = cart.getItemsSubtotal();
    final grandTotal = cart.getGrandTotal();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cart.totalItemCount} items',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '${myCurrency.format(itemsSubtotal)}',
                      style: const TextStyle(
                        fontSize: 20, // ✅ 改大了！从18改成20
                        fontWeight: FontWeight.bold,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  _showCheckoutDialog(context, grandTotal);
                },
                child: Text(
                  'Checkout - ${myCurrency.format(grandTotal)}',
                  style: const TextStyle(
                    fontSize: 20, // ✅ 改大了！从16改成20
                    fontWeight: FontWeight.bold,
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

  void _showRemoveStoreDialog(BuildContext context, String premiseCode, String storeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Store',
          style: TextStyle(fontWeight: FontWeight.bold),),
        content: Text(
          'Remove all items from $storeName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
              style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          TextButton(
            onPressed: () {
              final items = _cartService.cart.getStoreItems(premiseCode);
              for (final item in items.toList()) {
                _cartService.removeFromCart(premiseCode, item.itemCode);
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart',
          style: TextStyle(fontWeight: FontWeight.bold),),
        content: const Text('Are you sure you want to clear your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          TextButton(
            onPressed: () {
              _cartService.clearCart();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showChangeAddressDialog() {
    final addressController = TextEditingController(
      text: _cartService.userLocation,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Delivery Address',
          style: TextStyle(fontWeight: FontWeight.bold),),
        content: TextField(
          controller: addressController,
          decoration: const InputDecoration(
            hintText: 'Enter your address',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          TextButton(
            onPressed: () {
              if (addressController.text.isNotEmpty) {
                _cartService.setUserLocation(addressController.text);
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context, double total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Summary:'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount:'),
                Text(
                  '${myCurrency.format(total)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Proceed to payment?',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processPayment();
            },
            child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold),),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment processing... '),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.black87,
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    await _cartService.saveOrderToHistory();
    _cartService.clearCart();
    setState(() {});

    if (!mounted) return;
    _showOrderPlacedDialog();
  }

  void _showOrderPlacedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.local_shipping, color: Colors.green),
            SizedBox(width: 8),
            Text('Order Placed!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Your parcel is on the way!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}