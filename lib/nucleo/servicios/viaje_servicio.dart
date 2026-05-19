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
  }) async {
    final doc = await _firestore.collection("viajes").add({
      "usuarioId": usuarioId,
      "destino": destino,
      "descripcion": descripcion,
      "fechaInicio": fechaInicio,
      "fechaFin": fechaFin,
      "lat": lat,
      "lng": lng,
      "origen": origen,
      "cancelado": false,
      "realizado": null,
      "eliminado": false,
    });

    return doc.id;
  }
}
