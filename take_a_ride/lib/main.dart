import 'package:flutter/material.dart';
import 'package:take_a_ride/screens/auth/auth_check_screen.dart';

import 'core/services/auth_service.dart';
import 'core/network/socket_service.dart';
import 'screens/auth/login_screen.dart';

import 'screens/driver/driver_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // IP da sua rede Wi-Fi local
  SocketService().initSocket('http://192.168.31.54:3000');

  // Checa se existe sessão prévia no dispositivo
  final token = await AuthService.getToken();
  final driverId = await AuthService.getDriverId();

  runApp(TakeARideApp(isLoggedIn: token != null, driverId: driverId));
}

class TakeARideApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? driverId;

  const TakeARideApp({super.key, required this.isLoggedIn, this.driverId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Take A Ride',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const AuthCheckScreen(),
    );
  }
}
