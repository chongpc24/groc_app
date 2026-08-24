import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cart_item.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final myCurrency = NumberFormat('MYR #,##0.00', 'ms_MY');
    final itemTotal = item.itemSubtotal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 商品图标（简单方形）
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: Colors.green[300],
            ),
          ),
          const SizedBox(width: 12),

          // 商品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.storeName} - ${item.itemName}',  // ← 加店铺名称！
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  item.unit,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RM ${myCurrency.format(item.price)} each',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // 数量和总价
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${myCurrency.format(itemTotal)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              // 数量控制
              _buildQuantityControl(),
            ],
          ),
        ],
      ),
    );
  }

  /// 数量控制器（-、数量、+）
  Widget _buildQuantityControl() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 减号
          GestureDetector(
            onTap: item.quantity > 1
                ? () => onQuantityChanged(item.quantity - 1)
                : null,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: Icon(
                Icons.remove,
                size: 16,
                color: item.quantity > 1 ? Colors.black : Colors.grey[400],
              ),
            ),
          ),
          // 数量
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              item.quantity.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // 加号
          GestureDetector(
            onTap: () => onQuantityChanged(item.quantity + 1),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: const Icon(Icons.add, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
