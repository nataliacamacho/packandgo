import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto/modelos/maleta.dart';

class MaletaFirebaseServicio {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  // 🔹 STREAM
  Stream<List<ItemMaleta>> obtenerMaleta(String idViaje) {
    return _db
        .collection("usuarios")
        .doc(uid)
        .collection("viajes")
        .doc(idViaje)
        .collection("maleta")
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ItemMaleta.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 🔹 GUARDAR LISTA
  Future<void> guardarMaleta(
      String idViaje, List<ItemMaleta> lista) async {

    final ref = _db
        .collection("usuarios")
        .doc(uid)
        .collection("viajes")
        .doc(idViaje)
        .collection("maleta");

    final batch = _db.batch();

    for (var item in lista) {
      final doc = ref.doc();
      batch.set(doc, item.toMap());
    }

    await batch.commit();
  }

  // 🔹 AGREGAR
  Future<void> agregarItem(String idViaje, ItemMaleta item) async {
    final ref = _db
        .collection("usuarios")
        .doc(uid)
        .collection("viajes")
        .doc(idViaje)
        .collection("maleta");

    await ref.add(item.toMap());
  }

  // 🔹 CHECK
  Future<void> actualizarEstado(
      String idViaje, String idItem, bool estado) async {

    final ref = _db
        .collection("usuarios")
        .doc(uid)
        .collection("viajes")
        .doc(idViaje)
        .collection("maleta")
        .doc(idItem);

    await ref.update({"completado": estado});
  }

  // 🔹 ELIMINAR
  Future<void> eliminarItem(String idViaje, String idItem) async {
    final ref = _db
        .collection("usuarios")
        .doc(uid)
        .collection("viajes")
        .doc(idViaje)
        .collection("maleta")
        .doc(idItem);

    await ref.delete();
  }
}