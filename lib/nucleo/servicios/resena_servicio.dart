import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResenaServicio {
  static Future<void> guardarResena({
    required String idLugar,
    required String nombreLugar,
    required String texto,
    required int estrellas,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('resenas').add({
      "id_usuario": uid,
      "id_lugar": idLugar,
      "nombre_lugar": nombreLugar,
      "fecha": FieldValue.serverTimestamp(),

      "estrellas": estrellas,
      "texto": texto,

      "likes": 0,
      "me_encanta": 0,
      "usuarios_like": [],
      "usuarios_love": [],
      "ranking": estrellas * 10,

      "es_favorita": false,
    });
  }

  static const List<String> palabrasClave = [
    'gusta',
    'encanta',
    'caro',
    'barato',
    'lleno',
    'servicio',
    'precio',
    'lugar',
    'comida',
    'experiencia',
    'atencion',
    'limpieza',
    'ambiente',
    'recomendable',
  ];

  static String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[^\w\s]'), '');
  }

  static Future<void> eliminarResena(String id) async {
    await FirebaseFirestore.instance.collection('resenas').doc(id).delete();
  }

  static Future<void> editarResena({
    required String id,
    required String texto,
    required int estrellas,
  }) async {
    await FirebaseFirestore.instance.collection('resenas').doc(id).update({
      'texto': texto,
      'estrellas': estrellas,
    });
  }

  static Future<String?> validarTextoResena(String texto) async {
    final limpio = _normalizar(texto.trim());

    final palabras = limpio.split(RegExp(r'\s+'));

    if (limpio.isEmpty || palabras.length < 5) {
      return "Escribe al menos 5 palabras para una reseña útil.";
    }

    final tieneClave = palabras.any((p) => palabrasClave.contains(p));

    if (!tieneClave) {
      return "Incluye detalles como servicio, precio o experiencia.";
    }

    try {
      final config = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('filtros_comunidad')
          .get();

      if (config.exists && config.data() != null) {
        final listaNegra = List<String>.from(
          config.get('palabras_prohibidas') ?? [],
        );

        for (String prohibida in listaNegra) {
          final palabra = _normalizar(prohibida);

          if (palabras.contains(palabra)) {
            return "Evita lenguaje ofensivo en tu reseña.";
          }
        }
      }
    } catch (e) {
      print("⚠️ Error leyendo filtros: $e");
    }

    return null;
  }
}
