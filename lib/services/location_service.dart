import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  Future<Position> getCurrentLocation() async {
    final serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location service is disabled.',
      );
    }

    var permission =
    await Geolocator.checkPermission();

    if (permission ==
        LocationPermission.denied) {
      permission =
      await Geolocator.requestPermission();

      if (permission ==
          LocationPermission.denied) {
        throw Exception(
          'Location permission denied.',
        );
      }
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied.',
      );
    }

    return Geolocator.getCurrentPosition();
  }
}

class GeocodeResult {
  final String displayName;
  final double latitude;
  final double longitude;

  const GeocodeResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class NominatimService {
  Future<List<GeocodeResult>> searchAddress(
      String query,
      ) async {
    final clean = query.trim();

    if (clean.isEmpty) {
      return [];
    }

    final normalized =
    clean.toLowerCase();

    if (normalized == 'malaysia' ||
        normalized == 'malaysia, malaysia') {
      return const [
        GeocodeResult(
          displayName:
          'Kuala Lumpur, Malaysia',
          latitude: 3.1390,
          longitude: 101.6869,
        ),
        GeocodeResult(
          displayName:
          'Shah Alam, Selangor, Malaysia',
          latitude: 3.0738,
          longitude: 101.5183,
        ),
        GeocodeResult(
          displayName:
          'Ipoh, Perak, Malaysia',
          latitude: 4.5975,
          longitude: 101.0901,
        ),
        GeocodeResult(
          displayName:
          'George Town, Penang, Malaysia',
          latitude: 5.4141,
          longitude: 100.3288,
        ),
        GeocodeResult(
          displayName:
          'Johor Bahru, Johor, Malaysia',
          latitude: 1.4927,
          longitude: 103.7414,
        ),
        GeocodeResult(
          displayName:
          'Kota Kinabalu, Sabah, Malaysia',
          latitude: 5.9804,
          longitude: 116.0735,
        ),
        GeocodeResult(
          displayName:
          'Kuching, Sarawak, Malaysia',
          latitude: 1.5533,
          longitude: 110.3592,
        ),
      ];
    }

    final malaysiaQuery =
    normalized.contains('malaysia')
        ? clean
        : '$clean, Malaysia';

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(malaysiaQuery)}'
          '&format=json'
          '&limit=8'
          '&addressdetails=1'
          '&countrycodes=my',
    );

    final response = await http.get(
      url,
      headers: const {
        'User-Agent':
        'GROC-FlutterApp/1.0 student-project',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Address search failed: ${response.statusCode}',
      );
    }

    final List<dynamic> data =
    jsonDecode(response.body) as List<dynamic>;

    return data
        .map(
          (item) => GeocodeResult(
        displayName:
        item['display_name']
            ?.toString() ??
            '',
        latitude: double.parse(
          item['lat'].toString(),
        ),
        longitude: double.parse(
          item['lon'].toString(),
        ),
      ),
    )
        .toList();
  }
}
