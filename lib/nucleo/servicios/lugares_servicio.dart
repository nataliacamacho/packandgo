import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LugaresServicio {
  static String get foursquareApiKey =>
    dotenv.env['FOURSQUARE_API_KEY'] ?? '';

static String get openTripApiKey =>
    dotenv.env['OPENTRIPMAP_API_KEY'] ?? '';

  //  FOURSQUARE
  static Future<List<Map<String, dynamic>>> buscarFoursquare(String query) async {
    final url = Uri.parse(
        "https://api.foursquare.com/v3/places/search?query=$query&limit=10");

    final response = await http.get(
      url,
      headers: {
        "Authorization": foursquareApiKey,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data["results"] as List;

      return results.map((lugar) {
        return {
          "name": lugar["name"],
          "location": {
            "formatted_address":
                lugar["location"]["formatted_address"] ?? "Sin dirección"
          },
          "lat": lugar["geocodes"]["main"]["latitude"],
          "lng": lugar["geocodes"]["main"]["longitude"],
          "categories": lugar["categories"] ?? [],
        };
      }).toList();
    } else {
      throw Exception("Error Foursquare");
    }
  }

  //  OPENTRIPMAP
  static Future<List<Map<String, dynamic>>> buscarOpenTripMap(String query) async {
    final url = Uri.parse(
        "https://api.opentripmap.com/0.1/en/places/geoname?name=$query&apikey=$openTripApiKey");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return [
        {
          "name": data["name"],
          "location": {"formatted_address": data["country"]},
          "lat": data["lat"],
          "lng": data["lon"],
          "categories": [
            {"name": "Turístico"}
          ],
        }
      ];
    } else {
      return [];
    }
  }

  //  COMBINAR RESULTADOS
  static Future<List<Map<String, dynamic>>> buscarLugares(String query) async {
    final foursquare = await buscarFoursquare(query);
    final openTrip = await buscarOpenTripMap(query);

    return [...foursquare, ...openTrip];
  }
}