import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/login_screen.dart';
import '../driver/driver_home_screen.dart';
import '../passenger/passenger_home_screen.dart';

class HomeSelectionScreen extends StatelessWidget {
  final String userId;

  const HomeSelectionScreen({super.key, required this.userId});
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _primaryColor = Color(0xFF111111);
  static const Color _passengerColor = Color(0xFF2463EB);

  Future<void> _logout(BuildContext context) async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openDriver(BuildContext context) {
    print('User ID: $userId');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DriverHomeScreen(driverId: userId)),
    );
  }

  void _openPassenger(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PassengerHomeScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Carona'),
        centerTitle: false,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              const Icon(
                Icons.directions_car_filled,
                size: 64,
                color: _primaryColor,
              ),

              const SizedBox(height: 20),

              const Text(
                'O que deseja fazer?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Escolha como deseja utilizar o aplicativo hoje.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),

              const SizedBox(height: 32),

              _buildOptionCard(
                context: context,
                icon: Icons.directions_car,
                title: 'Oferecer carona',
                description:
                    'Defina seu percurso, informe as vagas disponíveis '
                    'e receba solicitações de passageiros.',
                iconColor: _primaryColor,
                iconBackground: const Color(0xFFFFF0BD),
                buttonText: 'Entrar como motorista',
                buttonColor: _primaryColor,
                buttonTextColor: Colors.white,
                onTap: () => _openDriver(context),
              ),

              const SizedBox(height: 20),

              _buildOptionCard(
                context: context,
                icon: Icons.person_pin_circle,
                title: 'Buscar carona',
                description:
                    'Encontre motoristas que passarão pelo seu destino '
                    'e escolha seus pontos de embarque e desembarque.',
                iconColor: _passengerColor,
                iconBackground: const Color(0xFFE7EFFF),
                buttonText: 'Entrar como passageiro',
                buttonColor: Colors.white,
                buttonTextColor: _primaryColor,
                buttonBorderColor: _primaryColor,
                onTap: () => _openPassenger(context),
              ),

              const SizedBox(height: 24),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, size: 20, color: Colors.black45),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Você pode alternar entre as opções quando quiser.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
    required Color iconBackground,
    required String buttonText,
    required Color buttonColor,
    required Color buttonTextColor,
    Color? buttonBorderColor,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E5E5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 30),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: buttonTextColor,
                  side: BorderSide(color: buttonBorderColor ?? buttonColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        buttonText,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
