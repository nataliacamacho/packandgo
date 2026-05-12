import 'package:proyecto/modulos/viajes/apartados/transporte/autobus/modelo_ruta_autobus.dart';
import 'google_servicio.dart';
import 'dart:math';

class ServicioAutobus {
  final google = GoogleServicio();

  String normalizarTexto(String texto) {
    return texto.toLowerCase().trim();
  }

  List<String> generarHorarios() {
    return ["06:00 AM", "09:00 AM", "01:00 PM", "05:00 PM", "10:00 PM"];
  }

  double extraerHoras(String duracionTexto) {
    double horas = 0;

    final regexDias = RegExp(r'(\d+)\s*(día|day)');
    final matchDias = regexDias.firstMatch(duracionTexto);
    if (matchDias != null) {
      horas += double.parse(matchDias.group(1)!) * 24;
    }

    final regexHoras = RegExp(r'(\d+)\s*(h|hour)');
    final matchHoras = regexHoras.firstMatch(duracionTexto);
    if (matchHoras != null) {
      horas += double.parse(matchHoras.group(1)!);
    }

    final regexMin = RegExp(r'(\d+)\s*(min)');
    final matchMin = regexMin.firstMatch(duracionTexto);
    if (matchMin != null) {
      horas += double.parse(matchMin.group(1)!) / 60;
    }

    return horas;
  }

  String calcularPrecio({
    required String distanciaTexto,
    required String duracionTexto,
  }) {
    final km =
        double.tryParse(distanciaTexto.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    final horas = extraerHoras(duracionTexto);

    double precio;

    if (horas <= 3) {
      precio = km * 0.9 + 80;
    } else if (horas <= 8) {
      precio = km * 1.0 + 150;
    } else if (horas <= 15) {
      precio = km * 1.2 + 300;
    } else {
      precio = km * 1.5 + (horas * 50) + 500;
    }

    if (horas > 20 && precio < 900) precio = 900;

    return precio.toStringAsFixed(0);
  }

  Future<List<RutaAutobus>> obtenerRutas({
    required String origen,
    required String destino,
  }) async {
    // 🔥 EN PARALELO
    final resultados = await Future.wait([
      google.buscarTerminalAutobus(origen),
      google.buscarTerminalAutobus(destino),
    ]);

    final terminalOrigen = resultados[0];
    final terminalDestino = resultados[1];

    final origenTexto = terminalOrigen?["nombre"] ?? origen;

    final destinoTexto = terminalDestino?["nombre"] ?? destino;

    final origenCoords = terminalOrigen != null
        ? "${terminalOrigen["lat"]},${terminalOrigen["lng"]}"
        : origen;

    final destinoCoords = terminalDestino != null
        ? "${terminalDestino["lat"]},${terminalDestino["lng"]}"
        : destino;

    final data = await google.obtenerRuta(
      origen: origenCoords,
      destino: destinoCoords,
    );

    if (data == null) return [];

    return [
      RutaAutobus(
        origen: origenTexto,
        destino: destinoTexto,
        duracion: data["duracion"],
        precio: calcularPrecio(
          distanciaTexto: data["distancia"],
          duracionTexto: data["duracion"],
        ),
        horarios: generarHorarios(),
      ),
    ];
  }
}
