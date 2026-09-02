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
  static String brandOf(
      String storeName,
      ) {
    final lower =
    storeName.toLowerCase();

    for (final brand
    in knownBrands) {
      if (lower.contains(
        brand.toLowerCase(),
      )) {
        return brand;
      }
    }

    return storeName.trim();
  }
}

class NameMatcher {
  static String _normalize(
      String input,
      ) {
    return input
        .toUpperCase()
        .replaceAll(
      RegExp(r'[^A-Z0-9 ]'),
      ' ',
    )
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    )
        .trim();
  }

  static Set<String> _words(
      String input,
      ) {
    final normalized =
    _normalize(input);

    if (normalized.isEmpty) {
      return {};
    }

    return normalized
        .split(' ')
        .where(
          (word) =>
      word.trim().isNotEmpty,
    )
        .toSet();
  }

  static double _similarity(
      String a,
      String b,
      ) {
    final wordsA = _words(a);
    final wordsB = _words(b);

    if (wordsA.isEmpty ||
        wordsB.isEmpty) {
      return 0;
    }

    final shared =
        wordsA.intersection(
          wordsB,
        ).length;

    final union =
        wordsA.union(
          wordsB,
        ).length;

    var score =
        shared / union;

    final normalizedA =
    _normalize(a);

    final normalizedB =
    _normalize(b);

    if (normalizedA.isNotEmpty &&
        normalizedB.isNotEmpty &&
        (normalizedA.contains(
          normalizedB,
        ) ||
            normalizedB.contains(
              normalizedA,
            ))) {
      if (score < 0.65) {
        score = 0.65;
      }
    }

    return score;
  }

  static T? bestMatch<T>(
      String osmName,
      List<T> candidates,
      String Function(T) nameOf, {
        double threshold = 0.4,
      }) {
    T? best;
    var bestScore = 0.0;

    for (final candidate
    in candidates) {
      final score =
      _similarity(
        osmName,
        nameOf(candidate),
      );

      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return bestScore >= threshold
        ? best
        : null;
  }

  static T? bestMatchWithLocation<T>({
    required String osmName,
    required String locationHint,
    required List<T> candidates,
    required String Function(T) nameOf,
    required String Function(T)
    locationOf,
    double minimumNameScore = 0.22,
  }) {
    T? best;
    var bestCombinedScore = 0.0;

    for (final candidate
    in candidates) {
      final nameScore =
      _similarity(
        osmName,
        nameOf(candidate),
      );

      if (nameScore <
          minimumNameScore) {
        continue;
      }

      final locationScore =
      locationHint.trim().isEmpty
          ? 0.0
          : _similarity(
        locationHint,
        locationOf(candidate),
      );

      final combinedScore =
          (nameScore * 0.78) +
              (locationScore * 0.22);

      if (combinedScore >
          bestCombinedScore) {
        bestCombinedScore =
            combinedScore;
        best = candidate;
      }
    }

    return best;
  }
}
