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
  }) async {

    final uid = _auth.currentUser!.uid;

    final doc = await _firestore.collection("viajes").add({
      "usuarioId": uid,
      "destino": destino,
      "fechaInicio": fechaInicio,
      "fechaFin": fechaFin,
      "descripcion": descripcion,
      'uid': FirebaseAuth.instance.currentUser!.uid,
      "fechaCreacion": Timestamp.now(),
    });

    return doc.id;
  }
}