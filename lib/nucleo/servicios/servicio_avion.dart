import 'dart:math';
import 'google_servicio.dart';
import '../../modulos/viajes/apartados/transporte/avion/modelo_ruta_avion.dart';

class ServicioAvion {
  final google = GoogleServicio();
  final random = Random();

  Future<List<RutaAvion>> obtenerRutas({
    required String origen,
    required String destino,
  }) async {
    final aeroOrigen = await google.buscarAeropuerto(origen);
    final aeroDestino = await google.buscarAeropuerto(destino);

    if (aeroOrigen == null || aeroDestino == null) return [];

    // 🔥 DISTANCIA REAL (línea recta)
    final km = calcularDistanciaKm(
      aeroOrigen["lat"],
      aeroOrigen["lng"],
      aeroDestino["lat"],
      aeroDestino["lng"],
    );

    final duracion = calcularDuracionVuelo(km);
    final precio = calcularPrecioVuelo(km);

    return [
      RutaAvion(
        origen: origen,
        destino: destino,
        aeropuertoOrigen: aeroOrigen["nombre"],
        aeropuertoDestino: aeroDestino["nombre"],
        duracion: duracion,
        precio: precio,
        horarios: generarHorarios(),
        aerolineas: generarAerolineas(),
      ),
    ];
  }

  // 🔥 DISTANCIA ENTRE AEROPUERTOS
  double calcularDistanciaKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371;

    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  // 🔥 DURACIÓN REALISTA DE VUELO
  String calcularDuracionVuelo(double km) {
    const velocidad = 800.0;

    double horas = km / velocidad;

    // tiempo extra real (aeropuerto)
    horas += 2;

    final h = horas.floor();
    final min = ((horas - h) * 60).round();

    return "${h} h ${min} min";
  }

  // 🔥 PRECIO REALISTA
  String calcularPrecioVuelo(double km) {
    double precio = km * 2.5;

    if (precio < 900) precio = 900;

    // ✨ ajuste para vuelos largos
    if (km > 1500) precio *= 1.2;
    if (km > 3000) precio *= 1.4;

    double variacion = precio * 0.15;
    precio += (random.nextDouble() * variacion * 2 - variacion);

    return precio.toStringAsFixed(0);
  }

  // 🔥 HORARIOS
  List<String> generarHorarios() {
    final now = DateTime.now();

    return List.generate(4, (i) {
      final hora = now.add(Duration(hours: i * 3 + 2));
      final h = hora.hour > 12 ? hora.hour - 12 : hora.hour;
      final periodo = hora.hour >= 12 ? "PM" : "AM";

      return "${h.toString().padLeft(2, '0')}:00 $periodo";
    });
  }

  // 🔥 AEROLÍNEAS
  List<String> generarAerolineas() {
    const base = ["Aeroméxico", "Volaris", "Viva Aerobus"];

    final lista = List<String>.from(base);
    lista.shuffle();

    return lista.take(2).toList();
  }
}