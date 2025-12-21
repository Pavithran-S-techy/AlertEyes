import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class FloodMapScreen extends StatefulWidget {
  const FloodMapScreen({super.key});

  @override
  State<FloodMapScreen> createState() => _FloodMapScreenState();
}

class _FloodMapScreenState extends State<FloodMapScreen> {
  final MapController _mapController = MapController();

  final LatLng keralaCenter = LatLng(10.8505, 76.2711);
  LatLng? _userLocation;
  double _currentZoom = 7;

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // try once at startup
  }

  // 🔹 LOCATION FETCH FUNCTION
  Future<void> _getUserLocation() async {
    // 1. Check GPS service
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMsg('Please enable location services');
      return;
    }

    // 2. Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showMsg('Location permission denied');
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _showMsg(
        'Location permission permanently denied. Enable it from settings.',
      );
      return;
    }

    // 3. Get current position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      _showMsg('Failed to get location');
    }
  }

  // 🔹 BUTTON HANDLER
  Future<void> _goToUserLocation() async {
    if (_userLocation == null) {
      await _getUserLocation();
    }

    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15);
    } else {
      _showMsg('User location not available');
    }
  }

  void _zoomIn() {
    _currentZoom++;
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _zoomOut() {
    _currentZoom--;
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _resetMap() {
    _currentZoom = 7;
    _mapController.move(keralaCenter, _currentZoom);
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flood Risk Map')),
      body: Stack(
        children: [
          // MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: keralaCenter,
              initialZoom: _currentZoom,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flood_ai',
              ),

              // MARKERS
              MarkerLayer(
                markers: [
                  // Demo flood location
                  Marker(
                    point: keralaCenter,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),

                  // User location
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 30,
                      height: 30,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // MAP BUTTONS
          Positioned(
            right: 12,
            top: 100,
            child: Column(
              children: [
                _MapButton(icon: Icons.add, onTap: _zoomIn),
                const SizedBox(height: 8),
                _MapButton(icon: Icons.remove, onTap: _zoomOut),
                const SizedBox(height: 8),
                _MapButton(icon: Icons.explore, onTap: _resetMap),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.my_location,
                  onTap: _goToUserLocation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shape: const CircleBorder(),
      color: Colors.white,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
