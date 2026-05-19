class NormalizadorLugares {
  // =========================
  // 🎯 CATEGORÍA PRINCIPAL
  // =========================
  static String obtenerCategoria(Map<String, dynamic>? lugar) {
    if (lugar == null) return 'Atracción turística';

    final google = _categoriaGoogle(lugar);
    if (google != null) return google;

    final otm = _categoriaOpenTripMap(lugar);
    if (otm != null) return otm;

    final fsq = _categoriaFoursquare(lugar);
    if (fsq != null) return fsq;

    return 'Atracción turística';
  }

  // =========================
  // 🟢 GOOGLE PLACES
  // =========================
  static String? _categoriaGoogle(Map<String, dynamic> lugar) {
    if (lugar['types'] == null || lugar['types'] is! List) return null;

    final tipos = List<String>.from(
      lugar['types'].map((e) => e.toString().toLowerCase()),
    );

    // 🔥 PRIORIDAD (orden IMPORTANTE)
    if (_match(tipos, ['restaurant', 'food'])) return 'Restaurante';
    if (_match(tipos, ['cafe'])) return 'Cafetería';
    if (_match(tipos, ['bar', 'night_club'])) return 'Bar';
    if (_match(tipos, ['park'])) return 'Parque';
    if (_match(tipos, ['museum'])) return 'Museo';
    if (_match(tipos, ['beach'])) return 'Playa';
    if (_match(tipos, ['shopping_mall', 'store'])) return 'Centro comercial';
    if (_match(tipos, ['amusement_park'])) return 'Actividades extremas';
    if (_match(tipos, ['tourist_attraction'])) return 'Monumento';

    return null;
  }

  // =========================
  // 🟡 OPENTRIPMAP
  // =========================
  static String? _categoriaOpenTripMap(Map<String, dynamic> lugar) {
    if (lugar['kinds'] == null) return null;

    final kinds = lugar['kinds'].toString().toLowerCase();

    if (kinds.contains('restaurants')) return 'Restaurante';
    if (kinds.contains('cafes')) return 'Cafetería';
    if (kinds.contains('bars')) return 'Bar';
    if (kinds.contains('parks')) return 'Parque';
    if (kinds.contains('museums')) return 'Museo';
    if (kinds.contains('beaches')) return 'Playa';
    if (kinds.contains('historic')) return 'Monumento';
    if (kinds.contains('archaeological')) return 'Zona arqueológica';
    if (kinds.contains('view_points')) return 'Mirador';
    if (kinds.contains('shopping')) return 'Centro comercial';
    if (kinds.contains('amusements')) return 'Actividades extremas';

    return null;
  }

  // =========================
  // 🔵 FOURSQUARE (fallback)
  // =========================
  static String? _categoriaFoursquare(Map<String, dynamic> lugar) {
    if (lugar['categories'] == null ||
        lugar['categories'] is! List ||
        lugar['categories'].isEmpty) {
      return null;
    }

    return lugar['categories'][0]['name'];
  }

  // =========================
  // 🔍 MATCH FLEXIBLE
  // =========================
  static bool _match(List<String> tipos, List<String> claves) {
    return tipos.any(
      (t) => claves.any((clave) => t.contains(clave)),
    );
  }

  // =========================
  // 🌍 NOMBRE LIMPIO (IDIOMA)
  // =========================
  static String obtenerNombre(Map<String, dynamic>? lugar) {
    if (lugar == null) return 'Lugar desconocido';

    String nombre = lugar['name'] ?? 'Lugar desconocido';

    // 🔥 limpieza básica
    nombre = nombre.replaceAll(RegExp(r'\(.*?\)'), '');

    return nombre.trim();
  }

  // =========================
  // 📍 DIRECCIÓN LIMPIA
  // =========================
  static String obtenerDireccion(Map<String, dynamic>? lugar) {
    if (lugar == null) return 'Ubicación desconocida';

    return lugar['formatted_address'] ??
        lugar['location']?['formatted_address'] ??
        lugar['vicinity'] ??
        'Ubicación desconocida';
  }
}