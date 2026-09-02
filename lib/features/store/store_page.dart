import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/premise.dart';
import '../../models/store.dart';
import '../../services/location_service.dart';
import '../../services/overpass_service.dart';
import '../../services/premise_repository.dart';
import 'matchers.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() =>
      _StorePageState();
}

class _StorePageState
    extends State<StorePage> {
  final LocationService _locationService =
  LocationService();

  final OverpassService _overpassService =
  OverpassService();

  final PremiseRepository _premiseRepository =
  PremiseRepository();

  final NominatimService _nominatimService =
  NominatimService();

  final MapController _mapController =
  MapController();

  final TextEditingController _searchController =
  TextEditingController();

  List<Store> allStores = [];
  LatLng? userLatLng;

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

    WidgetsBinding.instance
        .addPostFrameCallback(
          (_) {
        useCurrentLocation();
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Store> get filteredStores {
    if (_selectedBrands.isEmpty) {
      return allStores;
    }

    return allStores
        .where(
          (store) =>
          _selectedBrands.contains(
            BrandMatcher.brandOf(
              store.name,
            ),
          ),
    )
        .toList();
  }

  List<String> get availableBrands {
    final brands =
    allStores
        .map(
          (store) =>
          BrandMatcher.brandOf(
            store.name,
          ),
    )
        .where(
          (brand) =>
      brand.trim().isNotEmpty,
    )
        .toSet()
        .toList()
      ..sort();

    return brands;
  }

  Future<void> _findStoresAround(
      LatLng point,
      ) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      _selectedBrands.clear();
      _addressResults = [];
      _showAllStores = false;
    });

    try {
      List<Premise> premises = [];

      try {
        premises =
        await _premiseRepository
            .loadSupermarketPremises();
      } catch (error) {
        debugPrint(
          'PriceCatcher premise load failed: $error',
        );
      }

      var osmResults =
      await _overpassService
          .getNearbySupermarkets(
        point.latitude,
        point.longitude,
        radiusMeters: 8000,
      );

      if (osmResults.isEmpty) {
        osmResults =
        await _overpassService
            .getNearbySupermarkets(
          point.latitude,
          point.longitude,
          radiusMeters: 20000,
        );
      }

      final result =
      <Store>[];

      final seen =
      <String>{};

      for (final osm
      in osmResults) {
        final tags =
        Map<String, dynamic>.from(
          (osm['tags'] as Map?) ??
              const {},
        );

        final osmName =
            tags['name']
                ?.toString()
                .trim() ??
                '';

        if (osmName.isEmpty) {
          continue;
        }

        final lat =
        _readCoordinate(
          osm['lat'] ??
              (osm['center']
              as Map?)?['lat'],
        );

        final lon =
        _readCoordinate(
          osm['lon'] ??
              (osm['center']
              as Map?)?['lon'],
        );

        if (lat == null ||
            lon == null) {
          continue;
        }

        final distanceMeters =
        Geolocator.distanceBetween(
          point.latitude,
          point.longitude,
          lat,
          lon,
        );

        final locationHint =
        _locationHint(tags);

        final matched =
        premises.isEmpty
            ? null
            : NameMatcher
            .bestMatchWithLocation<
            Premise>(
          osmName: osmName,
          locationHint:
          locationHint,
          candidates:
          premises,
          nameOf: (premise) =>
          premise.premise,
          locationOf:
              (premise) =>
          '${premise.address} ${premise.district} ${premise.state}',
        );

        final displayName =
        matched?.premise
            .trim()
            .isNotEmpty ==
            true
            ? matched!.premise
            : _osmDisplayName(
          osmName,
          tags,
        );

        final address =
        matched?.address
            .trim()
            .isNotEmpty ==
            true
            ? matched!.address
            : _osmAddress(tags);

        final key =
            '${displayName.toLowerCase()}|${lat.toStringAsFixed(5)}|${lon.toStringAsFixed(5)}';

        if (!seen.add(key)) {
          continue;
        }

        result.add(
          Store(
            name: displayName,
            latitude: lat,
            longitude: lon,
            distanceKm:
            distanceMeters /
                1000,
            premiseCode:
            matched?.premiseCode,
            address: address,
            state:
            matched?.state,
            district:
            matched?.district,
          ),
        );
      }

      result.sort(
            (a, b) => a.distanceKm
            .compareTo(
          b.distanceKm,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        allStores = result;
        userLatLng = point;
        isLoading = false;

        if (result.isEmpty) {
          errorMessage =
          'No supermarkets were returned near this point. Try a nearby city, postcode, current location, or tap another point on the map.';
        }
      });

      WidgetsBinding.instance
          .addPostFrameCallback(
            (_) {
          if (!mounted) {
            return;
          }

          try {
            _mapController.move(
              point,
              13,
            );
          } catch (error) {
            debugPrint(
              'Map move failed: $error',
            );
          }
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage =
            error.toString();
        isLoading = false;
      });
    }
  }

  double? _readCoordinate(
      dynamic value,
      ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  String _locationHint(
      Map<String, dynamic> tags,
      ) {
    final values = [
      tags['branch'],
      tags['addr:suburb'],
      tags['addr:city'],
      tags['addr:district'],
      tags['addr:state'],
      tags['addr:postcode'],
    ]
        .map(
          (value) =>
      value?.toString().trim() ??
          '',
    )
        .where(
          (value) => value.isNotEmpty,
    );

    return values.join(' ');
  }

  String _osmDisplayName(
      String osmName,
      Map<String, dynamic> tags,
      ) {
    final branch =
        tags['branch']
            ?.toString()
            .trim() ??
            '';

    if (branch.isEmpty ||
        osmName
            .toLowerCase()
            .contains(
          branch.toLowerCase(),
        )) {
      return osmName;
    }

    return '$osmName $branch';
  }

  String? _osmAddress(
      Map<String, dynamic> tags,
      ) {
    final parts = [
      tags['addr:housenumber'],
      tags['addr:street'],
      tags['addr:suburb'],
      tags['addr:city'],
      tags['addr:postcode'],
      tags['addr:state'],
    ]
        .map(
          (value) =>
      value?.toString().trim() ??
          '',
    )
        .where(
          (value) => value.isNotEmpty,
    )
        .toList();

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(', ');
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
      final position =
      await _locationService
          .getCurrentLocation();

      await _findStoresAround(
        LatLng(
          position.latitude,
          position.longitude,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage =
            error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _searchAddress(
      String query,
      ) async {
    final clean =
    query.trim();

    if (clean.isEmpty) {
      return;
    }

    setState(() {
      isSearchingAddress = true;
      errorMessage = null;
    });

    try {
      final results =
      await _nominatimService
          .searchAddress(clean);

      if (!mounted) {
        return;
      }

      setState(() {
        _addressResults =
            results;
        isSearchingAddress =
        false;

        if (results.isEmpty) {
          errorMessage =
          'No Malaysian location found. Try a city, postcode or neighbourhood.';
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage =
            error.toString();
        isSearchingAddress =
        false;
      });
    }
  }

  void _onAddressSelected(
      GeocodeResult result,
      ) {
    _pickOnMapMode = false;

    _searchController.text =
        result.displayName;

    _findStoresAround(
      LatLng(
        result.latitude,
        result.longitude,
      ),
    );
  }

  void _onMapTapped(
      LatLng point,
      ) {
    if (!_pickOnMapMode) {
      return;
    }

    _findStoresAround(point);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text(
          'Grocery Nearby',
          style: TextStyle(
            fontWeight:
            FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor:
        Colors.white,
        foregroundColor:
        Colors.black87,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (userLatLng != null) {
            await _findStoresAround(
              userLatLng!,
            );
          }
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                      _searchController,
                      decoration:
                      InputDecoration(
                        hintText:
                        'Search city, area, postcode or Malaysia',
                        prefixIcon:
                        const Icon(
                          Icons.search,
                          size: 20,
                        ),
                        filled: true,
                        fillColor:
                        Colors.white,
                        contentPadding:
                        const EdgeInsets
                            .symmetric(
                          vertical: 0,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            12,
                          ),
                          borderSide:
                          BorderSide(
                            color: Colors
                                .grey
                                .shade300,
                          ),
                        ),
                        suffixIcon:
                        isSearchingAddress
                            ? const Padding(
                          padding:
                          EdgeInsets
                              .all(
                            12,
                          ),
                          child:
                          SizedBox(
                            width: 16,
                            height: 16,
                            child:
                            CircularProgressIndicator(
                              strokeWidth:
                              2,
                            ),
                          ),
                        )
                            : null,
                      ),
                      onSubmitted:
                      _searchAddress,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: Icon(
                      _pickOnMapMode
                          ? Icons.close
                          : Icons
                          .map_outlined,
                    ),
                    tooltip: _pickOnMapMode
                        ? 'Cancel map selection'
                        : 'Pick location on map',
                    onPressed: () {
                      setState(() {
                        _pickOnMapMode =
                        !_pickOnMapMode;
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    icon: const Icon(
                      Icons.my_location,
                    ),
                    tooltip:
                    'Use current location',
                    onPressed: isLoading
                        ? null
                        : useCurrentLocation,
                  ),
                ],
              ),
            ),
            if (_searchController.text
                .trim()
                .toLowerCase() ==
                'malaysia')
              const Padding(
                padding:
                EdgeInsets.fromLTRB(
                  16,
                  6,
                  16,
                  0,
                ),
                child: Text(
                  'Malaysia is a country, so choose a city below to calculate nearby stores.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
            if (_addressResults.isNotEmpty)
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Card(
                  child: Column(
                    children:
                    _addressResults
                        .map(
                          (result) =>
                          ListTile(
                            dense: true,
                            leading:
                            const Icon(
                              Icons
                                  .place_outlined,
                              size: 20,
                            ),
                            title: Text(
                              result
                                  .displayName,
                              maxLines: 2,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                              style:
                              const TextStyle(
                                fontSize: 13,
                              ),
                            ),
                            onTap: () {
                              _onAddressSelected(
                                result,
                              );
                            },
                          ),
                    )
                        .toList(),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Row(
                children: [
                  Text(
                    '${filteredStores.length} stores found',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w600,
                      color:
                      Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      _filtersExpanded
                          ? Icons
                          .keyboard_arrow_up
                          : Icons
                          .keyboard_arrow_down,
                      color:
                      Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _filtersExpanded =
                        !_filtersExpanded;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (_filtersExpanded &&
                availableBrands.isNotEmpty)
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                  availableBrands
                      .map(
                        (brand) {
                      final selected =
                      _selectedBrands
                          .contains(
                        brand,
                      );

                      return FilterChip(
                        label:
                        Text(brand),
                        selected:
                        selected,
                        selectedColor:
                        Colors.green
                            .shade100,
                        backgroundColor:
                        Colors.grey
                            .shade200,
                        onSelected:
                            (isSelected) {
                          setState(() {
                            if (isSelected) {
                              _selectedBrands
                                  .add(
                                brand,
                              );
                            } else {
                              _selectedBrands
                                  .remove(
                                brand,
                              );
                            }
                          });
                        },
                      );
                    },
                  )
                      .toList(),
                ),
              ),
            const SizedBox(height: 12),
            if (errorMessage != null)
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Card(
                  color:
                  Colors.orange.shade50,
                  child: Padding(
                    padding:
                    const EdgeInsets.all(
                      12,
                    ),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Icon(
                          Icons
                              .info_outline,
                          color: Colors.orange
                              .shade800,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Text(
                            errorMessage!,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                child: Container(
                  height: 300,
                  decoration:
                  BoxDecoration(
                    border: Border.all(
                      color: _pickOnMapMode
                          ? Colors.green
                          .shade600
                          : Colors.grey
                          .shade300,
                      width:
                      _pickOnMapMode
                          ? 2
                          : 1,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: userLatLng ==
                      null
                      ? Center(
                    child: Text(
                      isLoading
                          ? 'Loading map...'
                          : 'Map will appear after a location is selected.',
                      style:
                      const TextStyle(
                        color:
                        Colors.black45,
                      ),
                    ),
                  )
                      : FlutterMap(
                    mapController:
                    _mapController,
                    options:
                    MapOptions(
                      initialCenter:
                      userLatLng!,
                      initialZoom:
                      13,
                      onTap:
                          (tapPosition,
                          point) {
                        _onMapTapped(
                          point,
                        );
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                        'com.example.groc',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point:
                            userLatLng!,
                            width: 40,
                            height: 40,
                            child:
                            const Icon(
                              Icons
                                  .push_pin,
                              color:
                              Colors.blue,
                              size: 30,
                            ),
                          ),
                          ...filteredStores
                              .map(
                                (store) =>
                                Marker(
                                  point:
                                  LatLng(
                                    store.latitude,
                                    store.longitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child:
                                  Icon(
                                    Icons
                                        .storefront,
                                    color: store
                                        .isLinkedToPriceCatcher
                                        ? Colors.green
                                        .shade700
                                        : Colors.orange
                                        .shade700,
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
            if (filteredStores.isEmpty &&
                !isLoading)
              const Padding(
                padding:
                EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No stores found for this exact point. Try selecting a nearby city or a different point on the map.',
                    textAlign:
                    TextAlign.center,
                  ),
                ),
              ),
            ...(_showAllStores
                ? filteredStores
                : filteredStores.take(
              5,
            ))
                .map(
                  (store) => Card(
                elevation: 0,
                color: Colors.white,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                  side: BorderSide(
                    color: Colors
                        .grey.shade200,
                  ),
                ),
                margin:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.storefront,
                    color: store
                        .isLinkedToPriceCatcher
                        ? Colors.green
                        .shade700
                        : Colors.orange
                        .shade700,
                  ),
                  title: Text(
                    store.name,
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        '${store.distanceKm.toStringAsFixed(1)} km',
                      ),
                      if ((store.address ?? '')
                          .trim()
                          .isNotEmpty)
                        Text(
                          store.address!,
                          maxLines: 2,
                          overflow:
                          TextOverflow
                              .ellipsis,
                        ),
                      Text(
                        store
                            .isLinkedToPriceCatcher
                            ? 'PriceCatcher matched'
                            : 'Nearby map store',
                        style:
                        TextStyle(
                          fontSize: 11,
                          color: store
                              .isLinkedToPriceCatcher
                              ? Colors.green
                              .shade700
                              : Colors.orange
                              .shade800,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    _mapController.move(
                      LatLng(
                        store.latitude,
                        store.longitude,
                      ),
                      17,
                    );
                  },
                ),
              ),
            ),
            if (filteredStores.length >
                5)
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllStores =
                        !_showAllStores;
                      });
                    },
                    child: Text(
                      _showAllStores
                          ? 'Show less'
                          : 'Show all ${filteredStores.length} stores',
                    ),
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
