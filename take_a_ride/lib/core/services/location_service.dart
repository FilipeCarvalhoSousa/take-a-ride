import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LocationService {
  // ⚠️ Substitua pela sua chave da Google Cloud (com Places API e Geocoding API ativas)
  static const String _apiKey = 'AIzaSyAtUvkecl3gdjCfAREW-ya7x1VxuqTx6Qs';

  // 1. Autocomplete utilizando a Places API (New)
  static Future<List<Map<String, String>>> getPlacePredictions(
    String input,
  ) async {
    if (input.trim().isEmpty) return [];

    final url = Uri.parse(
      'https://places.googleapis.com/v1/places:autocomplete',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key':
              _apiKey, // A chave é enviada no cabeçalho na API Nova
        },
        body: jsonEncode({
          'input': input,
          'includedPrimaryTypes':
              [], // Pode filtrar por tipos específicos aqui se quiser
          'includedRegionCodes': ['br'],
          'languageCode': 'pt-BR',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final suggestions = data['suggestions'] as List? ?? [];

        return suggestions.map<Map<String, String>>((s) {
          final placePrediction = s['placePrediction'];
          return {
            'place_id': placePrediction['placeId'] as String,
            'description': placePrediction['text']['text'] as String,
          };
        }).toList();
      } else {
        debugPrint(
          '⚠️ [Places API New Error]: Status ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('💥 [Exceção no LocationService]: $e');
    }

    return [];
  }

  // 2. Busca coordenadas LatLng do local na Places API (New)
  static Future<LatLng?> getPlaceLatLng(String placeId) async {
    final url = Uri.parse('https://places.googleapis.com/v1/places/$placeId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'location', // Solicita apenas o campo de coordenadas
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final location = data['location'];
        return LatLng(
          (location['latitude'] as num).toDouble(),
          (location['longitude'] as num).toDouble(),
        );
      }
    } catch (e) {
      debugPrint('💥 [Exceção no getPlaceLatLng]: $e');
    }
    return null;
  }
}
