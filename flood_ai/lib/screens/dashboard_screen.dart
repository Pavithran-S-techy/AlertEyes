import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'flood_risk_screen.dart';
import 'login_screen.dart';
import 'saved_locations_screen.dart';

class DashboardScreen extends StatelessWidget {
  final int userId;
  final String name;
  final String email;

  const DashboardScreen({
    super.key,
    required this.userId,
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hello, $name',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          Text(email, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          _DashboardItem(
            icon: Icons.water,
            title: 'Flood Risk',
            subtitle: 'Check flood-prone areas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FloodRiskScreen()),
              );
            },
          ),

          _DashboardItem(
            icon: Icons.person_pin_circle,
            title: 'Saved Locations',
            subtitle: 'Home, Work, School',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SavedLocationsScreen(userId: userId),
                ),
              );
            },
          ),

          _DashboardItem(
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'View account details',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: userId, name: name, email: email),
                ),
              );
            },
          ),
        ],
      ),
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
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
