import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class OverpassService {
  static const List<String> _mirrors = [
    'https://overpass.kumi.systems/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
    'https://overpass-api.de/api/interpreter',
  ];

  Future<List<Map<String, dynamic>>>
  getNearbySupermarkets(
      double latitude,
      double longitude, {
        int radiusMeters = 8000,
      }) async {
    final query = '''
[out:json][timeout:30];
(
  nwr(around:$radiusMeters,$latitude,$longitude)["shop"="supermarket"];
  nwr(around:$radiusMeters,$latitude,$longitude)["shop"="convenience"];
);
out center tags;
''';

    Object? lastError;

    for (final mirror in _mirrors) {
      for (var attempt = 1;
      attempt <= 2;
      attempt++) {
        try {
          final response = await http
              .post(
            Uri.parse(mirror),
            headers: const {
              'Content-Type':
              'application/x-www-form-urlencoded',
              'Accept':
              'application/json',
              'User-Agent':
              'GROC-FlutterApp/1.0',
            },
            body: {
              'data': query,
            },
          )
              .timeout(
            const Duration(
              seconds: 25,
            ),
          );

          if (response.statusCode ==
              200) {
            final data =
            jsonDecode(
              response.body,
            ) as Map<String, dynamic>;

            final elements =
                data['elements']
                as List<dynamic>? ??
                    [];

            return elements
                .map(
                  (element) =>
              Map<String, dynamic>.from(
                element as Map,
              ),
            )
                .toList();
          }

          lastError = Exception(
            '$mirror returned ${response.statusCode}',
          );

          if (![502, 503, 504].contains(
            response.statusCode,
          )) {
            break;
          }

          if (attempt == 1) {
            await Future.delayed(
              const Duration(
                seconds: 2,
              ),
            );
          }
        } catch (error) {
          lastError = error;

          if (attempt == 1) {
            await Future.delayed(
              const Duration(
                seconds: 2,
              ),
            );
          }
        }
      }
    }

    throw Exception(
      'Nearby-store service is temporarily unavailable. Last error: $lastError',
    );
  }
}
