class ExperienciaUtil {
  // =========================
  // LISTA NEGRA
  // =========================
  static final List<String> blacklist = [
    "bonito",
    "agradable",
    "bueno",
    "lugar",
    "nice",
    "good",
  ];

  // =========================
  // TABLA DE PESOS
  // =========================
  static final Map<String, Map<String, Map<String, double>>> tablaPesos = {
    "restaurante": {
      "familiar": {
        "niños": 3,
        "menu": 2,
        "seguro": 2,
        "amable": 2,
      },
      "amigos": {
        "social": 3,
        "grupo": 2,
        "ambiente": 2,
      },
      "solo": {
        "tranquilo": 3,
        "relajante": 2,
        "lectura": 2,
      },
      "pareja": {
        "romantico": 4,
        "intimo": 3,
        "elegante": 2,
      }
    },

    "cafeteria": {
      "solo": {
        "lectura": 3,
        "estudio": 3,
        "tranquilo": 2,
      },
      "pareja": {
        "romantico": 3,
        "acogedor": 2,
      },
      "amigos": {
        "social": 2,
        "grupo": 2,
      }
    },

    "bar": {
      "amigos": {
        "fiesta": 4,
        "musica": 3,
        "bebidas": 3,
        "grupo": 2,
      },
      "pareja": {
        "intimo": 2,
        "romantico": 2,
      }
    },

    "parque": {
      "familiar": {
        "niños": 3,
        "juegos": 3,
        "seguro": 2,
      },
      "solo": {
        "tranquilo": 3,
        "naturaleza": 2,
      }
    },

    "centro_comercial": {
      "familiar": {
        "niños": 2,
        "compras": 2,
      },
      "amigos": {
        "grupo": 2,
        "social": 2,
      }
    }
  };

  // =========================
  // LIMPIEZA DE TEXTO
  // =========================
  static List<String> limpiarTexto(String texto) {
    return texto
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(" ")
        .where((p) => p.isNotEmpty && !blacklist.contains(p))
        .toList();
  }

  // =========================
  // ALGORITMO PRINCIPAL
  // =========================
  static List<String> calcularExperiencia(Map<String, dynamic> lugar) {
    final categoria =
        (lugar["categoriaPrincipal"] ?? "").toLowerCase();

    if (!tablaPesos.containsKey(categoria)) {
      return ["familiar"]; // fallback
    }

    final nombre = lugar["name"] ?? "";
    final direccion =
        lugar["location"]?["formatted_address"] ?? "";

    final palabras = [
      ...limpiarTexto(nombre),
      ...limpiarTexto(direccion),
    ];

    Map<String, double> puntajes = {
      "familiar": 0,
      "amigos": 0,
      "solo": 0,
      "pareja": 0,
    };

    final configCategoria = tablaPesos[categoria]!;

    for (var tipo in configCategoria.keys) {
      final palabrasCategoria = configCategoria[tipo]!;

      for (var palabra in palabras) {
        if (palabrasCategoria.containsKey(palabra)) {
          double peso = palabrasCategoria[palabra]!;

          // 🔥 NORMALIZACIÓN (si aparece en varias categorías)
          int count = 0;
          configCategoria.forEach((_, mapa) {
            if (mapa.containsKey(palabra)) count++;
          });

          if (count > 1) {
            peso = peso / count;
          }

          puntajes[tipo] = puntajes[tipo]! + peso;
        }
      }
    }

    // =========================
    // UMBRAL
    // =========================
    List<String> etiquetas = [];

    puntajes.forEach((tipo, valor) {
      if (valor >= 8) {
        etiquetas.add(tipo);
      }
    });

    // 🔥 fallback inteligente
    if (etiquetas.isEmpty) {
      if (categoria == "bar") return ["amigos"];
      if (categoria == "parque") return ["familiar"];
      if (categoria == "cafeteria") return ["solo"];
      return ["familiar"];
    }

    return etiquetas;
  }
}