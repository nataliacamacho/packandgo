import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViajeServicio {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> crearViaje({
    required String destino,
    required String descripcion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required double lat,
    required double lng,
    required String origen, required String usuarioId,
  }) async {
    final doc = await FirebaseFirestore.instance.collection("viajes").add({
      "usuarioId": usuarioId,
      "destino": destino,
      "descripcion": descripcion,
      "fechaInicio": fechaInicio,
      "fechaFin": fechaFin,
      "lat": lat,
      "lng": lng,
      "origen": origen,
      "cancelado": false,
    });

    return doc.id;
  }
}
