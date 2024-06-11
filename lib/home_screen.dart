import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'custom_bottom_navigation_bar.dart';
import 'homepage.dart';
import 'settings.dart';
import 'map.dart';
import 'profileImageService.dart';

class HomeScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const HomeScreen(
      {super.key,
      required this.initialLatitude,
      required this.initialLongitude});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? userProfileImageUrl;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    loadProfileImage();
    _initializePages();
  }

  void _initializePages() {
    _pages = [
      const HomePage(),
      MapScreen(
          latitude: widget.initialLatitude, longitude: widget.initialLongitude),
      SettingsScreen(updateProfileImage: updateProfileImage),
    ];
  }

  void updateProfileImage(String url) {
    setState(() {
      userProfileImageUrl = url;
    });
  }

  Future<void> loadProfileImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      ProfileImageService imageService = ProfileImageService();
      String? imageUrl = await imageService.fetchProfileImageUrl(user.uid);
      setState(() {
        userProfileImageUrl = imageUrl;
      });
    }
  }

  void _showAddArduinoDialog() {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _macAddressController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Arduino'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(hintText: "Nome do Arduino"),
                ),
                TextField(
                  controller: _macAddressController,
                  decoration: const InputDecoration(hintText: "Endereço MAC"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Salvar'),
              onPressed: () {
                _saveArduinoDetails(
                    _nameController.text, _macAddressController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _saveArduinoDetails(String name, String macAddress) {
    if (name.isEmpty || macAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Todos os campos devem ser preenchidos.")),
      );
      return;
    }

    FirebaseFirestore.instance.collection('arduinos').add({
      'name': name,
      'macAddress': macAddress,
      'timestamp': Timestamp.now(),
      'userId': FirebaseAuth
          .instance.currentUser?.uid, // associar o dispositivo ao usuário
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Arduino registrado com sucesso!")),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Falha ao registrar o Arduino: $error")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddArduinoDialog,
          ),
        ],
      ),
      body: Center(
        child: _pages.isNotEmpty
            ? _pages.elementAt(_selectedIndex)
            : const CircularProgressIndicator(),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        profileImageUrl: userProfileImageUrl,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
