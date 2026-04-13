import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/modulos/viajes/detalle_viaje_pantalla.dart';
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

  void mostrarDialogoEliminar(BuildContext context, String idViaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar viaje"),
        content: const Text("¿Seguro que quieres eliminar este viaje?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("viajes")
                  .doc(idViaje)
                  .delete();

              Navigator.pop(context);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Viaje eliminado")));
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
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

          final viajes = snapshot.data?.docs ?? [];

          if (viajes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    child: Text(
                      "Todavía no tienes viajes creados. ¡Crea tu primer viaje para empezar a planificar tus aventuras!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF6A230),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CrearViajePantalla(),
                        ),
                      );
                    },
                    child: const Text(
                      "Crear viaje",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: viajes.length,
            itemBuilder: (context, index) {
              final viaje = viajes[index];
              final data = viaje.data() as Map<String, dynamic>;

              final destino = data["destino"] ?? "Sin destino";

              final fechaInicio = (data["fechaInicio"] as Timestamp).toDate();
              final fechaFin = (data["fechaFin"] as Timestamp).toDate();

              final destinoLat = data["lat"] ?? 0.0;
              final destinoLng = data["lng"] ?? 0.0;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(destino),

                  subtitle: Text(
                    "${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year} - "
                    "${fechaFin.day}/${fechaFin.month}/${fechaFin.year}",
                  ),

                  // 🔥 BOTÓN DE ELIMINAR (MEJOR UX)
                  trailing: SizedBox(
                    width: 40,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        print(
                          "UID actual: ${FirebaseAuth.instance.currentUser!.uid}",
                        );
                        print("UID del viaje: ${data["usuarioId"]}");
                        mostrarDialogoEliminar(context, viaje.id);
                      },
                    ),
                  ),

                  // 🔥 NAVEGACIÓN A DETALLE
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalleViajePantalla(
                          nombre: destino,
                          fechaInicio: fechaInicio,
                          fechaFin: fechaFin,
                          descripcion: data["descripcion"] ?? "",
                          idViaje: viaje.id,
                          destino: destino,
                          destinoLat: destinoLat,
                          destinoLng: destinoLng,
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
