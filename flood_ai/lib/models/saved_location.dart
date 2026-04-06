import 'package:google_maps_flutter/google_maps_flutter.dart';

class SavedLocation {
  final String id;
  final String name;      // Home, Work, College
  final LatLng position;

  SavedLocation({
    required this.id,
    required this.name,
    required this.position,
  });
}
