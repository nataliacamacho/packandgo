import 'dart:convert';
import 'package:http/http.dart' as http;

class MapboxMaletaServicio {
  final String token = 'TU_TOKEN_MAPBOX';

  Future<String> detectarTipoDestino(
    String destino,
  ) async {
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$destino.json?access_token=$token';

    final response = await http.get(
      Uri.parse(url),
    );

    if (response.statusCode != 200) {
      return 'ciudad';
    }

    final data = jsonDecode(response.body);

    if (data['features'] == null ||
        data['features'].isEmpty) {
      return 'ciudad';
    }

    final lugar =
        data['features'][0]['place_name']
            .toString()
            .toLowerCase();

    // ======================
    // CLASIFICACIÓN
    // ======================

    if (lugar.contains('beach') ||
        lugar.contains('playa') ||
        lugar.contains('coast')) {
      return 'playa';
    }

    if (lugar.contains('mountain') ||
        lugar.contains('montaña') ||
        lugar.contains('sierra')) {
      return 'montaña';
    }

    if (lugar.contains('forest') ||
        lugar.contains('bosque')) {
      return 'bosque';
    }

    if (lugar.contains('desert') ||
        lugar.contains('desierto')) {
      return 'desierto';
    }

    if (lugar.contains('pueblo')) {
      return 'pueblo';
    }

    return 'ciudad';
  }
}