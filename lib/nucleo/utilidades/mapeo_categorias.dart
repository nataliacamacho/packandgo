class MapeoCategorias {
  static String obtenerCategoriaPrincipal(dynamic categoriasApi) {
    final texto = categoriasApi.toString().toLowerCase();

    if (texto.contains("restaurant")) return "Restaurante";
    if (texto.contains("coffee")) return "Cafetería";
    if (texto.contains("bar") || texto.contains("night")) return "Bar";
    if (texto.contains("park") || texto.contains("nature")) return "Parque";
    if (texto.contains("museum")) return "Museo";
    if (texto.contains("beach")) return "Playa";
    if (texto.contains("monument")) return "Monumento";
    if (texto.contains("archaeological")) return "Zona arqueológica";
    if (texto.contains("viewpoint")) return "Mirador";
    if (texto.contains("mall") || texto.contains("shopping"))
      return "Centro comercial";
    if (texto.contains("adventure") || texto.contains("extreme"))
      return "Actividades extremas";

    return "Turístico";
  }
}