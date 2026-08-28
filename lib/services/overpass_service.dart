//overpass_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class OverpassService {
  static const List<String> _mirrors = [
    'https://overpass.kumi.systems/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
    'https://overpass-api.de/api/interpreter',
  ];

  Future<List<Map<String, dynamic>>> getNearbySupermarkets(
      double latitude,
      double longitude,
      ) async {
    final query = '''
[out:json][timeout:25];
nwr(
  around:5000,
  $latitude,
  $longitude
)[shop=supermarket];
out center;
''';

    Object? lastError;

    for (final mirror in _mirrors) {
      // Try each mirror up to 2 times before moving to the next one —
      // a 502/503/504 is often transient and succeeds on retry.
      for (var attempt = 1; attempt <= 2; attempt++) {
        try {
          final response = await http
              .post(
            Uri.parse(mirror),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
              'User-Agent': 'PriceWiseMY-FlutterApp/1.0',
            },
            body: {'data': query},
          )
              .timeout(const Duration(seconds: 20));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return List<Map<String, dynamic>>.from(data['elements']);
          }

          lastError = Exception('$mirror returned ${response.statusCode}');

          // 502/503/504 = server overloaded, worth a short retry.
          // Other codes (400, 429) — no point retrying same mirror.
          if (![502, 503, 504].contains(response.statusCode)) break;

          if (attempt == 1) {
            await Future.delayed(const Duration(seconds: 2));
          }
        } catch (e) {
          lastError = e;
          if (attempt == 1) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }
    }

    throw Exception(
      'All Overpass mirrors are currently unavailable. '
          'This is a public server issue, not your app — please retry. '
          '(Last error: $lastError)',
    );
  }
}