import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cart.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import 'cart_item_tile.dart';

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
          if (!_cartService.cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                if (!_cartService.cart.isEmpty) {  // ← 加检查！
                  _showClearCartDialog();
                }
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
                      // 以后可以让用户改地址
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
    final storeInfo = _cartService.getStoreInfo(premiseCode);
    final subtotal = cart.getStoreItemsSubtotal(premiseCode);
    final deliveryFee = cart.getStoreDeliveryFee(premiseCode);
    final storeTotal = cart.getStoreTotal(premiseCode);

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeInfo?.storeName ?? 'Store',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${storeInfo?.distance ?? 0} km away',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    if (premiseCode.isNotEmpty) {
                      _showRemoveStoreDialog(context, premiseCode);
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
                  _cartService.removeFromCart(premiseCode, item.itemCode);
                  setState(() {});
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
                  deliveryFee == 0
                      ? 'FREE'
                      : '${myCurrency.format(deliveryFee)}',
                  isFree: deliveryFee == 0,
                ),
                const Divider(height: 12),
                _buildSummaryRow(
                  'Store Total:',
                  '${myCurrency.format(storeTotal)}',
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
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isFree ? Colors.green : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSummary(BuildContext context) {
    final cart = _cartService.cart;
    final itemsSubtotal = cart.getItemsSubtotal();
    final totalDelivery = cart.getTotalDeliveryFee();
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (totalDelivery > 0)
                  Chip(
                    label: Text(
                      'Delivery: ${myCurrency.format(totalDelivery)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.orange[50],
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
                    fontSize: 16,
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

  void _showRemoveStoreDialog(BuildContext context, String premiseCode) {
    final storeInfo = _cartService.getStoreInfo(premiseCode);
    final storeName = storeInfo?.storeName ?? 'Unknown Store';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Store',
          style: TextStyle(fontWeight: FontWeight.bold),),
        content: Text(
          'Remove all items from ${_cartService.getStoreInfo(premiseCode)?.storeName}?',
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment processing... '),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold),),
          ),
        ],
      ),
    );
  }
}
