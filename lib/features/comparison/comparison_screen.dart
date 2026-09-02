import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/product.dart';
import '../../services/cart_cloud_service.dart';
import '../../services/cart_service.dart';
import '../account/auth_required.dart';
import '../search/product_icon_tile.dart';
import '../shopping_list/save_to_list_sheet.dart';

class ComparisonScreen extends StatefulWidget {
  final String itemCode;
  final String itemName;

  const ComparisonScreen({
    super.key,
    required this.itemCode,
    required this.itemName,
  });

  @override
  State<ComparisonScreen> createState() =>
      _ComparisonScreenState();
}

class _ComparisonScreenState
    extends State<ComparisonScreen> {
  bool _showAll = false;

  final myCurrency =
  NumberFormat(
    '#,##0.00',
    'ms_MY',
  );

  List<Product> _latestPerStore(
      List<Product> matches,
      ) {
    final Map<String, Product> latest =
    {};

    for (final product in matches) {
      final existing =
      latest[product.premiseCode];

      if (existing == null ||
          product.date
              .isAfter(existing.date)) {
        latest[product.premiseCode] =
            product;
      }
    }

    return latest.values.toList()
      ..sort(
            (a, b) =>
            a.price.compareTo(b.price),
      );
  }

  List<FlSpot> _cheapestPricePerDay(
      List<Product> matches,
      ) {
    final Map<DateTime, double>
    cheapestByDate = {};

    for (final product in matches) {
      final day = DateTime(
        product.date.year,
        product.date.month,
        product.date.day,
      );

      final current =
      cheapestByDate[day];

      if (current == null ||
          product.price < current) {
        cheapestByDate[day] =
            product.price;
      }
    }

    final sortedDates =
    cheapestByDate.keys.toList()
      ..sort();

    if (sortedDates.isEmpty) {
      return [];
    }

    final firstDate =
        sortedDates.first;

    return sortedDates.map((date) {
      final dayOffset = date
          .difference(firstDate)
          .inDays
          .toDouble();

      return FlSpot(
        dayOffset,
        cheapestByDate[date]!,
      );
    }).toList();
  }

  Future<void> _saveToList(
      BuildContext pageContext,
      ) async {
    final matches =
    await ProductRepository
        .byItemCode(
      widget.itemCode,
    );

    if (!pageContext.mounted) {
      return;
    }

    final storeList =
    _latestPerStore(matches);

    if (storeList.isEmpty) {
      ScaffoldMessenger.of(
        pageContext,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'No store is available for this item.',
          ),
        ),
      );
      return;
    }

    await SaveToListSheet.show(
      pageContext,
      storeList,
    );
  }

  void _showAddToCartDialog(
      BuildContext pageContext,
      List<Product> storeList,
      ) {
    showDialog<void>(
      context: pageContext,
      builder: (dialogContext) =>
          AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Choose Store',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount:
                storeList.length,
                separatorBuilder:
                    (context, index) =>
                const Divider(
                  height: 1,
                ),
                itemBuilder:
                    (context, index) {
                  final product =
                  storeList[index];

                  return ListTile(
                    leading: Icon(
                      Icons.storefront,
                      color:
                      Colors.green.shade700,
                    ),
                    title: Text(
                      product.storeName,
                    ),
                    subtitle: Text(
                      'RM ${myCurrency.format(product.price)}${index == 0 ? ' • Lowest price' : ''}',
                    ),
                    trailing: const Icon(
                      Icons
                          .add_shopping_cart,
                    ),
                    onTap: () async {
                      final cartService =
                      CartService();

                      cartService.addToCart(
                        itemCode:
                        product.itemCode,
                        itemName:
                        product.itemName,
                        premiseCode:
                        product
                            .premiseCode,
                        storeName:
                        product.storeName,
                        price: product.price,
                        unit: product.unit,
                        category:
                        product.category,
                        quantity: 1,
                      );

                      try {
                        await CartCloudService
                            .instance
                            .syncFromLocal(
                          cartService,
                        );
                      } catch (error) {
                        if (!dialogContext
                            .mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Unable to sync cart: $error',
                            ),
                          ),
                        );
                        return;
                      }

                      if (!dialogContext
                          .mounted) {
                        return;
                      }

                      final messenger =
                      ScaffoldMessenger.of(
                        pageContext,
                      );

                      Navigator.pop(
                        dialogContext,
                      );

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added to cart from ${product.storeName}.',
                          ),
                          duration:
                          const Duration(
                            seconds: 2,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _openAddToCart(
      BuildContext pageContext,
      ) async {
    final allowed =
    await AuthRequired.ensureLoggedIn(
      pageContext,
    );

    if (!pageContext.mounted ||
        !allowed) {
      return;
    }

    final matches =
    await ProductRepository
        .byItemCode(
      widget.itemCode,
    );

    if (!pageContext.mounted) {
      return;
    }

    final storeList =
    _latestPerStore(matches);

    if (storeList.isEmpty) {
      ScaffoldMessenger.of(
        pageContext,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'No store is available for this item.',
          ),
        ),
      );
      return;
    }

    _showAddToCartDialog(
      pageContext,
      storeList,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.favorite_border,
            ),
            tooltip:
            'Save to Shopping List',
            onPressed: () {
              _saveToList(context);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons
                  .shopping_cart_outlined,
            ),
            tooltip: 'Add to Cart',
            onPressed: () {
              _openAddToCart(context);
            },
          ),
        ],
      ),
      body:
      FutureBuilder<List<Product>>(
        future:
        ProductRepository.byItemCode(
          widget.itemCode,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          final matches =
          snapshot.data!;

          if (matches.isEmpty) {
            return const Center(
              child: Text(
                'No price data found.',
              ),
            );
          }

          final storeList =
          _latestPerStore(matches);

          final trendSpots =
          _cheapestPricePerDay(
            matches,
          );

          final visibleStores =
          _showAll
              ? storeList
              : storeList
              .take(5)
              .toList();

          return ListView(
            padding:
            const EdgeInsets.all(
              16,
            ),
            children: [
              Center(
                child: ClipRRect(
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                  child: SizedBox(
                    height: 150,
                    width: 150,
                    child:
                    ProductIconTile(
                      itemName:
                      widget.itemName,
                      category:
                      storeList
                          .first
                          .category,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.itemName,
                textAlign:
                TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                storeList.first.unit,
                textAlign:
                TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Price Comparison',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 8),
              ...visibleStores.asMap().entries.map(
                    (entry) {
                  final index =
                      entry.key;
                  final product =
                      entry.value;

                  return ListTile(
                    leading:
                    const Icon(
                      Icons.storefront,
                    ),
                    title: Text(
                      product.storeName,
                    ),
                    subtitle: index == 0
                        ? const Text(
                      'Lowest price',
                    )
                        : null,
                    trailing: Text(
                      'RM ${myCurrency.format(product.price)}',
                      style:
                      const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
              if (storeList.length > 5)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAll =
                      !_showAll;
                    });
                  },
                  child: Text(
                    _showAll
                        ? 'Show less'
                        : 'Show all ${storeList.length} stores',
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _saveToList(
                    context,
                  );
                },
                icon: const Icon(
                  Icons.favorite_border,
                ),
                label: const Text(
                  'Choose Store & Save to List',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  _openAddToCart(
                    context,
                  );
                },
                icon: const Icon(
                  Icons
                      .add_shopping_cart,
                ),
                label: const Text(
                  'Choose Store & Add to Cart',
                ),
                style:
                FilledButton.styleFrom(
                  backgroundColor:
                  Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Monthly Price Trend',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 24),
              if (trendSpots.length < 2)
                const Padding(
                  padding:
                  EdgeInsets.symmetric(
                    vertical: 24,
                  ),
                  child: Text(
                    'Not enough price history yet to show a trend.',
                  ),
                )
              else
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData:
                      const FlGridData(
                        show: true,
                      ),
                      titlesData:
                      const FlTitlesData(
                        rightTitles:
                        AxisTitles(
                          sideTitles:
                          SideTitles(
                            showTitles:
                            false,
                          ),
                        ),
                        topTitles:
                        AxisTitles(
                          sideTitles:
                          SideTitles(
                            showTitles:
                            false,
                          ),
                        ),
                        bottomTitles:
                        AxisTitles(
                          sideTitles:
                          SideTitles(
                            showTitles:
                            true,
                            reservedSize:
                            25,
                          ),
                        ),
                        leftTitles:
                        AxisTitles(
                          sideTitles:
                          SideTitles(
                            showTitles:
                            true,
                            reservedSize:
                            45,
                          ),
                        ),
                      ),
                      borderData:
                      FlBorderData(
                        show: true,
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots:
                          trendSpots,
                          isCurved: true,
                          color: Colors
                              .pinkAccent,
                          barWidth: 3,
                          dotData:
                          const FlDotData(
                            show: false,
                          ),
                          belowBarData:
                          BarAreaData(
                            show: true,
                            color: Colors
                                .pinkAccent
                                .withValues(
                              alpha: 0.15,
                            ),
                          ),
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
