import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'image_manager.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  final Function(String) updateProfileImage;

  const SettingsScreen({super.key, required this.updateProfileImage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person_add, color: Colors.black),
            ),
            title: const Text('Clique aqui para adicionar a foto de perfil'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageScreen(
                    onImageUploaded: (imageUrl) {
                      updateProfileImage(imageUrl);
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_6, color: Colors.black),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: Provider.of<ThemeProvider>(context).themeMode ==
                  ThemeMode.dark,
              onChanged: (bool value) {
                Provider.of<ThemeProvider>(context, listen: false)
                    .toggleTheme(value);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.black),
            title: const Text('Logout'),
            onTap: () {
              _logout(context);
            },
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context)
        .pushReplacementNamed('/'); // Ajuste o roteamento conforme necessário
  }
}
