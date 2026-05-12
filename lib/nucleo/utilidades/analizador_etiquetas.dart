// lib/nucleo/utilidades/analizador_etiquetas.dart

class AnalizadorEtiquetas {
  // El umbral que definieron en el documento
  static const double UMBRAL_MINIMO = 8.0;

  // Tu lista de palabras ignoradas para evitar falsos positivos
  static const List<String> _listaNegra = [
    'bonito', 'agradable', 'bueno', 'lindo', 'bien', 'mal', 'feo'
  ];

  // El diccionario exacto de palabras y pesos según el documento
  // Estructura: Categoria -> Etiqueta Experiencia -> Palabra -> Peso
  static const Map<String, Map<String, Map<String, double>>> _diccionarioPesos = {
    "restaurante": {
      "Familiar": {
        "niños": 5.0, "comida": 2.0, "menú infantil": 5.0, 
        "divertido": 3.0, "seguro": 4.0, "amable": 2.0
      },
      "Amigos": {
        "comida": 2.0, "bebidas": 4.0, "social": 5.0, 
        "animado": 4.0, "grupo": 5.0, "ambiente": 3.0
      },
      "Solo": {
        "tranquilo": 4.0, "personal": 3.0, "lectura": 5.0, 
        "relajante": 4.0, "atento": 2.0
      },
      "En pareja": {
        "romántico": 5.0, "íntimo": 5.0, "cena": 3.0, 
        "elegante": 4.0, "acogedor": 3.0, "especial": 4.0
      }
    },
    "parque": {
      "Familiar": {
        "niños": 5.0, "picnic": 4.0, "juegos": 5.0, 
        "seguro": 4.0, "paseo": 3.0, "educativo": 3.0, "verde": 2.0
      },
      "Amigos": {
        "grupo": 5.0, "diversión": 3.0, "paseo": 2.0, 
        "animado": 4.0, "deporte": 5.0
      },
      "Solo": {
        "tranquilo": 4.0, "relajante": 4.0, "naturaleza": 3.0, 
        "paseo": 2.0, "lectura": 5.0
      },
      "En pareja": {
        "romántico": 5.0, "tranquilo": 4.0, "paseo": 2.0, 
        "vista": 4.0, "especial": 4.0
      }
    },
    // Nota: Aquí se agregarían las demás de tus 11 categorías siguiendo el mismo patrón
  };

  /// Analiza una lista de reseñas de un lugar y devuelve la mejor etiqueta de experiencia.
  /// Si ninguna supera los 8 puntos, devuelve null (se queda la de por defecto).
  static String? analizarExperiencia(String categoriaLugar, List<String> resenas) {
    String categoria = categoriaLugar.toLowerCase();
    
    // Si no tenemos diccionario para esta categoría, salimos
    if (!_diccionarioPesos.containsKey(categoria)) return null;

    Map<String, double> puntajesTotales = {
      "Familiar": 0.0,
      "Amigos": 0.0,
      "Solo": 0.0,
      "En pareja": 0.0
    };

    // 1. Limpiar y juntar todas las reseñas en un solo texto gigante
    String textoCompleto = resenas.join(" ").toLowerCase();

    // 2. Filtrar lista negra (reemplazar esas palabras por vacío)
    for (String palabraProhibida in _listaNegra) {
      textoCompleto = textoCompleto.replaceAll(palabraProhibida, "");
    }

    // 3. Analizar palabra por palabra contra el diccionario
    Map<String, Map<String, double>> diccionarioCategoria = _diccionarioPesos[categoria]!;

    diccionarioCategoria.forEach((experiencia, palabrasClave) {
      double puntajeEtiqueta = 0.0;

      palabrasClave.forEach((palabra, peso) {
        // Contar cuántas veces aparece la palabra clave en el texto
        int ocurrencias = palabra.allMatches(textoCompleto).length;
        
        if (ocurrencias > 0) {
          // Lógica de Peso Normalizado (penalización)
          double pesoNormalizado = _calcularPesoNormalizado(categoria, palabra, peso);
          
          // PuntajeEtiqueta = Sumatoria de (peso * veces que apareció)
          puntajeEtiqueta += (pesoNormalizado * ocurrencias);
        }
      });

      puntajesTotales[experiencia] = puntajeEtiqueta;
    });

    // 4. Buscar la experiencia ganadora que supere el umbral
    String experienciaGanadora = "";
    double puntajeMaximo = 0.0;

    puntajesTotales.forEach((experiencia, puntaje) {
      if (puntaje > puntajeMaximo && puntaje >= UMBRAL_MINIMO) {
        puntajeMaximo = puntaje;
        experienciaGanadora = experiencia;
      }
    });

    return experienciaGanadora.isNotEmpty ? experienciaGanadora : _obtenerEtiquetaPorDefecto(categoria);
  }

  /// Calcula el peso normalizado: peso / numero de categorías donde aparece
  static double _calcularPesoNormalizado(String categoria, String palabra, double pesoOriginal) {
    int nCategoriasAparece = 0;
    
    _diccionarioPesos[categoria]!.forEach((exp, palabras) {
      if (palabras.containsKey(palabra)) {
        nCategoriasAparece++;
      }
    });

    // Fórmula: pesoNormalizado = pesopalabra / ncategorias
    return nCategoriasAparece > 0 ? (pesoOriginal / nCategoriasAparece) : pesoOriginal;
  }

  static String _obtenerEtiquetaPorDefecto(String categoria) {
    switch (categoria.toLowerCase()) {
      case "restaurante": return "Familiar"; 
      case "parque": return "Familiar";
      case "museo": return "Familiar";
      case "playa": return "Familiar";
      case "zona arqueológica": return "Familiar";
      case "centro comercial": return "Familiar";
      case "mirador": return "En pareja";
      case "cafetería": return "Amigos";
      case "bar": return "Amigos";
      case "actividades extremas": return "Amigos";
      case "monumento": return "Solo";
      default: return "General";
    }
  }
}