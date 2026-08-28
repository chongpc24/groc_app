//matchers.dart
//Known Malaysian grocery chains used to group Overpass results into
// filter chips (e.g. many stores are named "99 Speedmart Puchong Utama",
// we just want the "99 Speedmart" chip).
const List<String> knownBrands = [
  'AEON BiG',
  'AEON',
  'Lotus\'s',
  'Giant',
  'Mydin',
  'Econsave',
  'NSK',
  'Village Grocer',
  'Jaya Grocer',
  'Hero Market',
  '99 Speedmart',
  'KK Super Mart',
];

class BrandMatcher {
  /// Returns the known brand contained in [storeName], or the
  /// original name (trimmed) if no known brand matches.
  static String brandOf(String storeName) {
    final lower = storeName.toLowerCase();
    for (final brand in knownBrands) {
      if (lower.contains(brand.toLowerCase())) return brand;
    }
    return storeName;
  }
}

class NameMatcher {
  /// Normalizes a store name for comparison: uppercase, strip
  /// punctuation, collapse whitespace.
  static String _normalize(String input) {
    return input
        .toUpperCase()
        .replaceAll(RegExp(r"[^A-Z0-9 ]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Returns a similarity score between 0.0 and 1.0 based on
  /// shared words between the two names.
  static double _similarity(String a, String b) {
    final wordsA = _normalize(a).split(' ').toSet();
    final wordsB = _normalize(b).split(' ').toSet();

    if (wordsA.isEmpty || wordsB.isEmpty) return 0.0;

    final shared = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;

    return shared / union; // Jaccard similarity
  }

  /// Finds the best-matching premise for [osmName] from [candidates].
  /// Returns null if nothing scores above [threshold].
  static T? bestMatch<T>(
      String osmName,
      List<T> candidates,
      String Function(T) nameOf, {
        double threshold = 0.4,
      }) {
    T? best;
    double bestScore = 0.0;

    for (final c in candidates) {
      final score = _similarity(osmName, nameOf(c));
      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }

    return bestScore >= threshold ? best : null;
  }
}