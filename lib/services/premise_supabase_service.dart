//premise_supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import 'premise_database_service.dart';

/// Pulls the 'premises' table from Supabase and caches it into the
/// local premises.db. Mirrors the shape of the team's
/// SupabaseService/DatabaseService pair, but kept entirely separate
/// so it never touches their files or the 'items'/'prices' tables.
class PremiseSupabaseService {
  static const int _pageSize = 1000;

  static Future<int> syncFromSupabase() async {
    final client = Supabase.instance.client;
    final List<Map<String, dynamic>> localRows = [];

    int from = 0;
    while (true) {
      final page = await client
          .from('premises')
          .select('premise_code, premise, address, premise_type, state, district')
          .range(from, from + _pageSize - 1);

      final List data = page as List;
      if (data.isEmpty) break;

      for (final row in data) {
        localRows.add({
          'premiseCode': row['premise_code'] as int,
          'premise': row['premise'] ?? '',
          'address': row['address'] ?? '',
          'premiseType': row['premise_type'] ?? '',
          'state': row['state'] ?? '',
          'district': row['district'] ?? '',
        });
      }

      if (data.length < _pageSize) break; // last page
      from += _pageSize;
    }

    await PremiseDatabaseService().replaceAll(localRows);
    return localRows.length;
  }
}