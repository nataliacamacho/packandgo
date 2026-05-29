import 'dart:convert';
import 'dart:math'; // 🧠 SOLUCIÓN ERROR 2: Ya reconoce min() y pow()
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de datos estructurado para la transferencia de información de las APIs
class Lugar {
  final String id;
  final String nombre;
  final String tipo; 
  final String precio; 
  final double rating; 
  final int numResenas; 
  final double latitud;
  final double longitud;
  final List<String> resenasTexto;
  final String fotoUrl;
  final String direccion;
  final String horario;

  Lugar({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.precio,
    required this.rating,
    required this.numResenas,
    required this.latitud,
    required this.longitud,
    required this.resenasTexto,
    required this.fotoUrl,
    required this.direccion,
    required this.horario,
  });
}

class FiltrosEtiquetasServicio {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lista negra de palabras ambiguas para el procesamiento NLP
  final Set<String> listaNegraNLP = {'bonito', 'agradable', 'bueno', 'lugar', 'excelente', 'bien'};

  // Matriz base de correspondencia inicial de pesos por palabra clave
  final Map<String, Map<String, Map<String, double>>> matrizPesosNLP = {
    'restaurante': {
      'Familiar': {'niños': 5, 'comida': 2, 'menú infantil': 5, 'divertido': 3, 'seguro': 4, 'amable': 3},
      'Amigos': {'comida': 2, 'bebidas': 4, 'social': 4, 'animado': 3, 'grupo': 5, 'ambiente': 3},
      'Solo': {'tranquilo': 4, 'personal': 5, 'lectura': 4, 'relajante': 4, 'atento': 2},
      'en pareja': {'romántico': 5, 'íntimo': 5, 'cena': 3, 'elegante': 4, 'acogedor': 4, 'especial': 3},
    },
    'cafeteria': {
      'Familiar': {'desayuno': 3, 'café': 2, 'postres': 4, 'tranquilo': 3, 'niños': 5},
      'Amigos': {'social': 4, 'café': 2, 'grupo': 5, 'ambiente': 3, 'divertido': 3},
      'Solo': {'lectura': 5, 'relajante': 4, 'estudio': 5, 'tranquilo': 4, 'personal': 4},
      'en pareja': {'romántico': 5, 'íntimo': 5, 'acogedor': 4, 'especial': 3},
    },
    'bar': {
      'Amigos': {'fiesta': 5, 'música': 4, 'bebidas': 5, 'social': 4, 'grupo': 5, 'baile': 5},
      'en pareja': {'íntimo': 5, 'elegante': 4, 'romántico': 5, 'tranquilo': 3},
    },
    'parque': {
      'Familiar': {'niños': 5, 'picnic': 5, 'juegos': 5, 'seguro': 4, 'paseo': 3},
      'Amigos': {'grupo': 5, 'diversión': 4, 'paseo': 3, 'deporte': 5},
      'Solo': {'tranquilo': 4, 'relajante': 5, 'naturaleza': 5, 'paseo': 3},
      'en pareja': {'romántico': 5, 'tranquilo': 4, 'paseo': 3, 'vista': 4},
    },
    'playa': {
      'familiar': {'arena': 4, 'mar': 4, 'niños': 5, 'seguro': 5, 'divertido': 3},
      'amigos': {'aventura': 5, 'deportes': 5, 'grupo': 5, 'diversión': 4, 'sol': 3},
      'solo': {'relajante': 5, 'lectura': 4, 'tranquilo': 5, 'paseo': 3, 'paisaje': 4},
      'en pareja': {'romántico': 5, 'relajante': 4, 'vista': 5, 'especial': 4, 'íntimo': 5},
    },
  };

  // 🧠 SOLUCIÓN ERROR 1: Agregamos su propio transformador seguro interno para parsear números
  double _toDouble(dynamic v, {double fb = 0}) {
    if (v == null) return fb;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fb;
    return fb;
  }

  /// Valida si el destino consultado se encuentra dentro del catálogo nacional mexicano
  Future<bool> validarDestinoEnMexico(String destino, List<String> ciudadesValidas) async {
    String destinoNormalizado = destino.toLowerCase().trim();

    // 🔥 EXCEPCIÓN GEOGRÁFICA CRÍTICA: Forzar el contexto de México para "La Paz"
    if (destinoNormalizado == 'la paz' || destinoNormalizado == 'lapaz') {
      destinoNormalizado = 'la paz baja california sur';
    }

    String normalizado = destinoNormalizado
        .replaceAll(RegExp(r'[áäâà]'), 'a')
        .replaceAll(RegExp(r'[éëêè]'), 'e')
        .replaceAll(RegExp(r'[íïîì]'), 'i')
        .replaceAll(RegExp(r'[óöôò]'), 'o')
        .replaceAll(RegExp(r'[úüûù]'), 'u');

    // Revisamos si el de la barra o botón coincide con nuestro catálogo local
    return ciudadesValidas.any((c) {
      String ciudadNorm = c.toLowerCase().trim()
        .replaceAll(RegExp(r'[áäâà]'), 'a')
        .replaceAll(RegExp(r'[éëêè]'), 'e')
        .replaceAll(RegExp(r'[íïîì]'), 'i')
        .replaceAll(RegExp(r'[óöôò]'), 'o')
        .replaceAll(RegExp(r'[úüûù]'), 'u');
      
      // Si el destino es nuestra excepción forzada, la subcadena "la paz" pasará la validación con éxito
      return normalizado.contains(ciudadNorm) || ciudadNorm.contains(normalizado) || 'la paz'.contains(ciudadNorm);
    });
  }

  /// Genera una firma única MD5 para el control de peticiones repetidas
  String generarHashConsulta(String destino, String tipoViaje, String rangoPrecio) {
    String datosString = "${destino.toLowerCase()}_${tipoViaje.toLowerCase()}_$rangoPrecio";
    return md5.convert(utf8.encode(datosString)).toString();
  }

  /// Busca respuestas previas válidas (menores a 30 días) para ahorrar consumo de APIs
  Future<List<Map<String, dynamic>>?> buscarEnCache(String hashQuery) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(hashQuery)) {
        String? dataLocal = prefs.getString(hashQuery);
        if (dataLocal != null) {
          var dec = jsonDecode(dataLocal);
          if (DateTime.now().difference(DateTime.parse(dec['timestamp'])).inDays < 30) {
            return List<Map<String, dynamic>>.from(dec['resultados']);
          }
        }
      }
      DocumentSnapshot doc = await _firestore.collection('cache_busquedas').doc(hashQuery).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
        if (DateTime.now().difference(timestamp).inDays < 30) {
          return List<Map<String, dynamic>>.from(data['resultados']);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Guarda de forma redundante las respuestas optimizadas en disco local y en la nube
  Future<void> guardarEnCache(String hashQuery, List<Map<String, dynamic>> resultados) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      DateTime ahora = DateTime.now();
      await prefs.setString(hashQuery, jsonEncode({'timestamp': ahora.toIso8601String(), 'resultados': resultados}));
      await _firestore.collection('cache_busquedas').doc(hashQuery).set({'timestamp': Timestamp.fromDate(ahora), 'resultados': resultados});
    } catch (_) {}
  }

  List<String> calcularEtiquetasExperiencia(Lugar lugar) {
    // 🔥 SOLUCIÓN: Limpiamos acentos y cambiamos espacios por guiones bajos
    // para que "Cafetería" -> "cafeteria" y "Zona arqueológica" -> "zona_arqueologica"
    String categoriaLimpia = lugar.tipo.toLowerCase().trim()
        .replaceAll(RegExp(r'[áäâà]'), 'a')
        .replaceAll(RegExp(r'[éëêè]'), 'e')
        .replaceAll(RegExp(r'[íïîì]'), 'i')
        .replaceAll(RegExp(r'[óöôò]'), 'o')
        .replaceAll(RegExp(r'[úüûù]'), 'u')
        .replaceAll(' ', '_');

    // Respaldos automáticos para lugares que no están en la matriz de palabras clave
    if (!matrizPesosNLP.containsKey(categoriaLimpia)) {
      if (categoriaLimpia == 'bar' || categoriaLimpia == 'actividades_extremas') {
        return ['Amigos', 'Solo', 'En pareja'];
      } else if (categoriaLimpia == 'museo' || categoriaLimpia == 'parque' || categoriaLimpia == 'zona_arqueologica') {
        return ['Familiar', 'Solo', 'En pareja'];
      } else if (categoriaLimpia == 'mirador' || categoriaLimpia == 'playa') {
        return ['En pareja', 'Familiar', 'Solo', 'Amigos'];
      } else if (categoriaLimpia == 'centro_comercial') {
        return ['Familiar', 'Amigos', 'Solo'];
      }
      return ['Familiar', 'Solo'];
    }

    // Si pasa por la matriz NLP con reseñas de control
    List<String> experienciasAsignadas = [];
    List<String> resenasSimuladas = [
      "ambiente ameno muy divertido para ir con niños familiar y seguro",
      "un lugar hermoso sumamente romántico ideal para una cena en pareja",
      "excelente para ir con amigos a tomar bebidas y pasarla bien"
    ];

    matrizPesosNLP[categoriaLimpia]!.forEach((experiencia, mapaPalabras) {
      double puntajeEtiqueta = 0.0;
      for (String resena in resenasSimuladas) {
        List<String> palabras = resena.toLowerCase().split(RegExp(r'\W+'));
        for (String palabra in palabras) {
          if (listaNegraNLP.contains(palabra)) continue;
          if (mapaPalabras.containsKey(palabra)) {
            double pesoPalabra = mapaPalabras[palabra]!;
            int nCategorias = 0;
            matrizPesosNLP[categoriaLimpia]!.forEach((k, v) {
              if (v.containsKey(palabra)) nCategorias++;
            });
            puntajeEtiqueta += pesoPalabra / (nCategorias > 0 ? nCategorias : 1);
          }
        }
      }

      if (puntajeEtiqueta >= 8.0) {
        String expNormalizada = experiencia.trim();
        if (expNormalizada.toLowerCase() == 'en pareja') {
          experienciasAsignadas.add('En pareja');
        } else {
          experienciasAsignadas.add(expNormalizada[0].toUpperCase() + expNormalizada.substring(1));
        }
      }
    });

    if (experienciasAsignadas.isEmpty) {
      return ['Familiar', 'Solo', 'Amigos', 'En pareja'];
    }

    return experienciasAsignadas.toSet().toList();
  }

  /// Ejecuta el cruce de vectores de intereses mediante similitud coseno con umbral > 70%
  Future<List<String>> obtenerSugerenciasOtrosViajeros(String idUsuarioActivo, List<double> vectorA) async {
    List<String> sugerencias = [];
    try {
      QuerySnapshot snap = await _firestore.collection('usuarios').get();
      for (var doc in snap.docs) {
        if (doc.id == idUsuarioActivo) continue;
        var data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey('vector_intereses')) continue;

        var vectorMap = data['vector_intereses'] as Map<String, dynamic>;
        List<double> vectorB = [
          _toDouble(vectorMap['Restaurante']),
          _toDouble(vectorMap['Cafetería']),
          _toDouble(vectorMap['Bar']),
          _toDouble(vectorMap['Parque']),
        ];

        double productoPunto = 0.0;
        double magA = 0.0;
        double magB = 0.0;

        for (int i = 0; i < min(vectorA.length, vectorB.length); i++) {
          productoPunto += vectorA[i] * vectorB[i];
          magA += pow(vectorA[i], 2);
          magB += pow(vectorB[i], 2);
        }

        if (magA > 0 && magB > 0) {
          double similitudCoseno = productoPunto / (sqrt(magA) * sqrt(magB));
          if (similitudCoseno >= 0.7) {
            List<String> favoritos = List<String>.from(data['destinos_favoritos'] ?? []);
            sugerencias.addAll(favoritos);
          }
        }
      }
    } catch (_) {}
    return sugerencias.toSet().toList();
  }

  static String normalizarTipoParaBuscador(List<dynamic> categoriesFromApi, String placeName) {
  final nameLower = placeName.toLowerCase().trim();
  final todoElTexto = categoriesFromApi.map((e) => e.toString().toLowerCase()).join(",");

  // Mapeo Estándar (Los nombres aquí DEBEN coincidir con los de tus botones de filtro)
  if (nameLower.contains("café") || nameLower.contains("coffee") || nameLower.contains("panaderia") || todoElTexto.contains("cafe") || todoElTexto.contains("coffee") || todoElTexto.contains("bakery") || todoElTexto.contains("pastry")) return "Cafetería";  if (nameLower.contains("bar") || todoElTexto.contains("bar") || todoElTexto.contains("night_club")) return "Bar";
  if (nameLower.contains("parque") || todoElTexto.contains("garden") || todoElTexto.contains("park")) return "Parque";
  if (nameLower.contains("museo") || todoElTexto.contains("museum")) return "Museo";
  if (nameLower.contains("playa") || todoElTexto.contains("beach") || todoElTexto.contains("sea")) return "Playa";
  if (nameLower.contains("monumento") || nameLower.contains("iglesia") || todoElTexto.contains("monument") || todoElTexto.contains("church")) return "Monumento";
  if (nameLower.contains("arqueológica") || todoElTexto.contains("ruins") || todoElTexto.contains("archaeolog")) return "Zona arqueológica";
  if (nameLower.contains("mirador") || todoElTexto.contains("viewpoint")) return "Mirador";
  if (nameLower.contains("mall") || nameLower.contains("plaza") || todoElTexto.contains("shopping")) return "Centro comercial";
  if (nameLower.contains("extremo") || nameLower.contains("aventura") || todoElTexto.contains("extreme")) return "Actividades extremas";
  if (nameLower.contains("restaurante") || nameLower.contains("tacos") || todoElTexto.contains("restaurant") || todoElTexto.contains("food")) return "Restaurante";

  return "Otro";
}

  /// ASIGNADOR INTELIGENTE DE PRECIO SIMULADO (Para que los filtros de precio tengan datos variados)
  static String calcularPrecioSimulado(dynamic apiPrice, String placeName) {
    if (apiPrice != null && apiPrice.toString().isNotEmpty) {
      String value = apiPrice.toString().trim();
      if (value == "1" || value == "\$") return "\$";
      if (value == "2" || value == "\$\$") return "\$\$";
      if (value == "3" || value == "\$\$\$") return "\$\$\$\$"; // O tu formato estándar
    }
    
    final length = placeName.length;
    if (placeName.toLowerCase().contains("tacos") || placeName.toLowerCase().contains("tortas")) return "\$";
    
    if (length % 3 == 0) return "\$";
    if (length % 3 == 1) return "\$\$";
    return "\$\$\$";
  }

  static List<Map<String, dynamic>> filtrarYObtenerTop5({
    required List<Map<String, dynamic>> listaCompleta,
    required String? tipo,
    required String? precio,
    required String? experiencia,
    required String queryTexto,
  }) {
    final textoBusqueda = queryTexto.toLowerCase().trim();

    // Aplicamos el filtrado inteligente
    final procesados = listaCompleta.where((lugar) {
      final nombre = (lugar["name"] ?? "").toString().toLowerCase();
      final direccion = (lugar["direccion"] ?? lugar["vicinity"] ?? "").toString().toLowerCase();
      
      // 🚫 CONTROL DE FRONTERAS
      if (direccion.contains("miami") || 
          direccion.contains("houston") || 
          direccion.contains("fl ") || 
          direccion.contains("usa") || 
          direccion.contains("united states")) {
        return false; 
      }

      // Relajamos a 3000 km para que no bloquee Cancún ni Tijuana
      final distanciaKM = double.tryParse(lugar["distancia"].toString()) ?? 0.0;
      if (distanciaKM > 3000.0) {
        return false;
      }

      // 🔥 FILTRO DE TEXTO INTELIGENTE REPARADO
      // Si escribió algo, buscamos en el nombre O en la dirección
      final coincideBusqueda = textoBusqueda.isEmpty || 
                               nombre.contains(textoBusqueda) || 
                               direccion.contains(textoBusqueda);

      // Función auxiliar rápida para quitar acentos
      String quitarAcentos(String s) {
        return s.toLowerCase().trim()
          .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
          .replaceAll('ó', 'o').replaceAll('ú', 'u');
      }

      // Filtro Determinante: TIPO DE LUGAR (A prueba de acentos)
      final tipoLugar = quitarAcentos((lugar["categoriaPrincipal"] ?? "").toString());
      final tipoFiltro = tipo != null ? quitarAcentos(tipo) : null;
      final coincideTipo = tipo == null || tipoLugar == tipoFiltro;

      // Filtro Secundario 1: PRECIO
      final precioLugar = (lugar["precio"] ?? "").toString().trim();
      final precioFiltro = precio != null ? precio.trim() : null;
      final coincidePrecio = precio == null || precioLugar == precioFiltro;

      // Filtro Secundario 2: EXPERIENCIA
      final listadoExperiencias = lugar["experiencias"] as List<dynamic>? ?? [];
      final experienciasLimpias = listadoExperiencias.map((e) => e.toString().toLowerCase().trim()).toList();
      final coincideExperiencia = experiencia == null || experienciasLimpias.contains(experiencia.toLowerCase().trim());

      // Solo sobreviven los lugares que cumplan TODOS los filtros activos
      return coincideBusqueda && coincideTipo && coincidePrecio && coincideExperiencia;
    }).toList();

    return procesados.take(5).toList();
  }


}