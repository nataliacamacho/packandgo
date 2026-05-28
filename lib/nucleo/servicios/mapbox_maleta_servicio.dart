import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MapboxMaletaServicio {
  final String token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  // =========================
  // NORMALIZADOR GLOBAL
  // =========================
  String normalizar(String s) {
    return s
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  // =========================
  // DETECTAR TIPO
  // =========================
  Future<String> detectarTipoDestino(String destino) async {
    try {
      print("MAPBOX ACTIVADO");
      print("Destino recibido: $destino");

      final url =
          'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(destino)}.json'
          '?access_token=$token';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return 'ciudad';
      }

      final data = jsonDecode(response.body);

      if (data['features'] == null || data['features'].isEmpty) {
        return 'ciudad';
      }

      final lugar = data['features'][0];

      final texto = normalizar(lugar['text'] ?? '');
      final nombreCompleto = normalizar(lugar['place_name'] ?? '');

      if (texto.contains('playa') ||
          nombreCompleto.contains('beach') ||
          nombreCompleto.contains('costa') ||
          nombreCompleto.contains('mar') ||
          nombreCompleto.contains('riviera') ||
          nombreCompleto.contains('isla') ||
          nombreCompleto.contains('bahia')) {
        return 'playa';
      }

      if (nombreCompleto.contains('montaña') ||
          nombreCompleto.contains('sierra') ||
          nombreCompleto.contains('nevado') ||
          nombreCompleto.contains('volcan')) {
        return 'montaña';
      }

      if (nombreCompleto.contains('bosque') ||
          nombreCompleto.contains('selva')) {
        return 'bosque';
      }

      if (nombreCompleto.contains('desierto') ||
          nombreCompleto.contains('dunas')) {
        return 'desierto';
      }

      if (nombreCompleto.contains('pueblo')) {
        return 'pueblo';
      }

      return 'ciudad';
    } catch (e) {
      print("ERROR MAPBOX: $e");
      return 'ciudad';
    }
  }

  // =========================
  // VALIDAR DESTINO (VERSIÓN ROBUSTA)
  // =========================
  Future<bool> destinoValido(String destino) async {
    try {
      final destinoNormalizado = normalizar(destino);

      // 🚫 BLOQUEO DE BASURA DIRECTO
      final blacklist = [
        'hola',
        'amigo',
        'test',
        'asdf',
        'qwerty',
        'prueba'
      ];

      if (blacklist.contains(destinoNormalizado)) {
        return false;
      }

      final url =
          'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(destino)}.json'
          '?access_token=$token'
          '&limit=10'
          '&language=es'
          '&types=place,locality,region,district,neighborhood';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);

      if (data['features'] == null || data['features'].isEmpty) {
        return false;
      }

      for (final feature in data['features']) {
        final placeType = feature['place_type'] as List<dynamic>?;

        if (placeType == null) continue;

        final text = normalizar(feature['text'] ?? '');
        final placeName = normalizar(feature['place_name'] ?? '');

        final relevance = (feature['relevance'] ?? 0.0) as num;

        // 🚫 filtro de basura
        if (relevance < 0.5) continue;

        final context = feature['context'] as List<dynamic>?;

        // 🚫 debe tener contexto geográfico real
        if (context == null || context.isEmpty) continue;

        // 🧠 scoring inteligente
        int score = 0;

        if (text.contains(destinoNormalizado)) score += 2;
        if (placeName.contains(destinoNormalizado)) score += 2;

        if (placeType.contains('place')) score += 1;
        if (placeType.contains('locality')) score += 1;
        if (placeType.contains('region')) score += 1;
        if (placeType.contains('district')) score += 1;
        if (placeType.contains('neighborhood')) score += 1;

        // 🎯 decisión final
        if (score >= 2) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print("ERROR VALIDANDO DESTINO: $e");
      return false;
    }
  }
}