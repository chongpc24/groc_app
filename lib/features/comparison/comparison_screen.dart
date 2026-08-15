import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:groc/features/search/product_icon_tile.dart';
import '../../models/product.dart';
import '../../models/product_repository.dart';

class ComparisonScreen extends StatefulWidget {
  final String itemCode;
  final String itemName;

  const ComparisonScreen({super.key, required this.itemCode, required this.itemName});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  bool _showAll = false;

  List<Product> _latestPerStore(List<Product> matches) {
    final Map<String, Product> latest = {};
    for (final p in matches) {
      final existing = latest[p.premiseCode];
      if (existing == null || p.date.isAfter(existing.date)) {
        latest[p.premiseCode] = p;
      }
    }
    return latest.values.toList()..sort((a, b) => a.price.compareTo(b.price));
  }

  List<FlSpot> _cheapestPricePerDay(List<Product> matches) {
    final Map<DateTime, double> cheapestByDate = {};
    for (final p in matches) {
      final day = DateTime(p.date.year, p.date.month, p.date.day);
      final current = cheapestByDate[day];
      if (current == null || p.price < current) cheapestByDate[day] = p.price;
    }
    final sortedDates = cheapestByDate.keys.toList()..sort();
    if (sortedDates.isEmpty) return [];
    final firstDate = sortedDates.first;
    return sortedDates.map((date) {
      final dayOffset = date.difference(firstDate).inDays.toDouble();
      return FlSpot(dayOffset, cheapestByDate[date]!);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Save to List',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved to list (placeholder)')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Add to Cart',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to cart (placeholder)')),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: ProductRepository.loadAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final matches =
          snapshot.data!.where((p) => p.itemCode == widget.itemCode).toList();
          if (matches.isEmpty) return const Center(child: Text('No price data found.'));

          final storeList = _latestPerStore(matches);
          final trendSpots = _cheapestPricePerDay(matches);
          final visibleStores = _showAll ? storeList : storeList.take(5).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 150,
                    width: 150,
                    child: ProductIconTile(category: storeList.first.category),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.itemName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(storeList.first.unit,
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Text('Price Comparison', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...visibleStores.map((product) => ListTile(
                title: Text(product.storeName),
                trailing: Text('RM${product.price.toStringAsFixed(2)}'),
              )),
              if (storeList.length > 5)
                TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(_showAll
                      ? 'Show less'
                      : 'Show all ${storeList.length} stores'),
                ),
              const SizedBox(height: 24),
              Text('Monthly Price Trend', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              if (trendSpots.length < 2)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Not enough price history yet to show a trend.'),
                )
              else
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: const FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 24),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: trendSpots,
                          isCurved: true,
                          color: Colors.pinkAccent,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: Colors.pinkAccent.withOpacity(0.15)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}