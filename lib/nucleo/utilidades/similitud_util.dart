import 'dart:math';

class SimilitudUtil {
  // =========================
  // 📊 COSINE SIMILARITY
  // =========================
  static double cosineSimilarity(
    Map<String, double> a,
    Map<String, double> b,
  ) {
    double dot = 0;
    double magA = 0;
    double magB = 0;

    final keys = {...a.keys, ...b.keys};

    for (var k in keys) {
      final va = a[k] ?? 0;
      final vb = b[k] ?? 0;

      dot += va * vb;
      magA += va * va;
      magB += vb * vb;
    }

    if (magA == 0 || magB == 0) return 0;

    return dot / (sqrt(magA) * sqrt(magB));
  }

  // =========================
  // 🧠 FILTRAR USUARIOS SIMILARES
  // =========================
  static List<String> usuariosSimilares({
    required Map<String, double> usuarioActual,
    required Map<String, Map<String, double>> otrosUsuarios,
    double umbral = 0.7,
  }) {
    List<String> similares = [];

    otrosUsuarios.forEach((uid, vector) {
      final sim = cosineSimilarity(usuarioActual, vector);

      if (sim >= umbral) {
        similares.add(uid);
      }
    });

    return similares;
  }
}