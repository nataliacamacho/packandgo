import 'package:cloud_firestore/cloud_firestore.dart';

class ViajeServicio {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> crearViaje({
    required String destino,
    required String descripcion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required double lat,
    required double lng,
    required String origen,
    required String usuarioId,
    required List<String> actividades,
  }) async {

    final viajeData = {
      "usuarioId": usuarioId,
      "destino": destino.trim(),
      "descripcion": descripcion.trim(),
      "fechaInicio": Timestamp.fromDate(fechaInicio),
      "fechaFin": Timestamp.fromDate(fechaFin),
      "lat": lat,
      "lng": lng,
      "origen": origen.trim(),

      "cancelado": false,
      "realizado": null,
      "eliminado": false,

      "fechaCreacion": FieldValue.serverTimestamp(),

      // NUEVO
      "estado": "proximo",
      "cantidadDias":
          fechaFin.difference(fechaInicio).inDays + 1,
      "actividades": actividades,
    };

    // =========================
    // VIAJE GLOBAL
    // =========================
    final doc = await _firestore
        .collection("viajes")
        .add(viajeData);

    // =========================
    // VIAJE DENTRO DEL USUARIO
    // =========================
    await _firestore
        .collection("usuarios")
        .doc(usuarioId)
        .collection("viajes")
        .doc(doc.id)
        .set(viajeData);

    return doc.id;
  }
}