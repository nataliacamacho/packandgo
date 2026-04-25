import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/modulos/viajes/apartados/hospedaje/hospedaje_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/maleta/maleta_pantalla.dart';
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

  bool yaTerminoViaje() {
    final hoy = DateTime.now();

    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);

    return hoySinHora.isAfter(fin);
  }

  void mostrarDialogoCancelar(BuildContext context, String idViaje) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        // 🔥 HEADER
        title: Row(
          children: const [
            Icon(Icons.cancel_outlined, color: Color(0xFFF6A230)),
            SizedBox(width: 8),
            Text(
              "Cancelar viaje",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        // 🔥 CONTENIDO
        content: const Text(
          "Este viaje se marcará como CANCELADO y pasará a viajes pasados.",
          style: TextStyle(fontSize: 14),
        ),

        actionsAlignment: MainAxisAlignment.center,

        actions: [
          // 🔹 NO
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),

          const SizedBox(width: 8),

          // 🔹 SÍ CANCELAR
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF6A230), // 👈 naranja app
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("viajes")
                  .doc(idViaje)
                  .update({'cancelado': true});

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Viaje cancelado"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fechaInicioTexto =
        "${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}";
    final fechaFinTexto = "${fechaFin.day}/${fechaFin.month}/${fechaFin.year}";

    final viajeTerminado = yaTerminoViaje();

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HospedajePantalla(
                      lat: destinoLat,
                      lng: destinoLng,
                      fechaInicio: fechaInicio,
                      fechaFin: fechaFin,
                      destino: destino,
                    ),
                  ),
                );
              },
            ),

            item(
              context,
              Icons.backpack,
              "Maleta",
              "Lista recomendada para tu viaje",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MaletaPantalla(idViaje: idViaje, destino: destino),
                  ),
                );
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

            const SizedBox(height: 20),

            // 🔥 BOTONES SOLO SI YA TERMINÓ
            if (viajeTerminado)
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('viajes')
                              .doc(idViaje)
                              .update({'realizado': true});

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Viaje realizado")),
                          );

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade300,
                        ),
                        child: const Text(
                          "Se realizó",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('viajes')
                            .doc(idViaje)
                            .update({'realizado': false});

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No se realizó")),
                        );

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade300,
                      ),
                      child: const Text(
                        "No se realizó",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

            // 🔥 MENSAJE SI AÚN NO TERMINA
            /*if (!viajeTerminado)
              const Padding(
                padding: EdgeInsets.all(5),
                child: Center(
                  child: Text(
                    "Podrás marcar este viaje cuando termine",
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                    
                  ),
                ),
              ),

            const SizedBox(height: 20),*/

            // SOLO PARTE IMPORTANTE (AGREGAR BOTÓN CANCELAR)
            if (!viajeTerminado)
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Center(
                  child: SizedBox(
                    child: ElevatedButton(
                      onPressed: () {
                        mostrarDialogoCancelar(context, idViaje);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text(
                        "Cancelar viaje",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
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
