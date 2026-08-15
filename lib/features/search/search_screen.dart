import 'package:flutter/material.dart';
import 'package:groc/features/search/product_icon_tile.dart';
import '../../models/product.dart';
import '../comparison/comparison_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialCategory;

  const SearchScreen({super.key, this.initialCategory});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final products = await ProductRepository.loadAll();
    final base = widget.initialCategory == null
        ? products
        : products.where((p) => p.category == widget.initialCategory).toList();

    setState(() {
      _allProducts = base;
      _results = _groupByItem(base);
      _loading = false;
    });
  }

  List<Product> _groupByItem(List<Product> products) {
    final Map<String, Product> lowestPricePerItem = {};
    for (final product in products) {
      final existing = lowestPricePerItem[product.itemCode];
      if (existing == null || product.price < existing.price) {
        lowestPricePerItem[product.itemCode] = product;
      }
    }
    return lowestPricePerItem.values.toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      final filtered = _allProducts
          .where((product) =>
          product.itemName.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _results = _groupByItem(filtered);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Cart',
            onPressed: () {
              // TODO: navigate to teammate's Cart screen once it exists.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cart screen coming soon')),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search Products',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final product = _results[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComparisonScreen(
                          itemCode: product.itemCode,
                          itemName: product.itemName,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ProductIconTile(category: product.category),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.itemName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(product.unit,
                                      style: const TextStyle(color: Colors.grey)),
                                  const Icon(Icons.chevron_right,
                                      size: 22, color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}