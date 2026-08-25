import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../services/cart_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final CartService _cartService = CartService();
  final myCurrency = NumberFormat('MYR #,##0.00', 'ms_MY');
  late Future<List<Order>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _cartService.getOrderHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _cartService.getOrderHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: FutureBuilder<List<Order>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildOrderCard(orders[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No past orders yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed orders will show up here',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');

    return Card(
      child: ExpansionTile(
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.check_circle, color: Colors.green),
        ),
        title: Text(
          order.storeNames.join(', '),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${dateFormat.format(order.date)} · ${order.totalItemCount} items',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Text(
          myCurrency.format(order.total),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.itemName} x${item.quantity}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    myCurrency.format(item.itemSubtotal),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}