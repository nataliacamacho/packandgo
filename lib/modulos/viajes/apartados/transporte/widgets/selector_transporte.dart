import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/avion/avion_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/carro/carro_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/mixtas/rutamixta_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/autobus/autobus_pantalla.dart';
import 'package:proyecto/nucleo/utilidades/formatear_destino.dart';
import 'package:proyecto/nucleo/utilidades/destinos_corregidos.dart';

class SelectorTransporte extends StatelessWidget {
  final double destinoLat;
  final double destinoLng;
  final String destinoNombre;
  final String origen;

  const SelectorTransporte({
    super.key,
    required this.destinoLat,
    required this.destinoLng,
    required this.destinoNombre,
    required this.origen,
  });

  @override
  Widget build(BuildContext context) {
    final destinoFormateado = FormateadorDestino.formatear(destinoNombre);

    double latCorregida = destinoLat;
    double lngCorregida = destinoLng;
    String nombreCorregido = destinoFormateado;

    final correccion = DestinosCorregidos.obtener(destinoFormateado);

    if (correccion != null) {
      latCorregida = correccion["lat"];
      lngCorregida = correccion["lng"];
      nombreCorregido = correccion["nombre"];

      debugPrint("DESTINO CORREGIDO");
      debugPrint("NUEVA LAT: $latCorregida");
      debugPrint("NUEVA LNG: $lngCorregida");
    }

    // ================= LÓGICA INTELIGENTE =================

    final distanciaAprox = _calcularDistanciaSimple(
      20.6597, // Guadalajara aprox origen demo
      -103.3496,
      latCorregida,
      lngCorregida,
    );

    final mostrarAvion = distanciaAprox > 350;

    final mostrarRutaMixta = distanciaAprox > 500;

    String? recomendado;

    if (distanciaAprox < 250) {
      recomendado = "Carro";
    } else if (distanciaAprox < 500) {
      recomendado = "Autobús";
    } else {
      recomendado = "Ruta mixta";
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _cardTransporte(
            context,
            titulo: "Carro",
            subtitulo: "Ruta directa en carretera",
            icono: Icons.directions_car,
            color: const Color(0xFF0066D2),
            recomendado: recomendado == "Carro",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CarroPantalla(
                    destinoLat: destinoLat,
                    destinoLng: destinoLng,
                    destinoNombre: destinoFormateado,
                    origen: origen,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          _cardTransporte(
            context,
            titulo: "Autobús",
            subtitulo: "Opciones de central de autobuses",
            icono: Icons.directions_bus,
            color: Colors.green,
            recomendado: recomendado == "Autobús",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaAutobus(
                    destino: destinoFormateado,
                    destinoLat: destinoLat,
                    destinoLng: destinoLng,
                    origen: origen,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          if (mostrarAvion)
            _cardTransporte(
              context,
              titulo: "Avión",
              subtitulo: "Viajes en avión disponibles",
              icono: Icons.flight,
              color: const Color.fromRGBO(255, 152, 0, 1),
              recomendado: recomendado == "Avión",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PantallaAvion(
                      destino: destinoFormateado,
                      origen: origen,
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 10),

          if (mostrarRutaMixta)
            _cardTransporte(
              context,
              titulo: "Ruta mixta",
              subtitulo: "Combinación de transportes",
              icono: Icons.alt_route,
              color: Colors.purple,
              recomendado: recomendado == "Ruta mixta",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RutaMixtaPantalla(
                      destinoLat: latCorregida,
                      destinoLng: lngCorregida,
                      origen: origen,
                      destinoNombre: nombreCorregido,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  double _calcularDistanciaSimple(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;

    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;

    return 12742 * asin(sqrt(a));
  }

  Widget _cardTransporte(
    BuildContext context, {
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
    bool recomendado = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(icono, color: color),

          title: Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              if (recomendado)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Recomendado",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          subtitle: Text(subtitulo, style: GoogleFonts.poppins(fontSize: 14)),

          onTap: onTap,
        ),
      ),
    );
  }
}
