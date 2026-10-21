// lib/screens/auth/auth_check_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../home/home_page.dart';
import '../passenger/passenger_home_screen.dart';
import 'login_screen.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    final role = await _storage.read(key: 'user_role');
    final userId = await _storage.read(key: 'user_id');

    if (!mounted) return;

    if (token != null && role != null && userId != null) {
      // 🚀 Se possui token, vai direto para a Home correspondente
      if (role == 'DRIVER') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeSelectionScreen(userId: userId),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PassengerHomeScreen(userId: userId),
          ),
        );
      }
    } else {
      // 🔒 Senão, envia para a tela de Login
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
