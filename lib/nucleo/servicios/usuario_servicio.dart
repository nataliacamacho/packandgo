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

  // =========================
  // ACTUALIZAR PERFIL
  // =========================
  Future<void> actualizarUsuario({
    String? nombreUsuario,
    String? nuevaPassword,
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

  // =========================================================
  // 🧠 NUEVO: CREAR USUARIO EN FIRESTORE (OBLIGATORIO)
  // =========================================================
  Future<void> crearUsuarioSiNoExiste({
    required String uid,
    required String correo,
    required String nombreUsuario,
  }) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();

    if (doc.exists) return;

    await _firestore.collection('usuarios').doc(uid).set({
      'correo': correo,
      'nombreUsuario': nombreUsuario,
      'fechaRegistro': DateTime.now().toIso8601String(),
      'historialEtiquetas': {},
      'destinosBuscados': [],
      'favoritos': [],
    });
  }

  // =========================================================
  // 🧠 NUEVO: INCREMENTAR ETIQUETAS (RECOMENDACIÓN)
  // =========================================================
  Future<void> incrementarEtiqueta({required String etiqueta}) async {
    final uid = obtenerUidActual();

    if (uid == null) {
      throw Exception("No hay usuario autenticado");
    }

    await _firestore.collection('usuarios').doc(uid).set({
      'historialEtiquetas': {etiqueta: FieldValue.increment(1)},
    }, SetOptions(merge: true));
  }

  // =========================================================
  // 🧠 NUEVO: GUARDAR DESTINO BUSCADO
  // =========================================================
  Future<void> guardarDestinoBuscado(String destino) async {
    final uid = obtenerUidActual();

    if (uid == null) {
      throw Exception("No hay usuario autenticado");
    }

    await _firestore.collection('usuarios').doc(uid).update({
      'destinosBuscados': FieldValue.arrayUnion([destino]),
    });
  }

  // =========================================================
  // 🧠 NUEVO: GUARDAR FAVORITO
  // =========================================================
  Future<void> guardarFavorito(String idLugar) async {
    final uid = obtenerUidActual();

    if (uid == null) {
      throw Exception("No hay usuario autenticado");
    }

    await _firestore.collection('usuarios').doc(uid).update({
      'favoritos': FieldValue.arrayUnion([idLugar]),
    });
  }

  // =========================================================
  // 🧠 NUEVO: OBTENER PERFIL PARA RECOMENDACIÓN
  // =========================================================
  Future<Map<String, int>> obtenerPerfil() async {
    final uid = obtenerUidActual();

    if (uid == null) return {};

    final doc = await _firestore.collection('usuarios').doc(uid).get();

    final data = doc.data();
    if (data == null) return {};

    final Map<String, dynamic> historial = Map<String, dynamic>.from(
      data['historialEtiquetas'] ?? {},
    );

    return historial.map((key, value) => MapEntry(key, value as int));
  }
}
