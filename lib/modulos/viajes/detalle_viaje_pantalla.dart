import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/transporte_pantalla.dart';

class DetalleViajePantalla extends StatelessWidget {
  final String idViaje;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String descripcion;
  final String destino;
  final double destinoLat;
  final double destinoLng;
  final String origen;

  const DetalleViajePantalla({
    super.key,
    required this.idViaje,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.descripcion,
    required this.destino,
    required this.destinoLat,
    required this.destinoLng,
    required this.origen,
  });

  @override
  Widget build(BuildContext context) {
    final fechaInicioTexto =
        "${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}";
    final fechaFinTexto = "${fechaFin.day}/${fechaFin.month}/${fechaFin.year}";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0066D2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Color(0xFF0066D2)),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),

                      if (descripcion.isNotEmpty)
                        Text(
                          descripcion,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "$fechaInicioTexto - $fechaFinTexto",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // =========================
            // 🚗 TRANSPORTE (CORREGIDO)
            // =========================
            item(
              context,
              Icons.directions_car,
              "Transporte",
              "Opciones para llegar al destino",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransportePantalla(
                      origen: origen,
                      destino: destino,
                      destinoLat: destinoLat,
                      destinoLng: destinoLng,
                    ),
                  ),
                );
              },
            ),

            item(
              context,
              Icons.hotel,
              "Hospedaje",
              "Hoteles disponibles en la zona",
              onTap: () {
                Navigator.pushNamed(context, '/hospedaje');
              },
            ),

            item(
              context,
              Icons.backpack,
              "Maleta",
              "Lista recomendada para tu viaje",
              onTap: () {
                Navigator.pushNamed(context, '/maleta');
              },
            ),

            item(
              context,
              Icons.map,
              "Itinerario",
              "Planea tus actividades por día",
              onTap: () {
                Navigator.pushNamed(context, '/itinerario');
              },
            ),

            item(
              context,
              Icons.book,
              "Diario Personal",
              "Registra tus recuerdos",
              onTap: () {
                Navigator.pushNamed(context, '/diario');
              },
            ),

            const SizedBox(height: 10),

            Center(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('viajes')
                        .doc(idViaje)
                        .update({'cancelado': true});
              
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Viaje cancelado")),
                    );
              
                    Navigator.pop(context);
                  } catch (e) {
                    print("❌ Error cancelando: $e");
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade100),
                child: const Text("Cancelar viaje", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),

          ],
        ),
      ),
    );
  }

  Widget item(
    BuildContext context,
    IconData icono,
    String titulo,
    String subtitulo, {
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
          leading: Icon(icono, color: const Color(0xFF0066D2)),
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
