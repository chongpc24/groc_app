import 'package:flutter/material.dart';
import 'package:groc/features/search/product_icon_tile.dart';
import '../../models/product.dart';
import 'search_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const List<Color> _palette = [
    Color(0xFFDCEFE0), Color(0xFFF6E8D8), Color(0xFFF9DADA),
    Color(0xFFE6DFF3), Color(0xFFFDF3D0), Color(0xFFD8ECF6),
  ];

  late Future<List<String>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ProductRepository.getCategories();
  }

  Future<void> _refresh() async {
    await ProductRepository.sync(); // re-pull latest prices from Supabase
    setState(() {
      _categoriesFuture = ProductRepository.getCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
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
      body: FutureBuilder<List<String>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    readOnly: true,
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const SearchScreen()));
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search Products',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: categories.isEmpty
                        ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No data yet — pull down to sync')),
                      ],
                    )
                        : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final color = _palette[index % _palette.length];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SearchScreen(initialCategory: category),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ProductIconTile(
                                      itemName: category,
                                      category: category,
                                      isCategoryTile: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(category,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
