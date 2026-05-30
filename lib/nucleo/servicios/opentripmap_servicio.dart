import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto/nucleo/utilidades/mapeo_categorias.dart';

class OpenTripMapServicio {
  static String get _apiKey => dotenv.env['OPENTRIPMAP_API_KEY'] ?? '';

  static const Map<String, String> _tipoAKinds = {
    'restaurante': 'foods',
    'restaurant': 'foods',
    'cafeteria': 'cafes,foods',
    'cafe': 'cafes,foods', // ¡Aquí estaba el problema!
    'bar': 'pubs,bars',
    'parque': 'natural',
    'park': 'natural',
    'museo': 'museums',
    'museum': 'museums',
    'playa': 'beaches',
    'monumento': 'historic,monuments',
    'tourist_attraction': 'historic,cultural,architecture',
    'zona_arqueologica': 'archaeology',
    'mirador': 'view_points',
    'centro_comercial': 'shops',
    'shopping_mall': 'shops',
    'actividades_extremas': 'sport,amusement_parks',
    'amusement_park': 'sport,amusement_parks',
  };

  static Future<List<Map<String, dynamic>>> buscarLugaresCulturales(
    double lat,
    double lng, {
    String query = '',
    String? tipo,
    int radio = 15000,
  }) async {
    
    // 🔥 FILTRADO DESDE EL ORIGEN PARA OTM
    String kindsAPI = 'foods,cultural,religion,natural,architecture,amusement_parks';
    
    if (tipo != null && tipo.isNotEmpty) {
      String tipoNormalizado = tipo.toLowerCase().trim()
          .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
          .replaceAll('ó', 'o').replaceAll('ú', 'u');
          
      if (_tipoAKinds.containsKey(tipoNormalizado)) {
        kindsAPI = _tipoAKinds[tipoNormalizado]!;
      }
    }

    final url = Uri.parse(
      'https://api.opentripmap.com/0.1/en/places/radius'
      '?radius=$radio'
      '&lon=$lng'
      '&lat=$lat'
      '&kinds=$kindsAPI'
      '&rate=1'
      '&limit=30' // 🔥 Subimos el límite para que nunca te falten tarjetas
      '&apikey=$_apiKey',
    );

    try {
      final respuesta = await http.get(url);
      if (respuesta.statusCode == 200) {
        final datos = json.decode(respuesta.body);
        if (datos['features'] != null && datos['features'].isNotEmpty) {
          final lugaresCrudos = (datos['features'] as List<dynamic>).cast<Map<String, dynamic>>();
          // Mapeamos para estandarizar el formato
          return lugaresCrudos.map((l) => _normalizarOTM(l)).toList();
        }
      }
    } catch (e) {
      print("❌ OPENTRIP ERROR: $e");
    }
    return [];
  }

  static Map<String, dynamic> _normalizarOTM(Map<String, dynamic> raw) {
    // Extraer propiedades
    final props = raw['properties'] ?? raw; 
    
    double lat = 0;
    double lng = 0;
    if (raw['geometry'] != null) {
      lat = (raw['geometry']['coordinates'][1] ?? 0).toDouble();
      lng = (raw['geometry']['coordinates'][0] ?? 0).toDouble();
    } else if (props['point'] != null) {
      lat = (props['point']['lat'] ?? 0).toDouble();
      lng = (props['point']['lon'] ?? 0).toDouble();
    }

    final kinds = (props['kinds'] ?? '').toString();
    final name = props['name'] ?? '';

    return {
      'name': name.isEmpty ? 'Lugar turístico' : name,
      'lat': lat,
      'lng': lng,
      'direccion': _direccionCategoria(kinds),
      'categoriaPrincipal': MapeoCategorias.obtenerCategoriaPrincipal(kinds),
      'rating': _rateToDouble(props['rate']),
      'popularity': _rateToDouble(props['rate']),
      'precio': null,
      'foto': null,
      'horario': 'Horario sujeto a disponibilidad', // OTM no maneja horarios, ponemos default
      'fuente': 'opentripmap',
    };
  }

  static String _direccionCategoria(String kinds) {
    if (kinds.contains('museum')) return 'Museo';
    if (kinds.contains('historic')) return 'Sitio histórico';
    if (kinds.contains('architecture')) return 'Lugar arquitectónico';
    if (kinds.contains('natural')) return 'Zona natural';
    if (kinds.contains('beach')) return 'Playa';
    if (kinds.contains('foods')) return 'Restaurante / Alimentos';
    return 'Lugar turístico';
  }

  static double _rateToDouble(dynamic rate) {
    if (rate is int) return ((rate * 2).clamp(0.0, 10.0)).toDouble();
    if (rate is double) return rate.clamp(0.0, 10.0).toDouble();
    return 5.0;
  }
}