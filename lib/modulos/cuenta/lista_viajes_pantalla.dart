import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/modulos/viajes/detalle_viaje_pantalla.dart';
import 'package:proyecto/nucleo/utilidades/viaje_estado.dart';

class ListaViajesPantalla extends StatelessWidget {
  final String titulo;

  const ListaViajesPantalla({super.key, required this.titulo});

  // 🔥 PARSE SEGURO
  DateTime? _parseFecha(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // 🔥 COLOR POR ESTADO
  Color obtenerColor(EstadoViaje estado) {
    switch (estado) {
      case EstadoViaje.futuro:
        return Colors.blue;
      case EstadoViaje.actual:
        return Colors.green;
      case EstadoViaje.pasado:
        return Colors.grey;
      case EstadoViaje.cancelado:
        return Colors.red.shade300;
    }
  }

  void mostrarDialogoEliminar(BuildContext context, String idViaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
        title: Text(titulo),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('viajes')
            .where(
              'usuarioId',
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final viajes = snapshot.data!.docs;

          // 🔥 LISTAS POR ESTADO
          final viajesActuales = <QueryDocumentSnapshot>[];
          final viajesFuturos = <QueryDocumentSnapshot>[];
          final viajesPasados = <QueryDocumentSnapshot>[];

          for (var doc in viajes) {
            final data = doc.data() as Map<String, dynamic>;

            final fechaInicio = _parseFecha(data['fechaInicio']);
            final fechaFin = _parseFecha(data['fechaFin']);

            if (fechaInicio == null || fechaFin == null) {
              print("❌ Error en fechas: ${doc.id}");
              continue;
            }

            final cancelado = data['cancelado'] ?? false;

            final estado = ViajeEstadoUtil.obtenerEstado(
              fechaInicio: fechaInicio,
              fechaFin: fechaFin,
              cancelado: cancelado,
            );

            switch (estado) {
              case EstadoViaje.actual:
                viajesActuales.add(doc);
                break;

              case EstadoViaje.futuro:
                viajesFuturos.add(doc);
                break;

              case EstadoViaje.pasado:
                viajesPasados.add(doc);
                break;

              case EstadoViaje.cancelado:
                viajesPasados.add(doc);
                break;
            }
          }

          print("🔥 ACTUALES: ${viajesActuales.length}");
          print("🔥 FUTUROS: ${viajesFuturos.length}");
          print("🔥 PASADOS: ${viajesPasados.length}");

          // 🎯 FILTRO POR TÍTULO
          List<QueryDocumentSnapshot> lista;
          final t = titulo.toLowerCase();

          if (t.contains("futuro")) {
            lista = viajesFuturos;
          } else if (t.contains("pasado")) {
            lista = viajesPasados;
          } else {
            lista = viajesActuales;
          }

          if (lista.isEmpty) {
            return const Center(child: Text("No se encontraron viajes"));
          }

          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final viaje = lista[index];
              final data = viaje.data() as Map<String, dynamic>;

              final destino = data["destino"] ?? "Sin destino";
              final descripcion = data["descripcion"] ?? "";
              final origen = data["origen"] ?? "Sin origen";

              final fechaInicio = _parseFecha(data['fechaInicio'])!;
              final fechaFin = _parseFecha(data['fechaFin'])!;

              final lat = (data["lat"] is num)
                  ? (data["lat"] as num).toDouble()
                  : 0.0;

              final lng = (data["lng"] is num)
                  ? (data["lng"] as num).toDouble()
                  : 0.0;

              final cancelado = data['cancelado'] ?? false;

              final estado = ViajeEstadoUtil.obtenerEstado(
                fechaInicio: fechaInicio,
                fechaFin: fechaFin,
                cancelado: cancelado,
              );

              return Card(
                margin: const EdgeInsets.all(12),
                color: obtenerColor(estado),
                child: ListTile(
                  title: Text(destino),
                  subtitle: Text(
                    "${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year} - ${ViajeEstadoUtil.textoEstado(estado)}",
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalleViajePantalla(
                          idViaje: viaje.id,
                          nombre: destino,
                          fechaInicio: fechaInicio,
                          fechaFin: fechaFin,
                          descripcion: descripcion,
                          destino: destino,
                          destinoLat: lat,
                          destinoLng: lng,
                          origen: origen,
                        ),
                      ),
                    );
                  },
                  onLongPress: () {
                    mostrarDialogoEliminar(context, viaje.id);
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
