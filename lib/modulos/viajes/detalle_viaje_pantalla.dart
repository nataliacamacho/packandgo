import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DetalleViajePantalla extends StatelessWidget {
  final String idViaje;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String descripcion;

  const DetalleViajePantalla({
    super.key,
    required this.idViaje,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.descripcion, required String destino,
  });

  @override
  Widget build(BuildContext context) {
    String fechaInicioTexto =
        "${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}";

    String fechaFinTexto = "${fechaFin.day}/${fechaFin.month}/${fechaFin.year}";

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
                        descripcion.isNotEmpty ? "$descripcion" : "",
                        style: GoogleFonts.poppins(
                          color: const Color.fromARGB(179, 255, 255, 255),
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

            item(Icons.directions_car, "Transporte", "Opciones para llegar al destino"),
            item(Icons.hotel, "Hospedaje", "Hoteles disponibles en la zona"),
            item(Icons.backpack, "Maleta", "Lista recomendada para tu viaje"),
            item(Icons.map, "Itinerario", "Planea tus actividades por día"),
            item(Icons.book, "Diario Personal", "Registra tus recuerdos"),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget item(IconData icono, String titulo, String subtitulo) {
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
          leading: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: const Color(0xFF0066D2)),
          ),
          title: Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(subtitulo, style: GoogleFonts.poppins(
              fontSize: 14,
            ),
            ),
         
          onTap: () {},
        ),
      ),
    );
  }
}
