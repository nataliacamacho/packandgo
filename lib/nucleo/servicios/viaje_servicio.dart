import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViajeServicio {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> crearViaje({
    required String destino,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String descripcion,
    required double lat,
    required double lng,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Usuario no autenticado");
    }

    final doc = await _firestore.collection("viajes").add({
      "usuarioId": user.uid,
      "destino": destino,
      "fechaInicio": fechaInicio,
      "fechaFin": fechaFin,
      "descripcion": descripcion,
      "lat": lat, // 🔥 CLAVE
      "lng": lng, // 🔥 CLAVE
      "fechaCreacion": Timestamp.now(),
    });

    return doc.id;
  }
}
