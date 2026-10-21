import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../core/services/location_service.dart';
import '../auth/login_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  final String userId;

  const PassengerHomeScreen({super.key, required this.userId});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  late IO.Socket _socket;
  GoogleMapController? _mapController;
  int _selectedSeats = 1;
  bool _isEntorno = false;
  double _estimatedPrice = 3.80;

  // Ponto de Embarque Inicial (ex: Av. Paulista)
  LatLng _originPosition = const LatLng(-15.7942, -47.8822);

  // Ponto de Destino (Será atualizado pela busca)
  LatLng? _destinationPosition;

  final Set<Marker> _markers = {};
  final _destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateOriginMarker();
    _getCurrentUserLocation();
  }

  void _recalculatePrice(String originCity, String destCity) {
    double unitFare = 5.50;

    if (_isEntorno) {
      unitFare = 7.00;
    } else if (originCity.toLowerCase() == destCity.toLowerCase()) {
      unitFare = 3.80;
    }

    setState(() {
      _estimatedPrice = unitFare * _selectedSeats;
    });
  }

  Future<void> _getCurrentUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Checa se o serviço de localização está ativo
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // Solicita permissão de GPS ao usuário
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Captura a posição exata atual
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final LatLng userLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _originPosition = userLatLng;
      _updateOriginMarker(); // Atualiza o pino de embarque (azul) para a posição real
    });

    // 🎥 Move o Google Maps para a posição real do passageiro no DF
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: userLatLng, zoom: 16.0),
      ),
    );
  }

  // Define o marcador de origem no mapa
  void _updateOriginMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId('origin'),
        position: _originPosition,
        infoWindow: const InfoWindow(title: 'Ponto de Embarque'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }

  // 🎯 Atualiza o pino de Destino e move a Câmera do Mapa
  void _onDestinationSelected(String description, String placeId) async {
    _destinationController.text = description;

    // Busca as coordenadas exatas da sugestão escolhida
    final LatLng? newCoordinates = await LocationService.getPlaceLatLng(
      placeId,
    );

    if (newCoordinates != null) {
      setState(() {
        _destinationPosition = newCoordinates;

        _markers.removeWhere((m) => m.markerId.value == 'destination');
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: newCoordinates,
            infoWindow: InfoWindow(title: 'Destino', snippet: description),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      });

      // 🎥 Move a câmera do mapa com animação suave para o novo endereço
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newCoordinates, zoom: 16.0),
        ),
      );
    }
  }

  Future<void> _logout() async {
    _socket.disconnect();
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take a Ride - Pedir Corrida'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🗺️ WIDGET DO GOOGLE MAPS
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _originPosition,
                  zoom: 14.0,
                ),
                markers: _markers,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                onMapCreated: (controller) => _mapController = controller,
              ),
            ),

            // Card Inferior com Autocompletar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Campo de Origem (Localização / Ponto Fixo)
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.my_location, color: Colors.blue),
                    title: Text('Sua localização / Ponto de Embarque'),
                    subtitle: Text('Av. Paulista, 1000 - São Paulo'),
                  ),
                  const Divider(height: 16),

                  // 2. Campo de Destino com Autocompletar (Filtro por Pontos e Terminais)
                  TypeAheadField<Map<String, String>>(
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Selecione o ponto ou terminal de destino',
                          hintText:
                              'Ex: Terminal Ceilândia, Estação Central...',
                          prefixIcon: Icon(
                            Icons.directions_bus,
                            color: Colors.red,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (text) {
                          _destinationController.text = text;
                        },
                      );
                    },
                    suggestionsCallback: (search) async {
                      if (search.trim().isEmpty) return [];
                      return await LocationService.getPlacePredictions(search);
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        leading: const Icon(
                          Icons.directions_bus_outlined,
                          color: Colors.black54,
                        ),
                        title: Text(
                          suggestion['description']!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      );
                    },
                    onSelected: (suggestion) {
                      _destinationController.text = suggestion['description']!;
                      _onDestinationSelected(
                        suggestion['description']!,
                        suggestion['place_id']!,
                      );
                    },
                    emptyBuilder: (context) => const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Nenhum ponto ou terminal encontrado.'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Seletor de Quantidade de Lugares
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quantidade de Lugares:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<int>(
                        value: _selectedSeats,
                        items: [1, 2, 3, 4].map((seats) {
                          return DropdownMenuItem(
                            value: seats,
                            child: Text('$seats lugar(es)'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSeats = val);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 4. Exibição do Valor Estimado
                  Text(
                    'Valor da Passagem: R\$ ${(_estimatedPrice * _selectedSeats).toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Botão de Solicitação de Corrida
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _destinationPosition == null
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Procurando motoristas próximos...',
                                ),
                              ),
                            );
                          },
                    child: const Text(
                      'Confirmar e Pedir Corrida',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
