import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItinerarioServicio {
  // RQF120: Calcula la lista de días restando fecha de inicio y fecha de fin
  static List<DateTime> generarListaDias(DateTime inicio, DateTime fin) {
    List<DateTime> dias = [];
    for (int i = 0; i <= fin.difference(inicio).inDays; i++) {
      dias.add(inicio.add(Duration(days: i)));
    }
    return dias;
  }

  // RQF129 / RQNF45: Guardar itinerario completo en Firebase con todos los campos
  // para que RQF127 (foto, nombre, categoría) funcione también al recargar
  static Future<void> guardarItinerarioEnFirebase(
    String idViaje,
    Map<String, List<Map<String, dynamic>>> itinerario,
  ) async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (uid.isEmpty) return;

    try {
      Map<String, dynamic> datosParaFirebase = {};

      itinerario.forEach((fecha, lugares) {
        datosParaFirebase[fecha] = lugares
            .map(
              (lugar) => {
                // Campos mínimos para mostrar en itinerario (RQF127)
                "nombre": lugar["nombre"] ?? "",
                "categoria": lugar["categoria"] ?? "",
                "lat": lugar["lat"] ?? 0.0,
                "lng": lugar["lng"] ?? 0.0,
                // Campos extra para detalle del lugar
                "foto": lugar["foto"] ?? "",
                "rating": lugar["rating"] ?? 0.0,
                "direccion": lugar["direccion"] ?? "",
                // RQF123: guardamos los horarios reales para poder revalidar después
                "hours": lugar["hours"] ?? "",
              },
            )
            .toList();
      });

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('viajes')
          .doc(idViaje)
          .set({"itinerario": datosParaFirebase}, SetOptions(merge: true));

      print("✅ Itinerario guardado con éxito");
    } catch (e) {
      print("❌ Error al guardar el itinerario: $e");
    }
  }
}