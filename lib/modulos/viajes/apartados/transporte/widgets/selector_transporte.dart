import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/avion/avion_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/carro/carro_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/mixtas/rutamixta_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/autobus/autobus_pantalla.dart';
import 'package:proyecto/nucleo/utilidades/formatear_destino.dart';

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

          _cardTransporte(
            context,
            titulo: "Avión",
            subtitulo: "Viajes en avión disponibles",
            icono: Icons.flight,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PantallaAvion(destino: destinoFormateado, origen: origen),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          _cardTransporte(
            context,
            titulo: "Ruta mixta",
            subtitulo: "Combinación de transportes",
            icono: Icons.alt_route,
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RutaMixtaPantalla(
                    destinoLat: destinoLat,
                    destinoLng: destinoLng,
                    origen: origen,
                    destinoNombre: destinoFormateado,
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

          title: Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          subtitle: Text(subtitulo, style: GoogleFonts.poppins(fontSize: 14)),

          onTap: onTap,
        ),
      ),
    );
  }
}
