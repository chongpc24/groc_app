//store_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/location_service.dart'; // LocationService + NominatimService + GeocodeResult
import '../../services/overpass_service.dart';
import '../../services/premise_repository.dart';
import '../../models/store.dart';
import 'matchers.dart'; // NameMatcher + BrandMatcher (feature-local helper)

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final LocationService _locationService = LocationService();
  final OverpassService _overpassService = OverpassService();
  final PremiseRepository _premiseRepository = PremiseRepository();
  final NominatimService _nominatimService = NominatimService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<Store> allStores = [];
  LatLng? userLatLng; // Wherever we're currently searching around —
  // either real GPS, a typed address, or a map tap.
  bool isLoading = false;
  bool isSearchingAddress = false;
  String? errorMessage;

  List<GeocodeResult> _addressResults = [];
  bool _pickOnMapMode = false;

  final Set<String> _selectedBrands = {};
  bool _filtersExpanded = false;
  bool _showAllStores = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => useCurrentLocation());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Store> get filteredStores {
    if (_selectedBrands.isEmpty) return allStores;
    return allStores
        .where((s) => _selectedBrands.contains(BrandMatcher.brandOf(s.name)))
        .toList();
  }

  List<String> get availableBrands {
    final brands = allStores.map((s) => BrandMatcher.brandOf(s.name)).toSet();
    return brands.toList()..sort();
  }

  /// Entry point used by GPS, address search, and map tap alike —
  /// they all just need to supply a LatLng to search around.
  Future<void> _findStoresAround(LatLng point) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      _selectedBrands.clear();
      _addressResults = [];
      _showAllStores = false;
    });

    try {
      final premises = await _premiseRepository.loadSupermarketPremises();
      debugPrint('[StorePage] premises loaded: ${premises.length}');

      final osmResults = await _overpassService.getNearbySupermarkets(
        point.latitude,
        point.longitude,
      );
      debugPrint('[StorePage] OSM results within 5km: ${osmResults.length}');

      final result = <Store>[];

      for (final osm in osmResults) {
        final tags = osm['tags'] ?? {};
        final osmName = (tags['name'] ?? '').toString();
        if (osmName.isEmpty) continue;

        final lat = (osm['lat'] ?? osm['center']?['lat'])?.toDouble();
        final lon = (osm['lon'] ?? osm['center']?['lon'])?.toDouble();
        if (lat == null || lon == null) continue;

        final osmLocationHint = [
          osmName,
          tags['branch'],
          tags['addr:suburb'],
          tags['addr:city'],
          tags['addr:district'],
        ]
            .where((value) => value != null && value.toString().trim().isNotEmpty)
            .map((value) => value.toString())
            .join(' ');

        final matched = NameMatcher.bestMatch(
          osmLocationHint,
          premises,
              (p) => '${p.premise} ${p.address} ${p.district}',
        );
        if (matched == null) continue;

        final distanceMeters = Geolocator.distanceBetween(
          point.latitude,
          point.longitude,
          lat,
          lon,
        );

        result.add(Store(
          name: matched.premise,
          latitude: lat,
          longitude: lon,
          distanceKm: distanceMeters / 1000,
          premiseCode: matched.premiseCode,
          address: matched.address,
          state: matched.state,
          district: matched.district,
        ));
      }

      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      debugPrint('[StorePage] matched to PriceCatcher: ${result.length}');

      setState(() {
        allStores = result;
        userLatLng = point;
        isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            _mapController.move(point, 15);
          } catch (_) {}
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> useCurrentLocation() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      _pickOnMapMode = false;
      _searchController.clear();
      _addressResults = [];
    });

    try {
      final position = await _locationService.getCurrentLocation();
      await _findStoresAround(LatLng(position.latitude, position.longitude));
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _searchAddress(String query) async {
    setState(() => isSearchingAddress = true);
    try {
      final results = await _nominatimService.searchAddress(query);
      setState(() {
        _addressResults = results;
        isSearchingAddress = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isSearchingAddress = false;
      });
    }
  }

  void _onAddressSelected(GeocodeResult result) {
    _pickOnMapMode = false;
    _findStoresAround(LatLng(result.latitude, result.longitude));
  }

  void _onMapTapped(LatLng point) {
    if (!_pickOnMapMode) return;
    _findStoresAround(point);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text(
          'Grocery Nearby',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (userLatLng != null) await _findStoresAround(userLatLng!);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ADDRESS SEARCH BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search an address, e.g. Shah Alam',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        suffixIcon: isSearchingAddress
                            ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                            : null,
                      ),
                      onSubmitted: (value) => _searchAddress(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: Icon(_pickOnMapMode ? Icons.close : Icons.map_outlined),
                    tooltip: _pickOnMapMode
                        ? 'Cancel pick-on-map'
                        : 'Pick location on map',
                    onPressed: () {
                      setState(() => _pickOnMapMode = !_pickOnMapMode);
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Use current location',
                    onPressed: isLoading ? null : useCurrentLocation,
                  ),
                ],
              ),
            ),

            if (_addressResults.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: _addressResults.map((result) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_outlined, size: 18),
                      title: Text(
                        result.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () => _onAddressSelected(result),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 8),

            // FILTER HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${filteredStores.length} stores found',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  IconButton(
                    icon: Icon(
                      _filtersExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() => _filtersExpanded = !_filtersExpanded);
                    },
                  ),
                ],
              ),
            ),

            if (_filtersExpanded && availableBrands.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableBrands.map((brand) {
                    final selected = _selectedBrands.contains(brand);
                    return ChoiceChip(
                      label: Text(brand),
                      selected: selected,
                      selectedColor: Colors.green.shade100,
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.green.shade800
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide.none,
                      ),
                      onSelected: (isSelected) {
                        setState(() {
                          if (isSelected) {
                            _selectedBrands.add(brand);
                          } else {
                            _selectedBrands.remove(brand);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 12),

            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : useCurrentLocation,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

            // MAP CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _pickOnMapMode
                          ? Colors.green.shade600
                          : Colors.grey.shade300,
                      width: _pickOnMapMode ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: userLatLng == null
                      ? Center(
                    child: Text(
                      isLoading
                          ? 'Loading map...'
                          : 'Map will appear after location is found.',
                      style: const TextStyle(color: Colors.black45),
                    ),
                  )
                      : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: userLatLng!,
                      initialZoom: 15,
                      onTap: (tapPosition, point) =>
                          _onMapTapped(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.groc',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: userLatLng!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.push_pin,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                          ...filteredStores.map(
                                (store) => Marker(
                              point: LatLng(
                                store.latitude,
                                store.longitude,
                              ),
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.storefront,
                                color: Colors.green.shade700,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            '© OpenStreetMap contributors',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (filteredStores.isEmpty && !isLoading && errorMessage == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No PriceCatcher-listed supermarkets found nearby.',
                  ),
                ),
              ),

            ...(_showAllStores ? filteredStores : filteredStores.take(5)).map(
                  (store) => Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.storefront,
                    color: Colors.green.shade700,
                  ),
                  title: Text(
                    store.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${store.distanceKm.toStringAsFixed(1)} km\n${store.address}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  onTap: () {
                    _mapController.move(
                      LatLng(store.latitude, store.longitude),
                      17,
                    );
                  },
                ),
              ),
            ),

            if (filteredStores.length > 5)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _showAllStores = !_showAllStores),
                    child: Text(_showAllStores
                        ? 'Show less'
                        : 'Show all ${filteredStores.length} stores'),
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}