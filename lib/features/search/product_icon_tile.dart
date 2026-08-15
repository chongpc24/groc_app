import 'package:flutter/material.dart';
import '../../models/product_icons.dart';

class ProductIconTile extends StatelessWidget {
  final String category;

  const ProductIconTile({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePathForProduct(category),
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
    );
  }
}