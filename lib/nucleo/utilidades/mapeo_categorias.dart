class MapeoCategorias {
  static String obtenerCategoriaPrincipal(dynamic input) {
    if (input == null) return "otro";

    final texto = input.toString().toLowerCase();

    // 🍽️ COMIDA
    if (texto.contains("restaurant") ||
        texto.contains("foods") ||
        texto.contains("food")) {
      return "restaurante";
    }

    if (texto.contains("cafe") ||
        texto.contains("coffee") ||
        texto.contains("bakery") ||
        texto.contains("espresso") ||
        texto.contains("tea_house") ||
        texto.contains("coffee_shop")) {
      return "cafeteria";
    }

    if (texto.contains("bar") ||
        texto.contains("pub") ||
        texto.contains("nightclub")) {
      return "bar";
    }

    // 🌿 NATURALEZA
    if (texto.contains("park") || texto.contains("natural")) {
      return "parque";
    }

    if (texto.contains("beach") ||
        texto.contains("coast") ||
        texto.contains("sea") ||
        texto.contains("water") ||
        texto.contains("natural_feature")) {
      return "playa";
    }

    // 🏛️ CULTURA
    if (texto.contains("museum") || texto.contains("museums")) {
      return "museo";
    }

    if (texto.contains("historic") || texto.contains("monument")) {
      return "monumento";
    }

    if (texto.contains("archaeology")) {
      return "zona_arqueologica";
    }

    // 🛍️
    if (texto.contains("shop") || texto.contains("shopping")) {
      return "centro_comercial";
    }

    // 📍
    if (texto.contains("view")) {
      return "mirador";
    }

    // ⚡
    if (texto.contains("sport")) {
      return "actividades_extremas";
    }

    return "otro";
  }
}
