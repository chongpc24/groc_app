import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/product_repository.dart';
import 'search_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static const List<Color> _palette = [
    Color(0xFFDCEFE0), Color(0xFFF6E8D8), Color(0xFFF9DADA),
    Color(0xFFE6DFF3), Color(0xFFFDF3D0), Color(0xFFD8ECF6),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: FutureBuilder<List<Product>>(
        future: ProductRepository.loadAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data!;
          final categories = products.map((p) => p.category).toSet().toList();

          String imageForCategory(String category) =>
              products.firstWhere((p) => p.category == category).imagePath;

          return Padding(
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
                  child: GridView.builder(
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
                                  child: Image.asset(
                                    imageForCategory(category),
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported, size: 32),
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
          );
        },
      ),
    );
  }
}