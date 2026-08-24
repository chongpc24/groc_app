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
  final myCurrency = NumberFormat('#,##0.00', 'ms_MY');

  @override
  void initState() {
    super.initState();
    _cartService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          // 清空购物车按钮
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

  /// 空购物车UI
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
              // 返回到搜索页面
              Navigator.pop(context);
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  /// 购物车内容
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
          // 显示每个店铺和其商品
          for (final premiseCode in storeList) ...[
            _buildStoreSection(context, premiseCode),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 80), // 底部留空，防止内容被底部栏遮挡
        ],
      ),
    );
  }

  /// 店铺分组卡片
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
          // 店铺头部
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
                // 删除整个店铺按钮
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _showRemoveStoreDialog(context, premiseCode);
                  },
                  tooltip: 'Remove this store',
                ),
              ],
            ),
          ),

          // 商品列表
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

          // 费用汇总
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSummaryRow(
                  'Subtotal:',
                  'RM ${myCurrency.format(subtotal)}',
                ),
                const SizedBox(height: 4),
                _buildSummaryRow(
                  'Delivery:',
                  deliveryFee == 0
                      ? 'FREE'
                      : 'RM ${myCurrency.format(deliveryFee)}',
                  isFree: deliveryFee == 0,
                ),
                const Divider(height: 12),
                _buildSummaryRow(
                  'Store Total:',
                  'RM ${myCurrency.format(storeTotal)}',
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 费用行
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

  /// 底部总价栏
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
                      'RM ${myCurrency.format(itemsSubtotal)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // 配送费提示
                if (totalDelivery > 0)
                  Chip(
                    label: Text(
                      'Delivery: RM ${myCurrency.format(totalDelivery)}',
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
                  'Checkout - RM ${myCurrency.format(grandTotal)}',
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

  /// 移除整个店铺的对话框
  void _showRemoveStoreDialog(BuildContext context, String premiseCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Store'),
        content: Text(
          'Remove all items from ${_cartService.getStoreInfo(premiseCode)?.storeName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 清空购物车的对话框
  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to clear your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _cartService.clearCart();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 结账的对话框
  void _showCheckoutDialog(BuildContext context, double total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout'),
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
                  'RM ${myCurrency.format(total)}',
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment processing... (TODO)'),
                  duration: Duration(seconds: 2),
                ),
              );
              // 这里以后可以连接支付功能
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }
}
