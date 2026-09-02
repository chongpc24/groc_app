import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/cart_item.dart';
import '../search/product_icon_tile.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final myCurrency =
    NumberFormat(
      'MYR #,##0.00',
      'ms_MY',
    );

    final itemTotal =
        item.itemSubtotal;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
            BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: ProductIconTile(
                itemName: item.itemName,
                category: item.category,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (item.unit.trim().isNotEmpty)
                  Text(
                    item.unit,
                    style: TextStyle(
                      color:
                      Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${myCurrency.format(item.price)} each',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight:
                    FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                myCurrency.format(
                  itemTotal,
                ),
                style: const TextStyle(
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              _buildQuantityControl(),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[300]!,
        ),
        borderRadius:
        BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: item.quantity > 1
                ? () {
              onQuantityChanged(
                item.quantity - 1,
              );
            }
                : null,
            child: SizedBox(
              width: 28,
              height: 28,
              child: Icon(
                Icons.remove,
                size: 16,
                color: item.quantity > 1
                    ? Colors.black
                    : Colors.grey[400],
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                item.quantity.toString(),
                style: const TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              onQuantityChanged(
                item.quantity + 1,
              );
            },
            child: const SizedBox(
              width: 28,
              height: 28,
              child: Icon(
                Icons.add,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
