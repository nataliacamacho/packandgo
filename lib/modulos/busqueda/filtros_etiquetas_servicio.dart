import 'dart:convert';
import 'dart:math'; 
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final Set<String> listaNegraNLP = {'bonito', 'agradable', 'bueno', 'lugar', 'excelente', 'bien'};

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

  
  // Diccionario de respaldo: Si no hay la categoría principal, busca estas alternativas.
  static const Map<String, List<String>> categoriasHomologas = {
    'playa': ['Parque', 'Mirador', 'Actividades extremas'],
    'museo': ['Monumento', 'Zona arqueológica', 'Centro comercial'],
    'monumento': ['Museo', 'Zona arqueológica', 'Parque'],
    'bar': ['Restaurante', 'Cafetería'],
    'cafetería': ['Restaurante', 'Centro comercial'],
    'restaurante': ['Cafetería', 'Bar'],
    'parque': ['Mirador', 'Zona arqueológica', 'Actividades extremas'],
    'zona arqueológica': ['Museo', 'Monumento', 'Parque'],
    'actividades extremas': ['Parque', 'Mirador', 'Playa'],
    'centro comercial': ['Cafetería', 'Restaurante', 'Mirador'],
  };


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
    // Limpiamos acentos y cambiamos espacios por guiones bajos
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

    // 1. ESCUDO ANTI-FALSOS POSITIVOS (Bloquea negocios con nombres engañosos)
    bool esNegocio = todoElTexto.contains("store") || todoElTexto.contains("liquor") || 
                     todoElTexto.contains("travel_agency") || todoElTexto.contains("clothing") || 
                     todoElTexto.contains("real_estate") || todoElTexto.contains("grocery") ||
                     nameLower.contains("bodega") || nameLower.contains("agencia") || 
                     nameLower.contains("sucursal") || nameLower.contains("rancho");
                     
    if (esNegocio) return "Comercio"; // Al darle esta categoría, tus filtros lo van a ignorar

    // 2. MAPEO ESTÁNDAR
    if (nameLower.contains("café") || nameLower.contains("coffee") || nameLower.contains("panaderia") || todoElTexto.contains("cafe") || todoElTexto.contains("coffee") || todoElTexto.contains("bakery") || todoElTexto.contains("pastry")) return "Cafetería";  
    if (nameLower.contains("bar") || todoElTexto.contains("bar") || todoElTexto.contains("night_club")) return "Bar";
    
    // 3. HOMOLOGACIÓN DE NATURALEZA (Presas, cerros y bosques ahora serán Parque en lugar de "Otro")
    if (nameLower.contains("parque") || nameLower.contains("presa") || nameLower.contains("cerro") || nameLower.contains("bosque") || nameLower.contains("lago") || todoElTexto.contains("garden") || todoElTexto.contains("park") || todoElTexto.contains("natural_feature")) return "Parque";
    
    if (nameLower.contains("museo") || todoElTexto.contains("museum")) return "Museo";
    
    // 4. PLAYA PROTEGIDA (Solo entra aquí si superó el escudo anti-negocios)
    if (nameLower.contains("playa") || todoElTexto.contains("beach") || todoElTexto.contains("sea")) return "Playa";
    
    if (nameLower.contains("monumento") || nameLower.contains("iglesia") || todoElTexto.contains("monument") || todoElTexto.contains("church")) return "Monumento";
    if (nameLower.contains("arqueológica") || todoElTexto.contains("ruins") || todoElTexto.contains("archaeolog")) return "Zona arqueológica";
    if (nameLower.contains("mirador") || todoElTexto.contains("viewpoint")) return "Mirador";
    if (nameLower.contains("mall") || nameLower.contains("plaza") || todoElTexto.contains("shopping")) return "Centro comercial";
    if (nameLower.contains("extremo") || nameLower.contains("aventura") || todoElTexto.contains("extreme")) return "Actividades extremas";
    if (nameLower.contains("restaurante") || nameLower.contains("tacos") || todoElTexto.contains("restaurant") || todoElTexto.contains("food")) return "Restaurante";

    return "Otro";
  }

  /// ASIGNADOR DE PRECIO SIMULADO (Para que los filtros de precio tengan datos variados)
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
    List<Map<String, dynamic>> procesados = listaCompleta.where((lugar) {
      final nombre = (lugar["name"] ?? "").toString().toLowerCase();
      final direccion = (lugar["direccion"] ?? lugar["vicinity"] ?? "").toString().toLowerCase();
      
      // 1. Candado internacional original intacto
      if (direccion.contains("miami") || 
          direccion.contains("houston") || 
          direccion.contains("fl ") || 
          direccion.contains("usa") || 
          direccion.contains("united states")) {
        return false; 
      }

      // 2. Limitador de distancia original a 3000 km
      final distanciaKM = double.tryParse(lugar["distancia"].toString()) ?? 0.0;
      if (distanciaKM > 3000.0) {
        return false;
      }

      // 3. Filtro de texto inteligente original
      final coincideBusqueda = textoBusqueda.isEmpty || 
                               nombre.contains(textoBusqueda) || 
                               direccion.contains(textoBusqueda);

      // Función auxiliar rápida original para quitar acentos
      String quitarAcentos(String s) {
        return s.toLowerCase().trim()
          .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
          .replaceAll('ó', 'o').replaceAll('ú', 'u');
      }

      // ====================================================================
      // REPARACIÓN MAESTRA DEL FILTRO DETERMINANTE: TIPO DE LUGAR
      // ====================================================================
      final tipoLugar = quitarAcentos((lugar["categoriaPrincipal"] ?? "").toString());
      final tipoFiltro = tipo != null ? quitarAcentos(tipo) : null;
      
      bool coincideTipo = false;

      if (tipo == null) {
        coincideTipo = true; // Si no hay chip seleccionado, todo pasa
      } else {
        // Validación semántica para categorías no estrictas de naturaleza/aventura
        if (tipoFiltro!.contains('playa')) {
          // Es una playa real o un cuerpo de agua natural de interior válido (Chihuahua/Ajijic)
          bool esCuerpoAgua = tipoLugar.contains('beach') || tipoLugar.contains('playa') || 
                              tipoLugar.contains('natural') || nombre.contains('presa') || 
                              nombre.contains('laguna') || nombre.contains('rio');
          
          // Bloqueo estricto: Prohibido restaurantes, neverías, templos o tiendas con nombre "playa"
          bool esFalsoPositivo = tipoLugar.contains('restaurante') || tipoLugar.contains('cafe') || 
                                 tipoLugar.contains('iglesia') || tipoLugar.contains('templo') ||
                                 nombre.contains('helado') || nombre.contains('neveria') || 
                                 nombre.contains('pizza') || nombre.contains('caesars');

          coincideTipo = esCuerpoAgua && !esFalsoPositivo;
        } 
        else if (tipoFiltro.contains('arqueo')) {
          // Acepta zonas arqueológicas explícitas, ruinas, sitios históricos o museos de sitio
          coincideTipo = tipoLugar.contains('arqueo') || tipoLugar.contains('historic') || 
                         tipoLugar.contains('monumento') || nombre.contains('zona arqueo') || 
                         nombre.contains('ruinas') || nombre.contains('paquime');
        } 
        else if (tipoFiltro.contains('extrem')) {
          coincideTipo = tipoLugar.contains('extrem') || tipoLugar.contains('parque') || 
                         tipoLugar.contains('adventure') || nombre.contains('paragliding') || 
                         nombre.contains('bungee');
        } 
        else {
          // Filtro exacto original para categorías urbanas (Café, Restaurante, Bar, Museo)
          coincideTipo = tipoLugar == tipoFiltro;
        }
      }

      // 4. Filtro secundario 1: Precio original
      final precioLugar = (lugar["precio"] ?? "").toString().trim();
      final precioFiltro = precio != null ? precio.trim() : null;
      final coincidePrecio = precio == null || precioLugar == precioFiltro;

      // 5. Filtro secundario 2: Experiencia original
      final listadoExperiencias = lugar["experiencias"] as List<dynamic>? ?? [];
      final experienciasLimpias = listadoExperiencias.map((e) => e.toString().toLowerCase().trim()).toList();
      final expFiltro = experiencia != null ? experiencia.toLowerCase().trim() : '';
      
      final coincideExperiencia = experiencia == null || experiencia.isEmpty || 
          experienciasLimpias.any((etiqueta) => expFiltro.contains(etiqueta) || etiqueta.contains(expFiltro));

      // Retorna verdadero solo si el lugar supera todas las compuertas
      return coincideBusqueda && coincideTipo && coincidePrecio && coincideExperiencia;
    }).toList();

    // ====================================================================
    // CANDADO DE GARANTÍA DE CONTROL DE CUOTA: 5 TARJETAS SIN DISFRAZ
    // ====================================================================
    if (procesados.length < 5) {
      for (var lugarGen in listaCompleta) {
        if (procesados.length >= 5) break;

        // Verificamos que no esté ya metido en la lista limpia
        bool yaExiste = procesados.any((element) => element['name'] == lugarGen['name']);
        
        if (!yaExiste) {
          // REGLA CLAVE: Lo metemos para cumplir las 5 tarjetas obligatorias,
          // pero conservando sus datos reales intactos para que NO se disfrace con el icono del filtro.
          procesados.add(lugarGen);
        }
      }
    }
    // ====================================================================
    // CANDADO DE GARANTÍA DE CONTROL DE CUOTA CORREGIDO
    // ====================================================================
    if (procesados.length < 5) {
      for (var lugarGen in listaCompleta) {
        if (procesados.length >= 5) break;

        bool yaExiste = procesados.any((element) => element['name'] == lugarGen['name']);
        
        // Obtenemos la categoría real del lugar
        final catActual = (lugarGen["categoriaPrincipal"] ?? "").toString().toLowerCase();
        
        // ¡LA CLAVE!: Solo lo agregamos si no existe y si NO es un comercio basura
        if (!yaExiste && catActual != 'comercio') {
          procesados.add(lugarGen);
        }
      }
    }

    return procesados.take(5).toList();
  }

  // MOTOR DE AUTOCOMPLETADO (RQF34 y RQF35)
  /// Función auxiliar para limpiar acentos y caracteres raros
  static String _removerAcentos(String texto) {
    var conAcentos = 'áéíóúüñÁÉÍÓÚÜÑ';
    var sinAcentos = 'aeiouunAEIOUUN';
    String resultado = texto;
    for (int i = 0; i < conAcentos.length; i++) {
      resultado = resultado.replaceAll(conAcentos[i], sinAcentos[i]);
    }
    return resultado.toLowerCase().trim();
  }

  /// Algoritmo matemático de Distancia de Levenshtein (Mide variaciones de letras)
  static int _calcularLevenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int costo = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + costo].reduce((a, b) => a < b ? a : b);
      }
      v0 = List<int>.from(v1);
    }
    return v0[s2.length];
  }
//autocompletar destinos
  /// Filtra una lista de destinos oficiales de México tolerando errores ortográficos y acentos
  static List<String> autocompletarDestinos(String inputUsuario) {
    if (inputUsuario.trim().length < 2) return [];

    final List<String> catalogoDestinos = [
      // Urber Principales y Playas Famosas
      "Acapulco", "Guadalajara", "Manzanillo", "Puebla", "Caborca", 
      "Cancún", "Monterrey", "Oaxaca", "Mazatlán", "Chapala", "Ajijic",
      "Bacalar", "Mérida", "Puerto Vallarta", "Cozumel", "Querétaro",
      "Tulum", "Guanajuato", "Cabo San Lucas", "San José del Cabo",
      "Tijuana", "Veracruz", "Mazamitla", "Tapalpa", "Tequila",
      "Playa del Carmen", "Huatulco", "Puerto Escondido", "Zihuatanejo",
      "Cuernavaca", "Pachuca", "San Luis Potosí", "Zacatecas", "Morelia",
      "Pátzcuaro", "Taxco", "Valle de Bravo", "Tepoztlán", "Malinalco",
      
      // Pueblos Mágicos y Destinos Culturales Clave
      "Teotihuacán", "San Miguel de Allende", "Campeche", "Palenque",
      "San Cristóbal de las Casas", "Comitán", "Izamal", "Valladolid",
      "Sayulita", "San Blas", "Loreto", "Todos Santos", "Creel",
      "Batopilas", "Parras de la Fuente", "Cuatro Ciénegas", "Arteaga",
      "Santiago", "Real de Catorce", "Xilitla", "Aquismón", "Jerez",
      "Sombrerete", "Pinos", "Dolores Hidalgo", "Mineral de Pozos",
      "Salvatierra", "Yuriria", "Jalpan de Serra", "Cadereyta",
      "Bernal", "Tequisquiapan", "Amealco", "Huichapan", "Tecozautla",
      "Real del Monte", "Huasca de Ocampo", "Mineral del Chico"
    ];

    final inputLimpio = _removerAcentos(inputUsuario);
    List<Map<String, dynamic>> candidatosConPuntaje = [];

    for (var destino in catalogoDestinos) {
      final destinoLimpio = _removerAcentos(destino);

      // Coincidencia Directa o Parcial (Contiene el texto ingresado)
      if (destinoLimpio.contains(inputLimpio) || inputLimpio.contains(destinoLimpio)) {
        candidatosConPuntaje.add({'destino': destino, 'score': 0});
        continue;
      }

      // Coincidencia Difusa: Si el usuario se equivoca por 1 o 2 letras (Levenshtein)
      // Solo evaluamos si las longitudes son similares para no alentar la app
      if ((destinoLimpio.length - inputLimpio.length).abs() <= 3) {
        int distancia = _calcularLevenshtein(inputLimpio, destinoLimpio);
        // Si el error es de máximo 2 letras cambiadas o faltantes, es válido
        if (distancia <= 2) {
          candidatosConPuntaje.add({'destino': destino, 'score': distancia});
        }
      }
    }

    // Ordenamos para que los aciertos más exactos salgan primero
    candidatosConPuntaje.sort((a, b) => a['score'].compareTo(b['score']));

    // Regresamos solo los nombres en texto limpios (Máximo 4 sugerencias para la UI)
    return candidatosConPuntaje.map((e) => e['destino'] as String).take(4).toList();
  }

  /// Rellena de forma inteligente una lista turística para garantizar 5 tarjetas
  /// utilizando categorías homólogas si la principal no está disponible.
  static List<Map<String, dynamic>> rellenarGarantiaCincoTarjetas({
    required List<Map<String, dynamic>> listaActual,
    required String? tipoFiltro,
    required List<dynamic> lugaresExtraDescargados,
  }) {
    if (listaActual.length >= 5) return listaActual;

    List<Map<String, dynamic>> listaResultado = List.from(listaActual);
    String filtro = (tipoFiltro ?? '').toLowerCase();
    
    // Obtenemos la lista de categorías permitidas como respaldo para este filtro
    List<String> respaldosPermitidos = categoriasHomologas[filtro] ?? [];

    for (var lugarCrudo in lugaresExtraDescargados) {
      if (listaResultado.length >= 5) break;

      final lugar = Map<String, dynamic>.from(lugarCrudo);
      final nombre = (lugar['name'] ?? '').toLowerCase();
      final types = (lugar['types'] as List<dynamic>? ?? []);
      
      // Calculamos la categoría REAL del lugar usando tu propio normalizador
      String categoriaReal = normalizarTipoParaBuscador(types, nombre);

      // Identificadores de basura
      bool esReligioso = types.contains('place_of_worship') || nombre.contains('santuario') || 
                         nombre.contains('templo') || nombre.contains('parroquia') || 
                         nombre.contains('catedral') || nombre.contains('capilla');

      // Si no hay filtro, o si la categoría real del lugar coincide con los respaldos permitidos
      if (tipoFiltro == null || (respaldosPermitidos.contains(categoriaReal) && !esReligioso)) {
        bool yaExiste = listaResultado.any((l) => l['name'] == lugar['name']);
        
        if (!yaExiste) {
          listaResultado.add({
            ...lugar,
            // AQUI ESTA LA MAGIA: Asignamos su categoría real, no la forzamos.
            'categoriaPrincipal': categoriaReal, 
            'notaRelleno': 'Sugerencia similar'
          });
        }
      }
    }

    // Si después del filtrado estricto homólogo aún no llegamos a 5, rellenamos con lo que sea que no sea iglesia
    if (listaResultado.length < 5) {
      for (var lugarCrudo in lugaresExtraDescargados) {
        if (listaResultado.length >= 5) break;
        final lugar = Map<String, dynamic>.from(lugarCrudo);
        final nombre = (lugar['name'] ?? '').toLowerCase();
        final types = (lugar['types'] as List<dynamic>? ?? []);
        String categoriaReal = normalizarTipoParaBuscador(types, nombre);
        
        bool esReligioso = types.contains('place_of_worship') || nombre.contains('santuario') || 
                           nombre.contains('templo');

        bool yaExiste = listaResultado.any((l) => l['name'] == lugar['name']);
        if (!yaExiste && !esReligioso) {
           listaResultado.add({
            ...lugar,
            'categoriaPrincipal': categoriaReal, 
            'notaRelleno': 'Sugerencia adicional'
          });
        }
      }
    }

    return listaResultado;
  }

}