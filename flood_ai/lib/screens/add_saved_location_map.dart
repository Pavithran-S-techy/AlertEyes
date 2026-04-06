// =============================
// add_saved_location_map.dart
// =============================

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as gplaces;
import '../models/saved_location.dart';

class AddSavedLocationMap extends StatefulWidget {
  const AddSavedLocationMap({super.key});

  @override
  State<AddSavedLocationMap> createState() => _AddSavedLocationMapState();
}

class _AddSavedLocationMapState extends State<AddSavedLocationMap> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  LatLng? _selectedPoint;
  Marker? _marker;

  final TextEditingController _searchController = TextEditingController();
  List<gplaces.AutocompletePrediction> _predictions = [];

  final gplaces.FlutterGooglePlacesSdk places =
      gplaces.FlutterGooglePlacesSdk('AIzaSyAiBCgfrRQYJgqcEtQomfJqTAW4H-fyosg');

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  /* ---------------- USER LOCATION ---------------- */

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _userLocation = LatLng(pos.latitude, pos.longitude);
    });
  }

  /* ---------------- SEARCH ---------------- */

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
      fields: [
        gplaces.PlaceField.Location,
        gplaces.PlaceField.Name,
      ],
    );

    if (details.place == null) return;

    final loc = details.place!.latLng!;
    final point = LatLng(loc.lat, loc.lng);

    setState(() {
      _selectedPoint = point;
      _marker = Marker(
        markerId: const MarkerId('selected'),
        position: point,
      );
      _predictions = [];
      _searchController.clear();
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(point, 16),
    );
  }

  /* ---------------- SAVE LOCATION ---------------- */

  Future<void> _saveLocation() async {
    if (_selectedPoint == null) return;

    final TextEditingController nameController = TextEditingController();

    final String? name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save Location'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Home / Work / College',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    Navigator.pop(
      context,
      SavedLocation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        position: _selectedPoint!,
      ),
    );
  }

  /* ---------------- BUILD ---------------- */

  @override
  Widget build(BuildContext context) {
    if (_userLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userLocation!,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: {
              if (_marker != null) _marker!,
            },
            onMapCreated: (c) => _mapController = c,
            onTap: (latLng) {
              setState(() {
                _selectedPoint = latLng;
                _marker = Marker(
                  markerId: const MarkerId('selected'),
                  position: latLng,
                );
              });
            },
          ),

          // SEARCH BAR
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
                      hintText: 'Search place',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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

          // SAVE BUTTON
          if (_selectedPoint != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _saveLocation,
                child: const Text('Save This Location'),
              ),
            ),
        ],
      ),
    );
  }
}
