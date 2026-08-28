//store.dart
class Store {
  final String name;          // Display name (from OSM)
  final double latitude;
  final double longitude;
  final double distanceKm;

  // Nullable — only present if we matched this to a PriceCatcher premise.
  final int? premiseCode;
  final String? address;
  final String? state;
  final String? district;

  bool get isLinkedToPriceCatcher => premiseCode != null;

  Store({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.premiseCode,
    this.address,
    this.state,
    this.district,
  });
}