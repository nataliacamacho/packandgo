import 'package:cloud_firestore/cloud_firestore.dart';

class ResenaServicio {
  // Palabras clave requeridas para asegurar que el comentario aporta valor
  static const List<String> palabrasClave = [
    'servicio', 'precio', 'lugar', 'comida', 'experiencia', 
    'atención', 'limpieza', 'ambiente', 'recomendable'
  ];

  // Retorna un String con el error, o 'null' si la reseña es perfecta
  static Future<String?> validarTextoResena(String texto) async {
    String textoLimpio = texto.trim().toLowerCase();
    
    // 1. Regla de Longitud (Mínimo 5 palabras)
    // Usamos una expresión regular para separar por espacios y contar
    List<String> palabras = textoLimpio.split(RegExp(r'\s+'));
    if (textoLimpio.isEmpty || palabras.length < 5) {
      return "Tu reseña parece ser poco informativa. Por favor, escribe al menos 5 palabras.";
    }

    // 2. Regla de Contenido (Debe incluir al menos un tema relevante)
    bool tienePalabraClave = palabrasClave.any((clave) => textoLimpio.contains(clave));
    if (!tienePalabraClave) {
      return "Tu reseña parece ser poco informativa. Intenta mencionar algo sobre el servicio, precio o tu experiencia.";
    }

    // 3. Regla de Lenguaje (Consulta de la Lista Negra en Firebase)
    try {
      // Lee el documento de configuración general de la app
      DocumentSnapshot config = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('filtros_comunidad')
          .get();

      if (config.exists && config.data() != null) {
        List<dynamic> listaNegra = config.get('palabras_prohibidas') ?? [];
        
        for (String palabraProhibida in listaNegra) {
          if (textoLimpio.contains(palabraProhibida.toLowerCase())) {
            return "Tu reseña contiene lenguaje que no cumple con nuestras normas de respeto.";
          }
        }
      }
    } catch (e) {
      print("⚠️ Advertencia: No se pudo verificar la lista negra en la nube: $e");
    }

    // ¡Pasó todos los filtros!
    return null; 
  }
}