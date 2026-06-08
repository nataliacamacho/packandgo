import 'dart:math';

class RecomendacionesServicio {
  // =========================
  //  DISTANCIA EUCLIDIANA
  // =========================
  static double distancia(Map a, Map b) {
    double sum = 0;

    for (var key in a.keys) {
      sum += pow((a[key] ?? 0) - (b[key] ?? 0), 2);
    }

    return sqrt(sum);
  }

  // =========================
  //  KNN SIMPLE
  // =========================
  static List<Map<String, dynamic>> knn({
    required Map<String, double> usuarioActual,
    required List<Map<String, dynamic>> candidatos,
    int k = 5,
  }) {
    List<Map<String, dynamic>> resultados = [];

    for (var lugar in candidatos) {
      double score = 0;

      // similitud básica por etiquetas
      Map<String, double> vectorLugar =
          Map<String, double>.from(lugar["vector"] ?? {});

      vectorLugar.forEach((key, value) {
        score += (usuarioActual[key] ?? 0) * value;
      });

      resultados.add({
        ...lugar,
        "score": score,
      });
    }

    resultados.sort(
      (a, b) => (b["score"] as double).compareTo(a["score"] as double),
    );

    return resultados.take(k).toList();
  }
}