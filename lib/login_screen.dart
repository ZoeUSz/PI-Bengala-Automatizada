import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'app_colors.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? selectedCountry = 'Brasil';
  bool isAgreed = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _keepLoggedIn = false;

  Future<void> _loginUser() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Armazenar a preferência de permanecer logado
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('keepLoggedIn', _keepLoggedIn);

      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Please verify your email address first.")));
      } else {
        // Aviso de sucesso no login
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Login successful!")));
        // Se o e-mail estiver verificado, redireciona para a HomeScreen
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              initialLatitude: position.latitude,
              initialLongitude: position.longitude,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to login: $e")));
    }
  }

  Future<void> _resetPassword(String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email address.")),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Password reset email sent! check your inbox.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send password reset email: $e")),
      );
    }
  }

  void _showResetPasswordDialog() {
    final TextEditingController _emailResetController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: TextField(
          controller: _emailResetController,
          decoration: const InputDecoration(
            labelText: "Email",
            hintText: "Enter your email address",
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _resetPassword(_emailResetController.text);
              Navigator.of(context).pop();
            },
            child: const Text("Send reset link"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entrar")),
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Entre com o seu email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              obscureText: true,
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              title: const Text("Mantenha-me conectado"),
              value: _keepLoggedIn,
              onChanged: (bool? value) {
                setState(() {
                  _keepLoggedIn = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text(
                  'Eu concordo com a Política de Privacidade, Termo de Acordo do Usuário e Política de Privacidade das Crianças'),
              value: isAgreed,
              onChanged: (bool? newValue) {
                setState(() {
                  isAgreed = newValue ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isAgreed ? _loginUser : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Entrar'),
            ),
            TextButton(
              onPressed: _showResetPasswordDialog,
              child: const Text('Esqueceu a senha'),
            ),
          ],
        ),
      ),
    );
  }
}
