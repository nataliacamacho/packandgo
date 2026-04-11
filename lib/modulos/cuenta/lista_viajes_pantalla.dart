import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/modulos/viajes/detalle_viaje_pantalla.dart';

class ListaViajesPantalla extends StatelessWidget {
  final String titulo;
  final List<QueryDocumentSnapshot> viajes;

  const ListaViajesPantalla({
    super.key,
    required this.titulo,
    required this.viajes,
  });

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

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Viaje eliminado")),
              );
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fecha actual
    final hoy = DateTime.now();

    // Filtrar y ordenar viajes futuros
    final viajesFuturos = viajes
        .where((viaje) {
          final data = viaje.data() as Map<String, dynamic>;
          final fechaInicio = (data["fechaInicio"] as Timestamp).toDate();
          return fechaInicio.isAfter(hoy) || fechaInicio.isAtSameMomentAs(hoy);
        })
        .toList()
      ..sort((a, b) {
        final fechaA = (a.data() as Map<String, dynamic>)["fechaInicio"] as Timestamp;
        final fechaB = (b.data() as Map<String, dynamic>)["fechaInicio"] as Timestamp;
        return fechaA.toDate().compareTo(fechaB.toDate()); // del más cercano al más lejano
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: viajesFuturos.isEmpty
          ? Center(child: Text("No se encontraron $titulo"))
          : ListView.builder(
              itemCount: viajesFuturos.length,
              itemBuilder: (context, index) {
                final viaje = viajesFuturos[index];
                final data = viaje.data() as Map<String, dynamic>;

                final destino = data["destino"] ?? "Sin destino";

                final fechaInicio = (data["fechaInicio"] as Timestamp).toDate();
                final fechaFin = (data["fechaFin"] as Timestamp).toDate();

                return Card(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  margin: const EdgeInsets.all(12),
                  surfaceTintColor: Colors.transparent,
                  elevation: 3,
                  child: ListTile(
                    title: Text(destino),
                    subtitle: Text(
                      "${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}",
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalleViajePantalla(
                            nombre: destino,
                            fechaInicio: fechaInicio,
                            fechaFin: fechaFin,
                            descripcion: data["descripcion"] ?? "",
                            idViaje: viaje.id,
                            destino: '',
                          ),
                        ),
                      );
                    },
                    onLongPress: () {
                      print("UID actual: ${FirebaseAuth.instance.currentUser!.uid}");
                      print("UID del viaje: ${data["usuarioId"]}");
                      mostrarDialogoEliminar(context, viaje.id);
                    },
                  ),
                );
              },
            ),
    );
  }
}