class MapeoCategorias {
  static String obtenerCategoriaPrincipal(dynamic categoriasApi) {
    final texto = categoriasApi.toString().toLowerCase();
    if (categoriasApi == null) return "General";

    String textoCategorias = categoriasApi.toString().toLowerCase();
    if (textoCategorias.contains("food") || textoCategorias.contains("restaurant") || textoCategorias.contains("fast_food")) {
      return "Restaurante"; 
    }
    if (textoCategorias.contains("beach") || textoCategorias.contains("natural")) {
      return "Playa";
    }
    if (textoCategorias.contains("cafe") || textoCategorias.contains("coffee")) {
      return "Cafetería"; 
    }
    if (textoCategorias.contains("museum") || textoCategorias.contains("cultural")) {
      return "Museo";
    }
    if (textoCategorias.contains("religion") || textoCategorias.contains("church") || textoCategorias.contains("temple")) {
      return "Monumento"; // O Iglesia, si la tienes en tus 11 categorías
    }
    if (textoCategorias.contains("architecture") || textoCategorias.contains("historic")) {
      return "Zona arqueológica";
    }
    if (textoCategorias.contains("amusement") || textoCategorias.contains("park") || textoCategorias.contains("leisure")) {
      return "Parque";
    }


    // 🍽️ COMIDA
    if (texto.contains("restaurant") ||
        texto.contains("foods") ||
        texto.contains("food")) {
      return "restaurante";
    }

    if (texto.contains("cafe")) {
      return "cafeteria";
    }

    if (texto.contains("bar") ||
        texto.contains("pub") ||
        texto.contains("nightclub")) {
      return "bar";
    }

    // 🌿 NATURALEZA
    if (texto.contains("park") ||
        texto.contains("natural")) {
      return "parque";
    }

    if (texto.contains("beach")) {
      return "playa";
    }

    // 🏛️ CULTURA
    if (texto.contains("museum") ||
        texto.contains("museums")) {
      return "museo";
    }

    if (texto.contains("historic") ||
        texto.contains("monument")) {
      return "monumento";
    }

    if (texto.contains("archaeology")) {
      return "zona_arqueologica";
    }

    // 🛍️
    if (texto.contains("shop") ||
        texto.contains("shopping")) {
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