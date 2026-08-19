import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

class SupabaseService {
  static const int _pageSize = 1000;

  static Future<int> syncFromSupabase() async {
    final client = Supabase.instance.client;
    final List<Map<String, dynamic>> localRows = [];

    int from = 0;
    while (true) {
      final page = await client
          .from('prices')
          .select(
        'item_code, price, date, store_name, premise_code, items(item_name, unit, category)',
      )
          .range(from, from + _pageSize - 1);

      final List data = page as List;
      if (data.isEmpty) break;

      for (final row in data) {
        final itemInfo = row['items'] as Map<String, dynamic>?;
        localRows.add({
          'itemCode': row['item_code'],
          'itemName': itemInfo?['item_name'] ?? 'Unknown item',
          'unit': itemInfo?['unit'] ?? '',
          'category': itemInfo?['category'] ?? 'Uncategorised',
          'premiseCode': row['premise_code'],
          'storeName': row['store_name'],
          'price': (row['price'] as num).toDouble(),
          'date': row['date'],
        });
      }

      if (data.length < _pageSize) break; // last page
      from += _pageSize;
    }

    await DatabaseService().replaceAll(localRows);
    return localRows.length;
  }
}
