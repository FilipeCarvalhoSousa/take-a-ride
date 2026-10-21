import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../auth/login_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  final String driverId;

  const DriverHomeScreen({super.key, required this.driverId});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  late IO.Socket _socket;

  GoogleMapController? _mapController;
  bool _isOnline = false;
  int _availableSeats = 4; // Capacidade padrão do veículo
  LatLng _driverPosition = const LatLng(-15.7942, -47.8822); // Padrão DF
  final Set<Marker> _markers = {};

  Map<String, dynamic>? _activeRideRequest;

  @override
  void initState() {
    super.initState();
    _initSocketConnection();
    _getDriverLocation();
  }

  void _initSocketConnection() {
    // ⚠️ Use o IP exato da sua máquina onde o Docker está rodando
    _socket = IO.io('http://192.168.31.54:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      _socket.emit('driver_online', {'driverId': widget.driverId});
    });

    _socket.on('new_ride_requested', (data) {
      debugPrint('📩 [SOCKET RECEIVED] Dados brutos recebidos: $data');

      // Helper para converter o campo 'price' com segurança (seja String, int ou double)
      double parsePrice(dynamic rawPrice) {
        if (rawPrice == null) return 0.0;
        if (rawPrice is num) return rawPrice.toDouble();
        if (rawPrice is String) return double.tryParse(rawPrice) ?? 0.0;
        return 0.0;
      }

      setState(() {
        _isOnline = true; // Força visualização da corrida na tela

        _activeRideRequest = {
          'rideId': data['id']?.toString() ?? '',
          'passengerName': data['passengerName'] ?? 'Passageiro',
          'pickup': data['originAddress'] ?? 'Ponto de Embarque',
          'destination': data['destinationAddress'] ?? 'Destino',
          'seatsRequested': data['seatsRequested'] ?? 1,
          'price': parsePrice(data['price']),
        };
      });

      debugPrint('✅ [STATE UPDATED] Card de corrida definido com sucesso!');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔔 Nova solicitação de corrida recebida!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  void dispose() {
    _socket.disconnect();
    _socket.dispose();
    super.dispose();
  }

  Future<void> _getDriverLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final LatLng pos = LatLng(position.latitude, position.longitude);
    setState(() {
      _driverPosition = pos;
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: pos,
          infoWindow: const InfoWindow(title: 'Sua Posição (Motorista)'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          ),
        ),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: 15.0)),
    );
  }

  void _acceptRide(Map<String, dynamic> ride) {
    final int seatsNeeded = ride['seatsRequested'];

    if (seatsNeeded > _availableSeats) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vagas insuficientes no veículo para esta corrida!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _availableSeats -= seatsNeeded;
      _activeRideRequest = null; // Limpa o card da solicitação
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Corrida aceita! Vagas restantes: $_availableSeats'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectRide() {
    setState(() {
      _activeRideRequest = null;
    });
  }

  Future<void> _logout() async {
    // 1. Desconecta o Socket se estiver ativo
    _socket.disconnect();

    // 2. Apaga o token salvo localmente
    const storage = FlutterSecureStorage();
    await storage.deleteAll();

    if (!mounted) return;

    // 3. Redireciona para o Login limpando todo o histórico de navegação (evita tela preta)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Motorista'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Botão para alternar visualização / Sair
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior de status do motorista
            Container(
              color: _isOnline ? Colors.green.shade800 : Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isOnline ? Icons.check_circle : Icons.offline_bolt,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isOnline ? 'ONLINE (Aguardando Corridas)' : 'OFFLINE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isOnline,
                    activeColor: Colors.lightGreenAccent,
                    onChanged: (val) {
                      setState(() {
                        _isOnline = val;
                        // Se ficou offline, pode limpar solicitações pendentes não salvas
                        if (!val) {
                          _activeRideRequest = null;
                        }
                      });

                      if (val) {
                        // Notifica o NestJS que o motorista está pronto para receber corridas
                        _socket.emit('driver_online', {
                          'driverId': widget.driverId,
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            // Google Maps
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _driverPosition,
                  zoom: 14.0,
                ),
                markers: _markers,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                onMapCreated: (controller) => _mapController = controller,
              ),
            ),

            // Painel Inferior: Controle de Vagas e Solicitação
            // Painel Inferior: Controle de Vagas e Solicitações de Corridas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Controle permanente de Vagas do Veículo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vagas no Veículo:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      DropdownButton<int>(
                        value: _availableSeats,
                        items: [1, 2, 3, 4].map((seats) {
                          return DropdownMenuItem(
                            value: seats,
                            child: Text('$seats vaga(s) livre(s)'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _availableSeats = val);
                          }
                        },
                      ),
                    ],
                  ),

                  // 2. Só desenha o Card DEPOIS que receber uma corrida real
                  if (_activeRideRequest != null && _isOnline) ...[
                    const Divider(height: 24),
                    Card(
                      elevation: 4,
                      color: Colors.amber.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.orange),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cabeçalho: Nome e Vagas
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _activeRideRequest!['passengerName']
                                            ?.toString() ??
                                        'Passageiro',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_activeRideRequest!['seatsRequested'] ?? 1} lugar(es)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Embarque
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.my_location,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Embarque: ${_activeRideRequest!['pickup'] ?? 'Local não informado'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Destino
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Destino: ${_activeRideRequest!['destination'] ?? 'Local não informado'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Valor dos Ganhos
                            Text(
                              'Ganhos: R\$ ${((_activeRideRequest!['price'] ?? 0.0) as double).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Botões de Ação
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _rejectRide,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    child: const Text('Recusar'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _acceptRide(_activeRideRequest!),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Aceitar Corrida'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Mensagem simples quando está aguardando ou offline
                    const SizedBox(height: 12),
                    Text(
                      _isOnline
                          ? 'Aguardando novas solicitações...'
                          : 'Fique ONLINE para receber passageiros.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
