import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'theme_provider.dart';
import 'app_colors.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'settings.dart';
import 'map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization failed: $e");
  }
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool keepLoggedIn = prefs.getBool('keepLoggedIn') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(keepLoggedIn: keepLoggedIn),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool keepLoggedIn;
  const MyApp({super.key, required this.keepLoggedIn});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    initUniLinks();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> initUniLinks() async {
    _sub = linkStream.listen((String? link) {
      if (link != null && mounted) {
        print('Received link: $link');
        handleDeepLink(link);
      }
    }, onError: (err) {
      print('Error receiving link: $err');
    });
  }

  void handleDeepLink(String link) {
    final Uri uri = Uri.parse(link);
    if (uri.host == 'maps.google.com' && uri.path == '/maps') {
      final String? query = uri.queryParameters['q'];
      if (query != null) {
        final List<String> latLng = query.split(',');
        if (latLng.length == 2) {
          final double latitude = double.parse(latLng[0]);
          final double longitude = double.parse(latLng[1]);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final BuildContext? context =
                navigatorKey.currentState?.overlay?.context;
            if (context != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MapScreen(latitude: latitude, longitude: longitude),
                ),
              );
            }
          });
        }
      }
    }
  }

  Future<LatLng> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      initialRoute: '/',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: themeProvider.themeMode,
      routes: {
        '/': (context) => MainPage(keepLoggedIn: widget.keepLoggedIn),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(
              initialLatitude:
                  0.0, // Placeholder, será atualizado após obter a localização
              initialLongitude:
                  0.0, // Placeholder, será atualizado após obter a localização
            ),
        '/settings': (context) =>
            SettingsScreen(updateProfileImage: _updateProfileImage),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

void _updateProfileImage(String imageUrl) {
  // Lógica para atualizar a imagem de perfil
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MainPage extends StatelessWidget {
  final bool keepLoggedIn;
  const MainPage({super.key, required this.keepLoggedIn});

  @override
  Widget build(BuildContext context) {
    if (keepLoggedIn && FirebaseAuth.instance.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        LatLng currentLocation = await _getCurrentLocation();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              initialLatitude: currentLocation.latitude,
              initialLongitude: currentLocation.longitude,
            ),
          ),
        );
      });
    }
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.home, size: 60.0, color: AppColors.blue),
            const SizedBox(height: 50),
            button(context, 'Log In', '/login'),
            const SizedBox(height: 20),
            button(context, 'Sign Up', '/signup'),
          ],
        ),
      ),
    );
  }

  Widget button(BuildContext context, String text, String routeName) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushNamed(routeName);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.white,
        ),
        child: Text(text),
      ),
    );
  }
}

Future<LatLng> _getCurrentLocation() async {
  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  return LatLng(position.latitude, position.longitude);
}
