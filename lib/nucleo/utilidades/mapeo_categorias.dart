class MapeoCategorias {
  static String obtenerCategoriaPrincipal(dynamic input) {
    if (input == null) return "otro";

    final texto = input.toString().toLowerCase();

    // 🏖️ PRIORIDAD ALTA
    if (texto.contains("beach")) return "playa";

    // 🍽️
    if (texto.contains("restaurant")) return "restaurante";
    if (texto.contains("cafe")) return "cafeteria";
    if (texto.contains("bar")) return "bar";

    // 🌿
    if (texto.contains("park")) return "parque";
    if (texto.contains("nature")) return "naturaleza";

    // 🏛️
    if (texto.contains("museum")) return "museo";
    if (texto.contains("historic")) return "monumento";
    if (texto.contains("archaeological")) return "zona_arqueologica";

    // 🛍️
    if (texto.contains("shopping")) return "centro_comercial";

    // 📍
    if (texto.contains("view_point")) return "mirador";

    return "otro";
  }
}