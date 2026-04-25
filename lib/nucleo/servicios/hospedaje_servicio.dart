import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Hospedaje {
  final String nombre;
  final String direccion;
  final String imagen;
  final String precio;
  final String xid;
  final String linkReserva;

  Hospedaje({
    required this.nombre,
    required this.direccion,
    required this.imagen,
    required this.precio,
    required this.xid,
    required this.linkReserva,
  });

  factory Hospedaje.fromOpenTripMap(Map<String, dynamic> json) {
    final nombre = (json['name'] ?? '').toString().trim();

    return Hospedaje(
      nombre: nombre.isNotEmpty ? nombre : 'Hospedaje sin nombre',
      direccion: 'Ver ubicación en mapa',
      imagen: 'https://via.placeholder.com/150',
      precio: 'Consultar precio',
      xid: json['xid'] ?? '',
      // 🔗 Link a Booking buscando el nombre del lugar
      linkReserva: nombre.isNotEmpty
          ? 'https://www.booking.com/search.html?ss=${Uri.encodeComponent(nombre)}'
          : 'https://www.booking.com',
    );
  }
}

class HospedajeServicio {
  Future<List<Hospedaje>> obtenerHospedajes({
    required double lat,
    required double lng,
    int radio = 5000,
    int limite =
        15, // pedimos 15 para filtrar los sin nombre y quedarnos con 5+
  }) async {
    final apiKey = dotenv.env['OPENTRIPMAP_API_KEY']?.trim();

    if (apiKey == null || apiKey.isEmpty) {
      print('❌ OPENTRIPMAP_API_KEY no encontrada en .env');
      return [];
    }

    final url = Uri.parse(
      'https://api.opentripmap.com/0.1/en/places/radius'
      '?radius=$radio'
      '&lon=$lng'
      '&lat=$lat'
      '&kinds=accomodations'
      '&rate=2'
      '&limit=$limite'
      '&format=json'
      '&apikey=$apiKey',
    );

    print('🌐 URL: $url');
    print('📍 Buscando hospedajes en lat=$lat, lng=$lng, radio=$radio');

    try {
      final respuesta = await http
          .get(url)
          .timeout(const Duration(seconds: 20));

      print('📡 STATUS: ${respuesta.statusCode}');

      if (respuesta.statusCode == 200) {
        final data = json.decode(respuesta.body);
        final lista = data is List ? data : (data['features'] as List? ?? []);

        // ✅ Filtramos los que no tienen nombre
        final conNombre = lista
            .map(
              (j) => Hospedaje.fromOpenTripMap(
                j is Map && j.containsKey('properties') ? j['properties'] : j,
              ),
            )
            .where((h) => h.nombre != 'Hospedaje sin nombre')
            .take(10)
            .toList();

        print('✅ Hospedajes con nombre: ${conNombre.length}');
        return conNombre;
      } else if (respuesta.statusCode == 429) {
        print('⚠️ Límite de requests alcanzado');
        return [];
      } else {
        print('❌ Error ${respuesta.statusCode}: ${respuesta.body}');
        return [];
      }
    } on TimeoutException {
      print('⏱ Timeout');
      return [];
    } on SocketException catch (e) {
      print('🔌 Sin conexión: $e');
      return [];
    } catch (e) {
      print('❌ Error inesperado: $e');
      return [];
    }
  }
}
