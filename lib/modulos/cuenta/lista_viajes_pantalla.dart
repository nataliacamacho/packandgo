import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/modulos/viajes/detalle_viaje_pantalla.dart';
import 'package:proyecto/nucleo/utilidades/formatear_destino.dart';
import 'package:proyecto/nucleo/utilidades/viaje_estado.dart';

class ListaViajesPantalla extends StatelessWidget {
  final EstadoViaje tipo;

  const ListaViajesPantalla({super.key, required this.tipo});

  DateTime? _parseFecha(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Color obtenerColor(bool cancelado, EstadoViaje estado, dynamic realizado) {
    if (cancelado) return Colors.orange.shade200;

    switch (estado) {
      case EstadoViaje.futuro:
        return Colors.blue.shade100;
      case EstadoViaje.actual:
        return Colors.green.shade100;
      case EstadoViaje.pasado:
        if (realizado == true) return Colors.green.shade200;
        if (realizado == false) return Colors.red.shade200;
        return Colors.grey.shade300;
    }
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

  void mostrarDialogoEliminarDefinitivo(BuildContext context, String idViaje) {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        // 🔥 HEADER CON ICONO
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              "Eliminar viaje",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        // 🔥 CONTENIDO
        content: const Text(
          "Este viaje se eliminará PERMANENTEMENTE.\n\n"
          "⚠️ No podrás recuperarlo después.",
          style: TextStyle(fontSize: 14),
        ),

        actionsAlignment: MainAxisAlignment.center,

        actions: [
          // 🔹 CANCELAR
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),

          const SizedBox(width: 8),

          // 🔹 ELIMINAR (PELIGRO)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("viajes")
                  .doc(idViaje)
                  .delete();

              Navigator.pop(dialogContext);

              messenger.clearSnackBars();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text("Viaje eliminado"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _textoEstadoLabel(EstadoViaje estado, bool cancelado) {
    if (cancelado) return "Cancelado";

    switch (estado) {
      case EstadoViaje.actual:
        return "Actual";
      case EstadoViaje.futuro:
        return "Futuro";
      case EstadoViaje.pasado:
        return "Pasado";
    }
  }

  Color _colorEstadoLabel(EstadoViaje estado) {
    switch (estado) {
      case EstadoViaje.actual:
        return Colors.green;
      case EstadoViaje.futuro:
        return Colors.blue;
      case EstadoViaje.pasado:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tipo == EstadoViaje.actual
              ? "Viajes actuales"
              : tipo == EstadoViaje.futuro
              ? "Viajes futuros"
              : "Viajes pasados",
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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

          final actuales = <QueryDocumentSnapshot>[];
          final futuros = <QueryDocumentSnapshot>[];
          final pasados = <QueryDocumentSnapshot>[];

          for (var doc in viajes) {
            final data = doc.data() as Map<String, dynamic>;

            if (data['eliminado'] == true) continue;

            final fechaInicio = _parseFecha(data['fechaInicio']);
            final fechaFin = _parseFecha(data['fechaFin']);

            if (fechaInicio == null || fechaFin == null) continue;

            final cancelado = data['cancelado'] ?? false;

            if (cancelado) {
              pasados.add(doc);
              continue;
            }

            final estado = ViajeEstadoUtil.obtenerEstado(
              fechaInicio: fechaInicio,
              fechaFin: fechaFin,
            );

            if (estado == EstadoViaje.actual) actuales.add(doc);
            if (estado == EstadoViaje.futuro) futuros.add(doc);
            if (estado == EstadoViaje.pasado) pasados.add(doc);
          }

          List<QueryDocumentSnapshot> lista;

          if (tipo == EstadoViaje.actual)
            lista = actuales;
          else if (tipo == EstadoViaje.futuro)
            lista = futuros;
          else
            lista = pasados;

          if (lista.isEmpty) {
            return const Center(child: Text("No se encontraron viajes"));
          }

          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final viaje = lista[index];
              final data = viaje.data() as Map<String, dynamic>;
              final destinoRaw = data["destino"] ?? "Sin destino";

              final destino = FormateadorDestino.formatear(destinoRaw);
              final descripcion = data["descripcion"] ?? "";
              final origen = data["origen"] ?? "Sin origen";

              final fechaInicio = _parseFecha(data['fechaInicio'])!;
              final fechaFin = _parseFecha(data['fechaFin'])!;

              final lat = (data["lat"] as num?)?.toDouble() ?? 0.0;
              final lng = (data["lng"] as num?)?.toDouble() ?? 0.0;

              final realizado = data['realizado'];
              final cancelado = data['cancelado'] ?? false;

              // 🔥 AQUÍ ESTÁ LA CLAVE
              final estadoBase = ViajeEstadoUtil.obtenerEstado(
                fechaInicio: fechaInicio,
                fechaFin: fechaFin,
              );

              final estadoFinal = cancelado ? EstadoViaje.pasado : estadoBase;

              return Card(
                margin: const EdgeInsets.all(12),
                color: obtenerColor(cancelado, estadoFinal, realizado),
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          destino,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      // 🔥 ETIQUETA DE ESTADO
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _colorEstadoLabel(estadoFinal),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _textoEstadoLabel(estadoFinal, cancelado),
                          style: const TextStyle(
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalleViajePantalla(
                          nombre: destino,
                          fechaInicio: fechaInicio,
                          fechaFin: fechaFin,
                          descripcion: descripcion,
                          idViaje: viaje.id,
                          destino: destino,
                          destinoLat: lat,
                          destinoLng: lng,
                          origen: origen,
                        ),
                      ),
                    );
                  },
                  onLongPress: () {
                    if (estadoFinal == EstadoViaje.pasado) {
                      mostrarDialogoEliminarDefinitivo(context, viaje.id);
                    } else {
                      mostrarDialogoCancelar(context, viaje.id);
                    }
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
