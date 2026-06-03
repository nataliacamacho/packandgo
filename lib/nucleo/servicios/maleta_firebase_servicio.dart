import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto/modelos/item_maleta.dart';

class MaletaFirebaseServicio {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _maletaRef(String idViaje) {
    return _db.collection('viajes').doc(idViaje).collection('maleta');
  }

  Stream<List<ItemMaleta>> obtenerMaleta(String idViaje) {
    return _maletaRef(idViaje)
        .orderBy('categoria')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ItemMaleta.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> guardarMaleta(String idViaje, List<ItemMaleta> lista) async {
    final batch = _db.batch();

    for (final item in lista) {
      final id = '${item.destino}_${item.nombre}'.toLowerCase().replaceAll(
        ' ',
        '_',
      );

      final doc = _maletaRef(idViaje).doc(id);

      batch.set(doc, item.toMap());
    }

    await batch.commit();
  }

  Future<void> agregarItem(String idViaje, ItemMaleta item) async {
    final id = '${item.destino}_${item.nombre}'.toLowerCase().replaceAll(
      ' ',
      '_',
    );

    await _maletaRef(idViaje).doc(id).set(item.toMap());
  }

  Future<void> actualizarEstado(
    String idViaje,
    String idItem,
    bool estado,
  ) async {
    await _maletaRef(idViaje).doc(idItem).update({'completado': estado});
  }

  Future<void> eliminarItem(String idViaje, String idItem) async {
    await _maletaRef(idViaje).doc(idItem).delete();
  }

  Future<void> eliminarMaleta(String idViaje) async {
    final docs = await _maletaRef(idViaje).get();

    final batch = _db.batch();

    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> registrarHabitoMaleta({required ItemMaleta item}) async {
    if (!item.esPersonalizado) return;

    final ref = _db
        .collection('usuarios')
        .doc(uid)
        .collection('historial_maleta')
        .doc(item.nombre.toLowerCase());

    final doc = await ref.get();

    if (doc.exists) {
      await ref.update({
        'veces_usado': FieldValue.increment(1),
        'ultima_fecha': Timestamp.now(),
      });
    }
    else {
      await ref.set({
        'nombre': item.nombre,
        'categoria': item.categoria,
        'veces_usado': 1,
        'ultima_fecha': Timestamp.now(),
      });
    }
  }
}
