import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/avion/avion_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/carro/carro_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/mixtas/rutamixta_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/autobus/autobus_pantalla.dart';
import 'package:proyecto/nucleo/servicios/mapbox_servicio.dart';
import 'package:proyecto/nucleo/servicios/ubicacion_servicio.dart';
import 'package:proyecto/nucleo/utilidades/formatear_destino.dart';
import 'package:proyecto/nucleo/utilidades/destinos_corregidos.dart';

class SelectorTransporte extends StatefulWidget {
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
  State<SelectorTransporte> createState() => _SelectorTransporteState();
}

class _SelectorTransporteState extends State<SelectorTransporte> {
  final _mapbox = MapboxServicio();
  final _ubicacion = UbicacionServicio();

  double? _distanciaReal;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDistancia();
  }

  // RQNF26 — usar Mapbox para verificar distancia real
  Future<void> _cargarDistancia() async {
    try {
      final pos = await _ubicacion.obtenerUbicacionActual();
      if (pos == null) {
        setState(() => _cargando = false);
        return;
      }

      final data = await _mapbox.obtenerRuta(
        origenLat: pos.latitude,
        origenLng: pos.longitude,
        destinoLat: widget.destinoLat,
        destinoLng: widget.destinoLng,
      );

      setState(() {
        _distanciaReal = data != null
            ? (data['distancia'] as num) / 1000
            : null;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  double _distanciaSimple(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final destinoFormateado = FormateadorDestino.formatear(
      widget.destinoNombre,
    );

    double latCorregida = widget.destinoLat;
    double lngCorregida = widget.destinoLng;
    String nombreCorregido = destinoFormateado;

    final correccion = DestinosCorregidos.obtener(destinoFormateado);
    if (correccion != null) {
      latCorregida = correccion["lat"];
      lngCorregida = correccion["lng"];
      nombreCorregido = correccion["nombre"];
    }

    // Usar distancia real de Mapbox si está disponible (RQNF26)
    final distanciaAprox =
        _distanciaReal ??
        _distanciaSimple(20.6597, -103.3496, latCorregida, lngCorregida);

    // RQF66 — recomendación por menor tiempo y costo
    final costoAvion = (distanciaAprox * 2.5).clamp(900.0, 15000.0);
    final costoAutobus = distanciaAprox * 1.1 + 150;
    final costoCarro = distanciaAprox * 2.0;

    final tiempoAvion = (distanciaAprox / 800) + 2;
    final tiempoAutobus = distanciaAprox / 75;
    final tiempoCarro = distanciaAprox / 85;

    final scoreCarro = tiempoCarro * 0.6 + (costoCarro / 1000) * 0.4;
    final scoreAutobus = tiempoAutobus * 0.6 + (costoAutobus / 1000) * 0.4;
    final scoreAvion = distanciaAprox > 350
        ? tiempoAvion * 0.6 + (costoAvion / 1000) * 0.4
        : double.infinity;
    final scoreMixta = distanciaAprox > 500
        ? (tiempoAvion + 1) * 0.6 + ((costoAvion + costoAutobus) / 2000) * 0.4
        : double.infinity;

    final scores = <String, double>{
      'Carro': scoreCarro,
      'Autobús': scoreAutobus,
      if (distanciaAprox > 350) 'Avión': scoreAvion,
      if (distanciaAprox > 500) 'Ruta mixta': scoreMixta,
    };

    final recomendado = scores.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;

    final bool mostrarAvion = distanciaAprox > 350;
    final bool mostrarRutaMixta = distanciaAprox > 500;

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
            tiempoEstimado: "${(tiempoCarro).toStringAsFixed(1)} h",
            costoEstimado: "\$${costoCarro.toStringAsFixed(0)}",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CarroPantalla(
                    destinoLat: widget.destinoLat,
                    destinoLng: widget.destinoLng,
                    destinoNombre: destinoFormateado,
                    origen: widget.origen,
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
            tiempoEstimado: "${tiempoAutobus.toStringAsFixed(1)} h",
            costoEstimado: "\$${costoAutobus.toStringAsFixed(0)}",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaAutobus(
                    destino: destinoFormateado,
                    destinoLat: widget.destinoLat,
                    destinoLng: widget.destinoLng,
                    origen: widget.origen,
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
              subtitulo: "Vuelos disponibles",
              icono: Icons.flight,
              color: const Color(0xFFF6A230),
              recomendado: recomendado == "Avión",
              tiempoEstimado: "${tiempoAvion.toStringAsFixed(1)} h",
              costoEstimado: "\$${costoAvion.toStringAsFixed(0)}",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PantallaAvion(
                      destino: destinoFormateado,
                      origen: widget.origen,
                    ),
                  ),
                );
              },
            ),

          if (mostrarAvion) const SizedBox(height: 10),

          if (mostrarRutaMixta)
            _cardTransporte(
              context,
              titulo: "Ruta mixta",
              subtitulo: "Combinación de transportes",
              icono: Icons.alt_route,
              color: Colors.purple,
              recomendado: recomendado == "Ruta mixta",
              tiempoEstimado: "${(tiempoAvion + 1).toStringAsFixed(1)} h",
              costoEstimado:
                  "\$${((costoAvion + costoAutobus) / 2).toStringAsFixed(0)}",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RutaMixtaPantalla(
                      destinoLat: latCorregida,
                      destinoLng: lngCorregida,
                      origen: widget.origen,
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

  Widget _cardTransporte(
    BuildContext context, {
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
    required String tiempoEstimado,
    required String costoEstimado,
    bool recomendado = false,
  }) {
    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitulo, style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: Colors.grey),
                const SizedBox(width: 3),
                Text(
                  tiempoEstimado,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.attach_money, size: 12, color: Colors.grey),
                Text(
                  costoEstimado,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
