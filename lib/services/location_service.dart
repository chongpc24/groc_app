//location_service.dart
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location service is disabled.');
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }
}

class GeocodeResult {
  final String displayName;
  final double latitude;
  final double longitude;

  GeocodeResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class NominatimService {
  Future<List<GeocodeResult>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}'
          '&format=json'
          '&limit=5'
          '&countrycodes=my', // bias results to Malaysia
    );

    final response = await http.get(
      url,
      headers: {
        // Nominatim's usage policy requires a real User-Agent identifying
        // your app — requests without one may be blocked.
        'User-Agent': 'PriceWiseMY-FlutterApp/1.0 (student project)',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Address search failed: ${response.statusCode}');
    }

    final List data = jsonDecode(response.body);

    return data.map((item) {
      return GeocodeResult(
        displayName: item['display_name'] ?? '',
        latitude: double.parse(item['lat']),
        longitude: double.parse(item['lon']),
      );
    }).toList();
  }
}