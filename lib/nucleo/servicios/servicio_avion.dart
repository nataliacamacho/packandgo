import 'dart:math';
import 'google_servicio.dart';
import 'transporte_firestore_servicio.dart';
import '../../modulos/viajes/apartados/transporte/avion/modelo_ruta_avion.dart';

class ServicioAvion {
  final google = GoogleServicio();
  final _firestore = TransporteFirestoreServicio();
  final random = Random();

  Future<List<RutaAvion>> obtenerRutas({
    required String origen,
    required String destino,
  }) async {
    // 1. Intentar cache de Firestore (RQNF28/29)
    final cached = await _firestore.obtenerDatosAvion(
      origen: origen,
      destino: destino,
    );

    if (cached != null) {
      return cached.map((r) => RutaAvion.fromMap(r)).toList();
    }

    // 2. Calcular
    final resultados = await Future.wait([
      google.buscarAeropuerto(origen),
      google.buscarAeropuerto(destino),
    ]);

    final aeroOrigen = resultados[0];
    final aeroDestino = resultados[1];

    if (aeroOrigen == null || aeroDestino == null) {
      await _firestore.registrarError(
        origen: origen,
        destino: destino,
        tipo: 'avion',
      );
      return [];
    }

    final km = calcularDistanciaKm(
      aeroOrigen["lat"],
      aeroOrigen["lng"],
      aeroDestino["lat"],
      aeroDestino["lng"],
    );

    final duracion = calcularDuracionVuelo(km);
    final precioBase = double.parse(calcularPrecioVuelo(km));

    final aerolineasBase = [
      "Aeroméxico",
      "Volaris",
      "Viva Aerobus",
      "Interjet",
      "Magnicharters",
    ];

    final horariosBase = generarHorarios();
    final List<RutaAvion> opciones = [];
    final List<Map<String, dynamic>> paraGuardar = [];

    for (int i = 0; i < 5; i++) {
      final variacion = 1.0 + (i * 0.08);
      final precioVar = (precioBase * variacion).toStringAsFixed(0);

      final ruta = RutaAvion(
        origen: origen,
        destino: destino,
        aeropuertoOrigen: aeroOrigen["nombre"],
        aeropuertoDestino: aeroDestino["nombre"],
        duracion: duracion,
        precio: precioVar,
        horarios: [horariosBase[i % horariosBase.length]],
        aerolineas: [aerolineasBase[i]],
      );

      opciones.add(ruta);
      paraGuardar.add(ruta.toMap());
    }

    // 3. Guardar en Firestore (RQNF28)
    await _firestore.guardarDatosAvion(
      origen: origen,
      destino: destino,
      rutas: paraGuardar,
    );

    return opciones;
  }

  double calcularDistanciaKm(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  String calcularDuracionVuelo(double km) {
    double horas = km / 800 + 2;
    final h = horas.floor();
    final min = ((horas - h) * 60).round();
    return "$h h $min min";
  }

  String calcularPrecioVuelo(double km) {
    double precio = km * 2.5;
    if (precio < 900) precio = 900;
    if (km > 1500) precio *= 1.2;
    if (km > 3000) precio *= 1.4;
    return precio.toStringAsFixed(0);
  }

  List<String> generarHorarios() => [
        "06:00 AM",
        "09:00 AM",
        "12:00 PM",
        "03:00 PM",
        "07:00 PM",
      ];
}