import 'package:flutter_dotenv/flutter_dotenv.dart';

class AnalizadorEtiquetas {
  
  // ====================================================================
  // 🔥 1. EL SALVAVIDAS: Tu función original para que Búsqueda no explote
  // ====================================================================
  static String? analizarExperiencia(String categoria, List<dynamic> tags) {
    // Retorna null para que tu búsqueda use el "General" y su propia lógica local
    return null; 
  }

  // ====================================================================
  // 🚀 2. LA FÁBRICA NUEVA: La usaremos después para limpiar el código
  // ====================================================================
  static Map<String, dynamic> enriquecerLugar(Map<String, dynamic> l) {
    final nombreCrudo = l['name'] ?? l['properties']?['name'] ?? 'Sin nombre';
    final String nombreMin = nombreCrudo.toString().toLowerCase();

    final types = l["types"] as List<dynamic>? ?? []; 
    final kinds = (l["kinds"] ?? l["properties"]?["kinds"] ?? "").toString(); 
    final datosCrudos = types.join(",") + "," + kinds.toLowerCase(); 

    String categoria = "Otro";
    if (nombreMin.contains("café") || nombreMin.contains("cafe") || nombreMin.contains("coffee") || nombreMin.contains("cafeteria")) categoria = "Cafetería";
    else if (datosCrudos.contains("restaurant") || datosCrudos.contains("food")) categoria = "Restaurante";
    else if (datosCrudos.contains("bar") || datosCrudos.contains("night_club") || datosCrudos.contains("pub")) categoria = "Bar";
    else if (datosCrudos.contains("park") || datosCrudos.contains("nature")) categoria = "Parque";
    else if (datosCrudos.contains("museum") || datosCrudos.contains("art")) categoria = "Museo";

    int priceLevel = l["price_level"] ?? -1; 
    String precioCalc = "\$\$"; 
    if (nombreMin.contains("mcdonald") || nombreMin.contains("burger") || nombreMin.contains("pizza") || nombreMin.contains("taco") || nombreMin.contains("kfc") || nombreMin.contains("vips")) precioCalc = "\$";
    else if (priceLevel <= 1 && priceLevel != -1) precioCalc = "\$";
    else if (priceLevel >= 3) precioCalc = "\$\$\$";

    String etiquetaAsignada = "General";
    if (nombreMin.contains("motel")) etiquetaAsignada = "En pareja";
    else if (types.contains("bar") || types.contains("liquor_store") || categoria == "Bar") etiquetaAsignada = "Amigos";

    String urlImagen = "";
    final photos = l["photos"] as List<dynamic>?;
    if (photos != null && photos.isNotEmpty) {
      final photoRef = photos[0]["photo_reference"].toString().trim();
      final apiKey = dotenv.env['GOOGLE_API_KEY'] ?? "AIzaSyARaWdvsXGpJZD4uMUNoeAEXDoMcl3GGuQ";
      urlImagen = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=$apiKey";
    } else if (l['imagen'] != null) {
      urlImagen = l['imagen'];
    }

    return {
      ...l,
      'name': nombreCrudo,
      'categoriaPrincipal': categoria,
      'experiencia': etiquetaAsignada,
      'precio': precioCalc,
      'imagen': urlImagen,
    };
  }
}