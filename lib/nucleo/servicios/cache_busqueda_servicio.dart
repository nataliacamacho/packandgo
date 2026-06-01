import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CacheBusquedaServicio {
  static final _db = FirebaseFirestore.instance;

  // =========================
  //  GENERAR HASH
  // =========================
  static String generarHash(
    String? destino,
    String? tipo,
    String? estilo,
    String? precio,
  ) {
    final input = "$destino|$tipo|$estilo|$precio";
    final bytes = utf8.encode(input);
    return sha1.convert(bytes).toString();
  }

  // =========================
  //  OBTENER CACHE
  // =========================
  static Future<List<Map<String, dynamic>>?> obtenerCache(
      String hash) async {
    final doc =
        await _db.collection("cache_busquedas").doc(hash).get();

    if (doc.exists) {
      return List<Map<String, dynamic>>.from(doc.data()!["data"]);
    }

    return null;
  }

  // =========================
  //   GUARDAR CACHE
  // =========================
  static Future<void> guardarCache(
    String hash,
    List<Map<String, dynamic>> datos,
  ) async {
    await _db.collection("cache_busquedas").doc(hash).set({
      "data": datos,
      "fecha": DateTime.now(),
    });
  }
}