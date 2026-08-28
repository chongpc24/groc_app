//premise_respository.dart
import '../models/premise.dart';
import 'premise_database_service.dart';
import 'premise_supabase_service.dart';

class PremiseRepository {
  final PremiseDatabaseService _dbService = PremiseDatabaseService();

  List<Premise>? _cache;

  Future<bool> hasLocalData() async => (await _dbService.rowCount()) > 0;

  /// Pulls the premises table from Supabase and refreshes the local cache.
  Future<int> sync() => PremiseSupabaseService.syncFromSupabase();

  Future<List<Premise>> loadSupermarketPremises() async {
    if (_cache != null) return _cache!;

    if (!await hasLocalData()) {
      await sync();
    }

    final rows = await _dbService.getAll();
    final premises = rows.map((r) => Premise.fromMap(r)).toList();

    _cache = premises;
    return premises;
  }
}