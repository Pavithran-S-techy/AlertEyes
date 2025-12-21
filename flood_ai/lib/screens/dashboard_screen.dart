import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'flood_risk_screen.dart';



class DashboardScreen extends StatelessWidget {
  final String name;
  final String email;

  const DashboardScreen({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flood AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome
          Text(
            'Hello, $name',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 16),

          // Status Card
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'System Status: Demo mode\n'
                      'AI predictions will be enabled soon.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Action List
          _DashboardItem(
            icon: Icons.water,
            title: 'Flood Risk',
            subtitle: 'Check flood-prone areas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FloodRiskScreen(),
                ),
              );
            },
          ),

          _DashboardItem(
            icon: Icons.warning,
            title: 'Alerts & Warnings',
            subtitle: 'View latest alerts',
            onTap: () => _comingSoon(context),
          ),
          _DashboardItem(
            icon: Icons.map,
            title: 'Safe Routes',
            subtitle: 'Find safer paths',
            onTap: () => _comingSoon(context),
          ),
          _DashboardItem(
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'View account details',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    name: name,
                    email: email,
                  ),
                ),
              );
            },
          ),

        ],
      ),
    );
  }

  static void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feature coming soon')),
    );
  }
}

class _DashboardItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
