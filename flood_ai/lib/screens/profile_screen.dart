import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'saved_locations_screen.dart';
import 'login_screen.dart';


class ProfileScreen extends StatelessWidget {
  final int userId;
  final String name;
  final String email;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
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
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

            TextButton.icon(
            onPressed: () {
                Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                    name: name,
                    email: email,
                    ),
                ),
                );
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Profile'),
            ),


          const SizedBox(height: 24),

          // Account section
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),

          _ProfileItem(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
                Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                ),
                );
            },
            ),

            _ProfileItem(
            icon: Icons.location_on_outlined,
            title: 'Saved Locations',
            onTap: () {
                Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SavedLocationsScreen(userId: userId),
                ),
                );
            },
            ),


          const SizedBox(height: 20),

          // App section
          const Text(
            'App',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),

          _ProfileItem(
            icon: Icons.info_outline,
            title: 'About Flood AI',
            onTap: () => _comingSoon(context),
          ),
          _ProfileItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => _comingSoon(context),
          ),

          const SizedBox(height: 30),

          // Logout
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
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

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileItem({
    required this.icon,
    required this.title,
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
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
