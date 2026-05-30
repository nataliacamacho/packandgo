import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/modulos/viajes/detalle_viaje_pantalla.dart';
import 'package:proyecto/nucleo/utilidades/formatear_destino.dart';
import 'crear_viaje_pantalla.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViajesPantalla extends StatelessWidget {
  const ViajesPantalla({super.key});

  Stream<QuerySnapshot> obtenerViajes() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("Usuario no autenticado");
    }

    return FirebaseFirestore.instance
        .collection("viajes")
        .where("usuarioId", isEqualTo: user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Viajes", style: GoogleFonts.poppins(fontSize: 36)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: obtenerViajes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar los viajes"));
          }

          // 🔥 FILTRAMOS AQUÍ (NO EN EL BUILDER)
          final viajes = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['eliminado'] != true;
          }).toList();

          // =========================
          // 🚨 SIN VIAJES
          // =========================
          if (viajes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.travel_explore,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 15),

                    Text(
                      "Aún no tienes viajes creados",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Crea tu primer viaje para empezar a planear todo.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF6A230),
                      ),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        "Crear viaje",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CrearViajePantalla(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          // =========================
          // 📦 LISTA
          // =========================
          return ListView.builder(
            itemCount: viajes.length,
            itemBuilder: (context, index) {
              final viaje = viajes[index];
              final data = viaje.data() as Map<String, dynamic>;

              final destinoFormateado = FormateadorDestino.formatear(data["destino"] ?? "Sin destino");
              final fechaInicio = (data["fechaInicio"] as Timestamp).toDate();
              final fechaFin = (data["fechaFin"] as Timestamp).toDate();

              final destinoLat = data["lat"] ?? 0.0;
              final destinoLng = data["lng"] ?? 0.0;

              final cancelado = data["cancelado"] ?? false;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(destinoFormateado)),

                      // 🔥 ETIQUETA CANCELADO
                      if (cancelado)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "CANCELADO",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  subtitle: Text(
                    "${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year} - "
                    "${fechaFin.day}/${fechaFin.month}/${fechaFin.year}",
                  ),

                  // ❌ SIN BOTÓN
                  trailing: null,

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalleViajePantalla(
                          nombre: destinoFormateado,
                          fechaInicio: fechaInicio,
                          fechaFin: fechaFin,
                          descripcion: data["descripcion"] ?? "",
                          idViaje: viaje.id,
                          destino: destinoFormateado,
                          destinoLat: destinoLat,
                          destinoLng: destinoLng,
                          origen: (data["origen"] as String?) ?? "Sin origen",
                          tipoViaje: (data["tipoViaje"] as String?) ?? "Desconocido",
                          actividades: (data["actividades"] as List<dynamic>?) ?? [],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
