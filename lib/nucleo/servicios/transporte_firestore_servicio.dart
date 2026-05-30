import 'package:cloud_firestore/cloud_firestore.dart';

class TransporteFirestoreServicio {
  final _db = FirebaseFirestore.instance;

  // ===================== AUTOBÚS =====================

  Future<void> guardarDatosAutobus({
    required String origen,
    required String destino,
    required List<Map<String, dynamic>> rutas,
  }) async {
    final key = _key(origen, destino);
    await _db.collection('transporte_autobus').doc(key).set({
      'origen': origen,
      'destino': destino,
      'rutas': rutas,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>?> obtenerDatosAutobus({
    required String origen,
    required String destino,
  }) async {
    final doc =
        await _db.collection('transporte_autobus').doc(_key(origen, destino)).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    if (!_esVigente(data)) return null;

    return List<Map<String, dynamic>>.from(data['rutas']);
  }

  // ===================== AVIÓN =====================

  Future<void> guardarDatosAvion({
    required String origen,
    required String destino,
    required List<Map<String, dynamic>> rutas,
  }) async {
    final key = _key('avion_$origen', destino);
    await _db.collection('transporte_avion').doc(key).set({
      'origen': origen,
      'destino': destino,
      'rutas': rutas,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>?> obtenerDatosAvion({
    required String origen,
    required String destino,
  }) async {
    final doc = await _db
        .collection('transporte_avion')
        .doc(_key('avion_$origen', destino))
        .get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    if (!_esVigente(data)) return null;

    return List<Map<String, dynamic>>.from(data['rutas']);
  }

  // ===================== ERROR RQF79 =====================

  Future<void> registrarError({
    required String origen,
    required String destino,
    required String tipo,
  }) async {
    await _db.collection('errores_transporte').add({
      'origen': origen,
      'destino': destino,
      'tipo': tipo,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  // ===================== HELPERS =====================

  String _key(String a, String b) =>
      '${a}_$b'.toLowerCase().replaceAll(' ', '_');

  bool _esVigente(Map<String, dynamic> data) {
    final timestamp = data['actualizadoEn'] as Timestamp?;
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp.toDate()).inDays <= 30;
  }
}