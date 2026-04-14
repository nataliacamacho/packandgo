import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/autobus/modelo_ruta_autobus.dart';

class ServicioAutobus {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==============================
  // 🔧 NORMALIZACIÓN
  // ==============================
  String normalizarTexto(String texto) {
    return texto
        .toLowerCase()
        .trim()
        .replaceAll("á", "a")
        .replaceAll("é", "e")
        .replaceAll("í", "i")
        .replaceAll("ó", "o")
        .replaceAll("ú", "u")
        .replaceAll("ñ", "n")
        .replaceAll(" ", "_");
  }

  // ==============================
  // 🔎 BÚSQUEDA EXACTA (ORIGEN → DESTINO)
  // ==============================
  Future<List<RutaAutobus>> obtenerRutaExacta({
    required String origen,
    required String destino,
  }) async {
    final origenKey = normalizarTexto(origen);
    final destinoKey = normalizarTexto(destino);

    final snapshot = await _db
        .collection("transportes_autobus")
        .where("origen_key", isEqualTo: origenKey)
        .where("destino_key", isEqualTo: destinoKey)
        .get();

    return snapshot.docs
        .map((doc) => RutaAutobus.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==============================
  // 🔄 FALLBACK INTELIGENTE
  // ==============================
  Future<List<RutaAutobus>> obtenerFallback({
    required String origen,
    required String destino,
  }) async {
    final origenKey = normalizarTexto(origen);
    final destinoKey = normalizarTexto(destino);

    // 🔥 primero intenta por destino + origen parcial
    final snapshot = await _db
        .collection("transportes_autobus")
        .where("origen_key", isEqualTo: origenKey)
        .where("destino_key", isEqualTo: destinoKey)
        .get();

    final rutas = snapshot.docs
        .map((doc) => RutaAutobus.fromMap(doc.data(), doc.id))
        .toList();

    // 🔥 filtrado extra en memoria (más flexible)
    return rutas.where((ruta) {
      final o = normalizarTexto(ruta.origen);
      final d = normalizarTexto(ruta.destino);

      return o.contains(origenKey) || d.contains(destinoKey);
    }).toList();
  }

  // ==============================
  // 🔎 FILTRO INTELIGENTE LOCAL
  // ==============================
  List<RutaAutobus> filtrar(List<RutaAutobus> rutas, String query) {
    final q = normalizarTexto(query);

    return rutas.where((ruta) {
      final o = normalizarTexto(ruta.origen);
      final d = normalizarTexto(ruta.destino);

      return o.contains(q) || d.contains(q);
    }).toList();
  }

  // ==============================
  // 🧠 MATCH FLEXIBLE
  // ==============================
  bool coincideRuta(String texto, String query) {
    final t = normalizarTexto(texto);
    final q = normalizarTexto(query);

    return t.contains(q) || q.contains(t);
  }
}
