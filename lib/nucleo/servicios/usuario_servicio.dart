import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsuarioServicio {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? obtenerUidActual() {
    return _auth.currentUser?.uid;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> obtenerDatosUsuario() async {
    final uid = obtenerUidActual();

    if (uid == null) {
      throw Exception("No hay usuario autenticado");
    }

    return await _firestore.collection('usuarios').doc(uid).get();
  }

  Future<void> actualizarUsuario({
    String? nombreUsuario,
    String? nuevaPassword,
    String? correo,
  }) async {

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("No hay usuario autenticado");
    }

    if (nombreUsuario != null && nombreUsuario.isNotEmpty) {
      await user.updateDisplayName(nombreUsuario);

      await _firestore.collection('usuarios').doc(user.uid).update({
        'nombreUsuario': nombreUsuario,
      });
    }

    if (nuevaPassword != null && nuevaPassword.isNotEmpty) {
      await user.updatePassword(nuevaPassword);
    }
  }
}