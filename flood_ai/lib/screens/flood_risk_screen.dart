import 'package:flutter/material.dart';
import 'flood_map_screen.dart';


class FloodRiskScreen extends StatelessWidget {
  const FloodRiskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flood Risk'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Location card
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: const [
                  Icon(Icons.location_on, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Selected Location:\nKerala (Demo)',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Risk status card
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  Text(
                    'Flood Risk Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'MODERATE',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Indicators
          const Text(
            'Indicators',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),

          _IndicatorTile(
            title: 'Rainfall (last 24h)',
            value: '85 mm',
            icon: Icons.cloud,
          ),
          _IndicatorTile(
            title: 'River Water Level',
            value: 'Rising',
            icon: Icons.trending_up,
          ),
          _IndicatorTile(
            title: 'Terrain Risk',
            value: 'Medium',
            icon: Icons.terrain,
          ),

          const SizedBox(height: 30),

          // Map button
          ElevatedButton.icon(
            onPressed: () {
                Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const FloodMapScreen(),
                ),
                );
            },
            icon: const Icon(Icons.map),
            label: const Text('View Flood Risk Map'),
            ),
        ],
      ),
    );
  }
}

class _IndicatorTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _IndicatorTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
