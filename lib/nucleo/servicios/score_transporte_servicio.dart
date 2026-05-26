import 'dart:math';

class ScoreTransporteServicio {
  double calcularScore({
    required double tiempo,
    required double costo,
    required double distancia,
    double pesoTiempo = 0.5,
    double pesoCosto = 0.3,
    double pesoDistancia = 0.2,
  }) {
    // normalización simple para evitar números gigantes
    final t = tiempo / 1000;
    final c = costo / 10000;
    final d = distancia / 5000;

    return (t * pesoTiempo) + (c * pesoCosto) + (d * pesoDistancia);
  }

  String mejorOpcion(Map<String, double> scores) {
    String mejor = scores.keys.first;
    double menor = scores[mejor]!;

    scores.forEach((key, value) {
      if (value < menor) {
        menor = value;
        mejor = key;
      }
    });

    return mejor;
  }
}