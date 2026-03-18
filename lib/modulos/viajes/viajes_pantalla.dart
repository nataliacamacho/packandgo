import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/modulos/viajes/detalle_viaje_pantalla.dart';
import 'crear_viaje_pantalla.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViajesPantalla extends StatelessWidget {
  const ViajesPantalla({super.key});

  Stream<QuerySnapshot> obtenerViajes() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection("viajes")
        .where("usuarioId", isEqualTo: uid)
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
              final destino = viaje["destino"];

              final fechaInicio = viaje["fechaInicio"].toDate();
              final fechaFin = viaje["fechaFin"].toDate();

              return Card(
                margin: const EdgeInsets.all(12),
                color: const Color.fromARGB(255, 255, 255, 255),

                child: ListTile(
                  title: Text(destino),

                  subtitle: Text(
                    "${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year} - "
                    "${fechaFin.day}/${fechaFin.month}/${fechaFin.year}",
                  ),

                  onLongPress: () {
                    mostrarDialogoEliminar(context, viaje.id);
                  },

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalleViajePantalla(
                          nombre: destino,
                          fechaInicio: fechaInicio,
                          fechaFin: fechaFin,
                          descripcion: viaje["descripcion"] ?? "",
                          idViaje: viaje.id,
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
