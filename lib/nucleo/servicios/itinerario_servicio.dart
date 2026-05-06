import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItinerarioServicio {
  // Calcula la lista de días entre dos fechas para mostrar en la pantalla
  static List<DateTime> generarListaDias(DateTime inicio, DateTime fin) {
    List<DateTime> dias = [];
    for (int i = 0; i <= fin.difference(inicio).inDays; i++) {
      dias.add(inicio.add(Duration(days: i)));
    }
    return dias;
  }

  // Verifica disponibilidad según el DER (Foursquare/OpenTripMap)
  static bool verificarApertura(DateTime fecha, Map<String, dynamic>? horas) {
    if (horas == null) return true; // Si no hay info, permitimos agregar

    int diaBuscado = fecha.weekday; // 1=Lunes, 7=Domingo
    List<dynamic> periodos = horas['regular'] ?? [];

    // Buscamos si el día de la semana está en los periodos de apertura
    return periodos.any((p) => p['day'] == diaBuscado);
  }

  // Mensaje de error exacto de la propuesta
  static void mostrarAlertaCerrado(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Lugar no disponible"),
        content: const Text(
          "Este lugar no estará disponible el día seleccionado. ¿Deseas elegir otro día o lugar?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  //  FASE 4: Guardar el itinerario en Firebase
  static Future<void> guardarItinerarioEnFirebase(
    String idViaje,
    Map<String, List<Map<String, dynamic>>> itinerario,
  ) async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (uid.isEmpty) return;

    try {
      // Convertimos el mapa complejo a algo que Firebase entienda fácilmente
      Map<String, dynamic> datosParaFirebase = {};

      itinerario.forEach((fecha, lugares) {
        // Extraemos solo la info básica del lugar para no saturar la base de datos
        datosParaFirebase[fecha] = lugares
            .map(
              (lugar) => {
                "nombre": lugar["nombre"], // 🔥 CORRECTO
                "lat": lugar["lat"],
                "lng": lugar["lng"],
                "categoria": lugar["categoria"], // 🔥 CORRECTO
              },
            )
            .toList();
      });

      // Guardamos en la sub-colección del viaje específico
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
