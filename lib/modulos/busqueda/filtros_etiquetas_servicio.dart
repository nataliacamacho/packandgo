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
    }
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
    String normalizado = destino.toLowerCase().trim();
    return ciudadesValidas.any((c) => c.toLowerCase().trim() == normalizado);
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

  /// Algoritmo NLP: Suma ponderada de descriptores léxicos analizados bajo un umbral de 8 puntos
  List<String> calcularEtiquetasExperiencia(Lugar lugar) {
    List<String> experienciasAsignadas = [];
    String categoriaLimpia = lugar.tipo.toLowerCase().trim();

    if (!matrizPesosNLP.containsKey(categoriaLimpia)) {
      if (categoriaLimpia == 'bar' || categoriaLimpia == 'actividades_extremas') return ['Amigos'];
      return ['Familiar', 'Solo'];
    }

    matrizPesosNLP[categoriaLimpia]!.forEach((experiencia, mapaPalabras) {
      double puntajeEtiqueta = 0.0;

      for (String resena in lugar.resenasTexto) {
        List<String> palabras = resena.toLowerCase().split(RegExp(r'\W+'));
        for (String palabra in palabras) {
          if (listaNegraNLP.contains(palabra)) continue;

          if (mapaPalabras.containsKey(palabra)) {
            double pesoPalabra = mapaPalabras[palabra]!;
            
            // Fórmula de mitigación de ambigüedad por co-ocurrencia multi-etiqueta
            int nCategorias = 0;
            matrizPesosNLP[categoriaLimpia]!.forEach((k, v) {
              if (v.containsKey(palabra)) nCategorias++;
            });

            puntajeEtiqueta += pesoPalabra / (nCategorias > 0 ? nCategorias : 1);
          }
        }
      }

      // Condición lógica de asignación sobre umbral de confianza mínimo
      if (puntajeEtiqueta >= 8.0) {
        experienciasAsignadas.add(experiencia);
      }
    });

    if (experienciasAsignadas.isEmpty) {
      if (categoriaLimpia == 'bar') experienciasAsignadas.add('Amigos');
      else experienciasAsignadas.add('Familiar');
    }

    return experienciasAsignadas;
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
}