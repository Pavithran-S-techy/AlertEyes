import 'package:flutter/material.dart';
import '../models/saved_location.dart';
import 'add_saved_location_map.dart';
import '../services/saved_location_service.dart';

class SavedLocationsScreen extends StatefulWidget {
  final int userId;

  const SavedLocationsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  List<dynamic> _savedLocations = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final data =
        await SavedLocationService.fetchLocations(widget.userId);
    setState(() {
      _savedLocations = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Locations')),
      body: Column(
        children: [
          Expanded(
            child: _savedLocations.isEmpty
                ? const Center(child: Text('No saved locations'))
                : ListView.builder(
                    itemCount: _savedLocations.length,
                    itemBuilder: (_, i) {
                      final loc = _savedLocations[i];
                      return ListTile(
                        leading: const Icon(Icons.place),
                        title: Text(loc['name']),
                        subtitle: Text(
                            '${loc['latitude']}, ${loc['longitude']}'),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add New Location'),
              onPressed: () async {
                final result = await Navigator.push<SavedLocation>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddSavedLocationMap(),
                  ),
                );

                if (result != null) {
                  await SavedLocationService.addLocation(
                    widget.userId,
                    result.name,
                    result.position,
                  );
                  _loadLocations();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
