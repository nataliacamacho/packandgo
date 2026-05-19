class AnalizadorExperiencias {

  static const Map<String, Map<String, List<String>>> reglas = {

    "restaurante": {
      "Familiar": [
        "niños",
        "menú infantil",
        "seguro",
        "familia"
      ],

      "Amigos": [
        "grupo",
        "social",
        "bebidas",
        "animado"
      ],

      "Solo": [
        "tranquilo",
        "lectura",
        "relajante"
      ],

      "En pareja": [
        "romántico",
        "íntimo",
        "elegante",
        "especial"
      ],
    },

    "playa": {
      "Familiar": [
        "niños",
        "seguro",
        "arena"
      ],

      "Amigos": [
        "aventura",
        "deportes",
        "grupo"
      ],

      "Solo": [
        "relajante",
        "tranquilo",
        "paisaje"
      ],

      "En pareja": [
        "romántico",
        "vista",
        "íntimo"
      ],
    },

  };

  // -------------------------------------------------------------------------
  // DETECTAR EXPERIENCIAS
  // -------------------------------------------------------------------------
  static List<String> detectarExperiencias({
    required String categoria,
    required String texto,
  }) {

    final experiencias = <String>[];

    final reglasCategoria = reglas[categoria];

    if (reglasCategoria == null) {
      return ["General"];
    }

    final textoMin = texto.toLowerCase();

    reglasCategoria.forEach((experiencia, palabras) {

      int coincidencias = 0;

      for (final palabra in palabras) {

        if (textoMin.contains(palabra)) {
          coincidencias++;
        }
      }

      // 🔥 mínimo 1 coincidencia
      if (coincidencias >= 1) {
        experiencias.add(experiencia);
      }
    });

    if (experiencias.isEmpty) {
      experiencias.add("General");
    }

    return experiencias;
  }
}