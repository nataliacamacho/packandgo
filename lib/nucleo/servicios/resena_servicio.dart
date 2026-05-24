import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResenaServicio {
  static Future<void> guardarResena({
    required String idLugar,
    required String nombreLugar,
    required String texto,
    required int estrellas,
    String? fotoUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('resenas').add({
      "id_usuario": uid,
      "id_lugar": idLugar,
      "nombre_lugar": nombreLugar,
      "fecha": FieldValue.serverTimestamp(),

      "estrellas": estrellas,
      "texto": texto,
      "foto": fotoUrl,

      "likes": 0,
      "me_encanta": 0,
      "usuarios_like": [],
      "usuarios_love": [],
      "ranking": estrellas * 10,

      "es_favorita": false,
    });
  }

  static Future<void> reaccionarResena({
    required String idResena,
    required String tipo,
    required String autorId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 🚫 No reaccionarte a ti mismo
    if (uid == autorId) {
      throw "No puedes reaccionar a tu propia reseña";
    }

    final ref = FirebaseFirestore.instance.collection('resenas').doc(idResena);

    final doc = await ref.get();

    if (!doc.exists) return;

    final data = doc.data()!;

    final usuariosLike = List<String>.from(data['usuarios_like'] ?? []);
    final usuariosLove = List<String>.from(data['usuarios_love'] ?? []);

    // 🚫 Ya reaccionó antes
    if (usuariosLike.contains(uid) || usuariosLove.contains(uid)) {
      throw Exception("Ya reaccionaste a esta reseña");
    }

    if (tipo == 'like') {
      await ref.update({
        'likes': FieldValue.increment(1),
        'usuarios_like': FieldValue.arrayUnion([uid]),
      });
    }

    if (tipo == 'love') {
      await ref.update({
        'me_encanta': FieldValue.increment(1),
        'usuarios_love': FieldValue.arrayUnion([uid]),
      });
    }

    // 🔥 recalcular ranking
    final nuevoDoc = await ref.get();
    final nuevaData = nuevoDoc.data()!;

    final estrellas = nuevaData['estrellas'] ?? 0;
    final likes = nuevaData['likes'] ?? 0;
    final love = nuevaData['me_encanta'] ?? 0;

    final ranking = (estrellas * 10) + likes + (love * 2);

    await ref.update({'ranking': ranking});
  }

  static int calcularRanking({
    required int estrellas,
    required int likes,
    required int meEncanta,
  }) {
    return (estrellas * 10) + likes + (meEncanta * 2);
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
    if (estrellas < 1 || estrellas > 5) {
      throw Exception("Las estrellas deben ser entre 1 y 5");
    }

    await FirebaseFirestore.instance.collection('resenas').doc(id).update({
      'texto': texto.trim(),

      'estrellas': estrellas,

      'ranking': estrellas * 10,

      'fechaEdicion': FieldValue.serverTimestamp(),
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

  static Future<void> toggleFavorita({required String idResena}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('resenas_favoritas')
        .doc(idResena);

    final existe = await ref.get();

    // 🔥 SI YA EXISTE -> ELIMINAR FAVORITO
    if (existe.exists) {
      await ref.delete();
    }
    // 🔥 SI NO EXISTE -> GUARDAR FAVORITO
    else {
      await ref.set({'id_resena': idResena, 'fecha_guardado': Timestamp.now()});
    }
  }

  static Stream<bool> esFavorita(String idResena) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Stream.value(false);
    }

    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('resenas_favoritas')
        .doc(idResena)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
