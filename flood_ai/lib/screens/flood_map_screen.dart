import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as gplaces;
import 'package:http/http.dart' as http;

import '../services/flood_zone_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class FloodMapScreen extends StatefulWidget {
  const FloodMapScreen({super.key});

  @override
  State<FloodMapScreen> createState() => _FloodMapScreenState();
}

class _FloodMapScreenState extends State<FloodMapScreen> {
  GoogleMapController? _mapController;

  LatLng? _userLocation;
  LatLng? _origin;
  LatLng? _destination;

  Marker? _selectedMarker;
  bool _showRouteButton = false;

  Set<Polyline> _polylines = {};
  Set<Polygon> _floodPolygons = {};
  Set<Polygon> _gridSquares = {};
  Set<Polygon> _riskFloodPolygons = {};

  String? _routeInfo;

  bool _loadingFloodZones = false;
  double _currentZoom = 13.0;

  bool _showMLGrids = true;
  bool _showFloodPolygons = true;
  bool _showRiskFloodOverlay = false;

  bool _gridTapped = false;

  final gplaces.FlutterGooglePlacesSdk places =
      gplaces.FlutterGooglePlacesSdk(
    dotenv.env['GOOGLE_MAPS_KEY']!,
  );

  final TextEditingController _searchController = TextEditingController();
  List<gplaces.AutocompletePrediction> _predictions = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _userLocation = LatLng(pos.latitude, pos.longitude);
      _origin = _userLocation;
    });
  }

  Future<void> _loadFloodZonesForVisibleArea() async {
    if (_mapController == null || _loadingFloodZones) return;

    if (_currentZoom < 12) {
      if (_floodPolygons.isNotEmpty) {
        setState(() {
          _floodPolygons.clear();
          _riskFloodPolygons.clear();
        });
      }
      return;
    }

    _loadingFloodZones = true;

    try {
      final bounds = await _mapController!.getVisibleRegion();
      final polygons =
          await FloodZoneService.fetchFloodPolygons(bounds: bounds);

      setState(() {
        _floodPolygons = polygons.toSet();
      });

      if (_showRiskFloodOverlay) {
        _buildRiskFloodOverlay();
      }
    } catch (e) {
      debugPrint('❌ Flood polygon error: $e');
    } finally {
      _loadingFloodZones = false;
    }
  }

  Future<void> _loadGridPredictions() async {
    try {
      final uri = Uri.parse(
        '${dotenv.env['API_BASE_URL']}/flood-prediction/predict-all-grids',
      );
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        debugPrint('❌ ML API error ${response.statusCode}');
        return;
      }

      _buildSquaresFromResponse(response.body);
    } catch (e) {
      debugPrint('❌ Grid prediction error: $e');
    }
  }

  Future<void> _runDevPrediction(
      String daily, String rain3, String rain5, String rain7) async {
    try {
      final uri = Uri.parse(
        '${dotenv.env['API_BASE_URL']}/flood-prediction/predict-dev',
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "daily": double.parse(daily),
          "rain_3": double.parse(rain3),
          "rain_5": double.parse(rain5),
          "rain_7": double.parse(rain7),
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("❌ Dev prediction error");
        return;
      }

      _buildSquaresFromResponse(response.body);
    } catch (e) {
      debugPrint("❌ Dev mode error: $e");
    }
  }

  void _buildSquaresFromResponse(String body) {
    final List data = json.decode(body);
    final Set<Polygon> squares = {};

    for (final grid in data) {
      final double lat = (grid['lat'] as num).toDouble();
      final double lon = (grid['lon'] as num).toDouble();
      final String alert = grid['alert'];

      Color color;
      if (alert == 'RED') {
        color = Colors.red.withOpacity(0.45);
      } else if (alert == 'YELLOW') {
        color = Colors.orange.withOpacity(0.45);
      } else {
        color = Colors.green.withOpacity(0.45);
      }

      const double halfSizeDeg = 0.125;

      final points = <LatLng>[
        LatLng(lat + halfSizeDeg, lon - halfSizeDeg),
        LatLng(lat + halfSizeDeg, lon + halfSizeDeg),
        LatLng(lat - halfSizeDeg, lon + halfSizeDeg),
        LatLng(lat - halfSizeDeg, lon - halfSizeDeg),
      ];

      squares.add(
        Polygon(
          polygonId: PolygonId('grid_${lat}_$lon'),
          points: points,
          fillColor: color,
          strokeColor: Colors.black26,
          strokeWidth: 1,
          consumeTapEvents: true,
          onTap: () {
            _gridTapped = true;
            final latStr = lat.toStringAsFixed(4);
            final lonStr = lon.toStringAsFixed(4);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Grid Center\nLat: $latStr, Lon: $lonStr'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      );
    }

    setState(() {
      _gridSquares = squares;
    });

    if (_showRiskFloodOverlay) {
      _buildRiskFloodOverlay();
    }
  }

  void _buildRiskFloodOverlay() {
    final Set<Polygon> result = {};

    for (final floodPolygon in _floodPolygons) {
      Color? polygonColor;

      for (final grid in _gridSquares) {
        final intersects = _polygonIntersectsGrid(
          floodPolygon.points,
          grid.points,
        );

        if (!intersects) continue;

        final gridColor = grid.fillColor;

        if (gridColor.red > 200 && gridColor.green < 100) {
          polygonColor = Colors.red.withOpacity(0.5);
          break;
        }

        if (gridColor.green > 100 &&
            gridColor.red > 200 &&
            polygonColor == null) {
          polygonColor = Colors.orange.withOpacity(0.5);
        }
      }

      if (polygonColor != null) {
        result.add(
          Polygon(
            polygonId:
                PolygonId('risk_${floodPolygon.polygonId.value}'),
            points: floodPolygon.points,
            fillColor: polygonColor,
            strokeColor: polygonColor,
            strokeWidth: 2,
          ),
        );
      }
    }

    setState(() {
      _riskFloodPolygons = result;
    });
  }

  bool _polygonIntersectsGrid(
    List<LatLng> polygonPoints,
    List<LatLng> gridPoints,
  ) {
    final polyLats = polygonPoints.map((p) => p.latitude);
    final polyLngs = polygonPoints.map((p) => p.longitude);
    final gridLats = gridPoints.map((p) => p.latitude);
    final gridLngs = gridPoints.map((p) => p.longitude);

    final double polyMinLat = polyLats.reduce((a, b) => a < b ? a : b);
    final double polyMaxLat = polyLats.reduce((a, b) => a > b ? a : b);
    final double polyMinLng = polyLngs.reduce((a, b) => a < b ? a : b);
    final double polyMaxLng = polyLngs.reduce((a, b) => a > b ? a : b);

    final double gridMinLat = gridLats.reduce((a, b) => a < b ? a : b);
    final double gridMaxLat = gridLats.reduce((a, b) => a > b ? a : b);
    final double gridMinLng = gridLngs.reduce((a, b) => a < b ? a : b);
    final double gridMaxLng = gridLngs.reduce((a, b) => a > b ? a : b);

    return !(polyMaxLat < gridMinLat ||
        polyMinLat > gridMaxLat ||
        polyMaxLng < gridMinLng ||
        polyMinLng > gridMaxLng);
  }

  void _openDevDialog() {
    final dailyController = TextEditingController();
    final rain3Controller = TextEditingController();
    final rain5Controller = TextEditingController();
    final rain7Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Dev Rainfall Input"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: dailyController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: "Daily"),
                ),
                TextField(
                  controller: rain3Controller,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: "Rain 3 Day"),
                ),
                TextField(
                  controller: rain5Controller,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: "Rain 5 Day"),
                ),
                TextField(
                  controller: rain7Controller,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: "Rain 7 Day"),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text("Run Prediction"),
              onPressed: () {
                Navigator.pop(context);
                _runDevPrediction(
                  dailyController.text,
                  rain3Controller.text,
                  rain5Controller.text,
                  rain7Controller.text,
                );
              },
            )
          ],
        );
      },
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().length < 2) {
      setState(() => _predictions = []);
      return;
    }

    final response = await places.findAutocompletePredictions(
      query,
      countries: ['IN'],
    );

    setState(() {
      _predictions = response.predictions;
    });
  }

  Future<void> _selectPlace(String placeId) async {
    final details = await places.fetchPlace(
      placeId,
      fields: [gplaces.PlaceField.Location],
    );

    if (details.place == null) return;

    final loc = details.place!.latLng!;
    final point = LatLng(loc.lat, loc.lng);

    setState(() {
      _destination = point;
      _selectedMarker = Marker(
        markerId: const MarkerId('destination'),
        position: point,
      );
      _predictions = [];
      _searchController.clear();
      _polylines.clear();
      _routeInfo = null;
      _showRouteButton = true;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(point, 16),
    );
  }

  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    final googleKey = dotenv.env['GOOGLE_MAPS_KEY'];

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=driving'
      '&key=$googleKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return;

    final data = json.decode(response.body);
    if (data['routes'].isEmpty) return;

    final leg = data['routes'][0]['legs'][0];
    final polyline = data['routes'][0]['overview_polyline']['points'];
    final points = _decodePolyline(polyline);

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: points,
        ),
      };
      _routeInfo =
          '${leg['distance']['text']} • ${leg['duration']['text']}';
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    if (_userLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allPolygons = <Polygon>{
      if (_showFloodPolygons) ..._floodPolygons,
      if (_showMLGrids) ..._gridSquares,
      if (_showRiskFloodOverlay) ..._riskFloodPolygons,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Flood Risk Map')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(10.2, 76.3),
              zoom: 7,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: {if (_selectedMarker != null) _selectedMarker!},
            polylines: _polylines,
            polygons: allPolygons,
            onMapCreated: (controller) {
              _mapController = controller;
              _loadGridPredictions();
            },
            onCameraMove: (pos) => _currentZoom = pos.zoom,
            onCameraIdle: _loadFloodZonesForVisibleArea,
            onTap: (latLng) {
              if (_gridTapped) {
                _gridTapped = false;
                return;
              }

              setState(() {
                _destination = latLng;
                _selectedMarker = Marker(
                  markerId: const MarkerId('destination'),
                  position: latLng,
                );
                _showRouteButton = true;
              });
            },
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchPlaces,
                    decoration: const InputDecoration(
                      hintText: 'Search places',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                    ),
                  ),
                ),
                if (_predictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      itemBuilder: (_, i) {
                        final p = _predictions[i];
                        return ListTile(
                          title: Text(p.fullText),
                          onTap: () => _selectPlace(p.placeId),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 80,
            right: 12,
            child: Column(
              children: [
                FloatingActionButton.extended(
                  heroTag: 'ml_grid',
                  backgroundColor:
                      _showMLGrids ? Colors.red : Colors.grey.shade700,
                  icon: const Icon(Icons.grid_on),
                  label: const Text('ML Grid'),
                  onPressed: () {
                    setState(() {
                      _showMLGrids = !_showMLGrids;
                    });
                  },
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'flood_poly',
                  backgroundColor: _showFloodPolygons
                      ? Colors.blue
                      : Colors.grey.shade700,
                  icon: const Icon(Icons.water),
                  label: const Text('Flood Map'),
                  onPressed: () {
                    setState(() {
                      _showFloodPolygons = !_showFloodPolygons;
                    });
                  },
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'risk_overlay',
                  backgroundColor: _showRiskFloodOverlay
                      ? Colors.deepOrange
                      : Colors.grey.shade700,
                  icon: const Icon(Icons.warning_amber),
                  label: const Text('Risk Overlay'),
                  onPressed: () {
                    setState(() {
                      _showRiskFloodOverlay = !_showRiskFloodOverlay;
                    });

                    if (_showRiskFloodOverlay) {
                      _buildRiskFloodOverlay();
                    }
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 140,
            left: 20,
            child: FloatingActionButton(
              heroTag: 'dev_mode',
              backgroundColor: Colors.black87,
              child: const Icon(Icons.developer_mode),
              onPressed: _openDevDialog,
            ),
          ),
          if (_showRouteButton)
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
                onPressed: () {
                  if (_origin != null && _destination != null) {
                    _getDirections(_origin!, _destination!);
                    setState(() => _showRouteButton = false);
                  }
                },
              ),
            ),
          if (_routeInfo != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: Text(
                  _routeInfo!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
