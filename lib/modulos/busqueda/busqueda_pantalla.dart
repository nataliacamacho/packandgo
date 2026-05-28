import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto/compartidos/widgets/barra_busqueda.dart';
import 'package:proyecto/compartidos/widgets/filtros_busqueda.dart';
import 'package:proyecto/compartidos/widgets/tarjeta_lugar.dart';
import 'package:proyecto/modulos/busqueda/lugar_detalle_pantalla.dart';

import 'package:proyecto/nucleo/servicios/google_places_servicio.dart';
import 'package:proyecto/nucleo/servicios/opentripmap_servicio.dart';
import 'package:proyecto/nucleo/servicios/ubicacion_servicio.dart';
import 'package:proyecto/modulos/busqueda/filtros_etiquetas_servicio.dart';

// ---------------------------------------------------------------------------
// CIUDADES DE MÉXICO
// ---------------------------------------------------------------------------
const List<Map<String, dynamic>> _ciudadesMexico = [
  {"id": "cdmx", "nombre": "Ciudad de México", "lat": 19.4326, "lng": -99.1332},
  {"id": "gdl", "nombre": "Guadalajara", "lat": 20.6597, "lng": -103.3496},
  {"id": "mty", "nombre": "Monterrey", "lat": 25.6866, "lng": -100.3161},
  {"id": "cancun", "nombre": "Cancún", "lat": 21.1619, "lng": -86.8515},
  {"id": "puebla", "nombre": "Puebla", "lat": 19.0414, "lng": -98.2063},
  {"id": "merida", "nombre": "Mérida", "lat": 20.9674, "lng": -89.5926},
  {"id": "tijuana", "nombre": "Tijuana", "lat": 32.5149, "lng": -117.0382},
  {"id": "leon", "nombre": "León", "lat": 21.1220, "lng": -101.6823},
  {"id": "queretaro", "nombre": "Querétaro", "lat": 20.5888, "lng": -100.3899},
  {"id": "toluca", "nombre": "Toluca", "lat": 19.2826, "lng": -99.6557},
  {"id": "acapulco", "nombre": "Acapulco", "lat": 16.8531, "lng": -99.8237},
  {
    "id": "puertovallarta",
    "nombre": "Puerto Vallarta",
    "lat": 20.6534,
    "lng": -105.2253,
  },
  {"id": "loscabos", "nombre": "Los Cabos", "lat": 22.8905, "lng": -109.9167},
  {"id": "mazatlan", "nombre": "Mazatlán", "lat": 23.2494, "lng": -106.4111},
  {"id": "veracruz", "nombre": "Veracruz", "lat": 19.1738, "lng": -96.1342},
  {"id": "oaxaca", "nombre": "Oaxaca", "lat": 17.0732, "lng": -96.7266},
  {
    "id": "sanmiguel",
    "nombre": "San Miguel de Allende",
    "lat": 20.9144,
    "lng": -100.7430,
  },
  {
    "id": "guanajuato",
    "nombre": "Guanajuato",
    "lat": 21.0190,
    "lng": -101.2574,
  },
  {"id": "morelia", "nombre": "Morelia", "lat": 19.7050, "lng": -101.1949},
  {"id": "zacatecas", "nombre": "Zacatecas", "lat": 22.7709, "lng": -102.5832},
  {
    "id": "tuxtla",
    "nombre": "Tuxtla Gutiérrez",
    "lat": 16.7528,
    "lng": -93.1167,
  },
  {
    "id": "sancristobal",
    "nombre": "San Cristóbal de las Casas",
    "lat": 16.7370,
    "lng": -92.6376,
  },
  {
    "id": "villahermosa",
    "nombre": "Villahermosa",
    "lat": 17.9895,
    "lng": -92.9475,
  },
  {"id": "campeche", "nombre": "Campeche", "lat": 19.8301, "lng": -90.5349},
  {"id": "chetumal", "nombre": "Chetumal", "lat": 18.5043, "lng": -88.3053},
  {
    "id": "playadelcarmen",
    "nombre": "Playa del Carmen",
    "lat": 20.6296,
    "lng": -87.0739,
  },
  {"id": "tulum", "nombre": "Tulum", "lat": 20.2114, "lng": -87.4654},
  {"id": "cozumel", "nombre": "Cozumel", "lat": 20.4229, "lng": -86.9223},
  {
    "id": "aguascalientes",
    "nombre": "Aguascalientes",
    "lat": 21.8853,
    "lng": -102.2916,
  },
  {"id": "saltillo", "nombre": "Saltillo", "lat": 25.4383, "lng": -100.9737},
  {"id": "torreon", "nombre": "Torreón", "lat": 25.5428, "lng": -103.4068},
  {"id": "chihuahua", "nombre": "Chihuahua", "lat": 28.6329, "lng": -106.0691},
  {"id": "juarez", "nombre": "Ciudad Juárez", "lat": 31.6904, "lng": -106.4245},
  {"id": "durango", "nombre": "Durango", "lat": 24.0277, "lng": -104.6532},
  {
    "id": "hermosillo",
    "nombre": "Hermosillo",
    "lat": 29.0729,
    "lng": -110.9559,
  },
  {"id": "caborca", "nombre": "Caborca", "lat": 30.7167, "lng": -112.1500},
  {"id": "lapaz", "nombre": "La Paz", "lat": 24.1426, "lng": -110.3128},
  {"id": "ensenada", "nombre": "Ensenada", "lat": 31.8667, "lng": -116.6000},
  {"id": "colima", "nombre": "Colima", "lat": 19.2433, "lng": -103.7241},
  {
    "id": "manzanillo",
    "nombre": "Manzanillo",
    "lat": 19.1138,
    "lng": -104.3385,
  },
  {"id": "tepic", "nombre": "Tepic", "lat": 21.5085, "lng": -104.8956},
  {
    "id": "nuevovallarta",
    "nombre": "Nuevo Vallarta",
    "lat": 20.6829,
    "lng": -105.2850,
  },
  {"id": "cuernavaca", "nombre": "Cuernavaca", "lat": 18.9242, "lng": -99.2216},
  {"id": "taxco", "nombre": "Taxco", "lat": 18.5563, "lng": -99.6057},
  {"id": "tlaxcala", "nombre": "Tlaxcala", "lat": 19.3139, "lng": -98.2404},
  {"id": "pachuca", "nombre": "Pachuca", "lat": 20.1011, "lng": -98.7591},
  {"id": "tula", "nombre": "Tula de Allende", "lat": 20.0544, "lng": -99.3429},
  {"id": "xalapa", "nombre": "Xalapa", "lat": 19.5438, "lng": -96.9102},
  {"id": "coatepec", "nombre": "Coatepec", "lat": 19.4524, "lng": -96.9613},
  {"id": "orizaba", "nombre": "Orizaba", "lat": 18.8506, "lng": -97.1036},
  {"id": "metepec", "nombre": "Metepec", "lat": 19.2530, "lng": -99.6010},
  {
    "id": "vallebravo",
    "nombre": "Valle de Bravo",
    "lat": 19.1925,
    "lng": -100.1327,
  },
  {"id": "izamal", "nombre": "Izamal", "lat": 20.9300, "lng": -89.0200},
  {"id": "valladolid", "nombre": "Valladolid", "lat": 20.6896, "lng": -88.2017},
  {"id": "bacalar", "nombre": "Bacalar", "lat": 18.6783, "lng": -88.3891},
  {"id": "holbox", "nombre": "Isla Holbox", "lat": 21.5236, "lng": -87.3000},
  {
    "id": "realcatorce",
    "nombre": "Real de Catorce",
    "lat": 23.6900,
    "lng": -100.8900,
  },
  {"id": "slp", "nombre": "San Luis Potosí", "lat": 22.1565, "lng": -100.9855},
  {"id": "tequila", "nombre": "Tequila", "lat": 20.8823, "lng": -103.8355},
  {"id": "chapala", "nombre": "Chapala", "lat": 20.2967, "lng": -103.1917},
  {"id": "ajijic", "nombre": "Ajijic", "lat": 20.2972, "lng": -103.2542},
];

// ---------------------------------------------------------------------------
// PANTALLA
// ---------------------------------------------------------------------------
class BusquedaPantalla extends StatefulWidget {
  final bool esSeleccion;
  final String? destinoInicial;

  const BusquedaPantalla({
    super.key,
    this.esSeleccion = false,
    this.destinoInicial,
  });

  @override
  State<BusquedaPantalla> createState() => _BusquedaPantallaState();
}

class _BusquedaPantallaState extends State<BusquedaPantalla> {
  // -------------------------------------------------------------------------
  // FILTROS
  // -------------------------------------------------------------------------
  String query = '';
  String? destinoSeleccionado;
  String? tipoSeleccionado;
  String? estiloSeleccionado;
  String? precioSeleccionado;

  // -------------------------------------------------------------------------
  // ESTADO
  // -------------------------------------------------------------------------
  bool cargando = false;
  String? error;

  List<Map<String, dynamic>> lugares = [];

  // -------------------------------------------------------------------------
  // USUARIO
  // -------------------------------------------------------------------------
  final String _idUsuario = FirebaseAuth.instance.currentUser?.uid ?? '';

  Map<String, dynamic> _intereses = {};

  // -------------------------------------------------------------------------
  // UBICACIÓN
  // -------------------------------------------------------------------------
  double _latActual = 20.6597;
  double _lngActual = -103.3496;

  //para el algoritmo de filtros
  final FiltrosEtiquetasServicio _servicioFiltros = FiltrosEtiquetasServicio();
  @override
  void initState() {
    super.initState();
    if (widget.destinoInicial != null) {
      destinoSeleccionado = _resolverIdDestino(widget.destinoInicial!);
    }
    _inicializar();
  }

  String? _resolverIdDestino(String nombreDestino) {
    final normalizado = nombreDestino.toLowerCase().trim();
    try {
      final ciudad = _ciudadesMexico.firstWhere(
        (c) =>
            c['nombre'].toString().toLowerCase().contains(normalizado) ||
            normalizado.contains(c['nombre'].toString().toLowerCase()),
      );
      return ciudad['id'] as String;
    } catch (_) {
      return null; // No encontró coincidencia, no pasa nada
    }
  }

  // -------------------------------------------------------------------------
  // INIT
  // -------------------------------------------------------------------------
  Future<void> _inicializar() async {
    await _cargarIntereses();
    await _resolverCoordenadas();
    await _buscar();
  }

  Future<void> _cargarIntereses() async {
    if (_idUsuario.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_idUsuario)
          .get();

      if (doc.exists) {
        _intereses =
            (doc.data()?['vector_intereses'] ?? {}) as Map<String, dynamic>;
      }
    } catch (_) {}
  }

Future<void> _resolverCoordenadas() async {
    // 1. Intentamos sacar las coordenadas del destino seleccionado o del texto escrito
    String posibleDestino = destinoSeleccionado ?? query;
    
    if (posibleDestino.isNotEmpty) {
      // Quitamos mayúsculas y acentos
      final destinoLimpio = posibleDestino.toLowerCase().trim()
          .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
          .replaceAll('ó', 'o').replaceAll('ú', 'u');

      final ciudad = _ciudadesMexico.firstWhere(
        (c) {
          String nombreNorm = c['nombre'].toString().toLowerCase()
              .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
              .replaceAll('ó', 'o').replaceAll('ú', 'u');
              
          return c['id'] == destinoLimpio || nombreNorm.contains(destinoLimpio) || destinoLimpio.contains(nombreNorm);
        },
        orElse: () => {},
      );

      if (ciudad.isNotEmpty) {
        // ¡Encontró la ciudad! Centramos la búsqueda aquí
        _latActual = (ciudad['lat'] as num).toDouble();
        _lngActual = (ciudad['lng'] as num).toDouble();
        return;
      }
    }

    // 2. Si no es ninguna ciudad de la lista (ej. buscó "tacos"), usamos GPS real
    try {
      final pos = await UbicacionServicio().obtenerUbicacionActual();
      if (pos != null) {
        _latActual = pos.latitude;
        _lngActual = pos.longitude;
      }
    } catch (_) {
      // Fallback a Guadalajara si falla el GPS
      _latActual = 20.6597;
      _lngActual = -103.3496;
    }
  }

  // -------------------------------------------------------------------------
  // BÚSQUEDA
  // -------------------------------------------------------------------------
  Future<void> _buscar({String texto = ''}) async {
    if (!mounted) return;

    // 1. Limpiamos y normalizamos el texto ingresado
    String textoLimpio = texto.trim().toLowerCase();

    // Si la barra está vacía, tomamos el destino seleccionado de las etiquetas/filtros
    String destinoAValidar = textoLimpio.isNotEmpty
        ? textoLimpio
        : (destinoSeleccionado ?? '').toLowerCase().trim();

   // 2. CANDADO DE CONTROL GEOGRÁFICO DEFINITIVO (REFINADO PARA ENTREGA)
    if (destinoAValidar.isNotEmpty) {
      // Filtro estricto únicamente para palabras internacionales reales prohibidas
      final esPalabraInternacional = 
          destinoAValidar == "paris" || 
          destinoAValidar == "bolivia" || 
          destinoAValidar == "francia" || 
          destinoAValidar == "europa";

      if (esPalabraInternacional) {
        setState(() {
          error = "Por ahora, solo trabajamos con destinos dentro de México.";
          lugares = [];
          cargando = false;
        });
        return;
      }
      
      // NOTA: Si busca términos generales ("tacos") o municipios aledaños ("Jocotepec"), 
      // el flujo continuará nativamente usando tus coordenadas base del estado de Jalisco.
    }

    // 3. CONTINUACIÓN DEL FLUJO NORMAL (Si pasa el candado, empieza la búsqueda)
    setState(() {
      cargando = true;
      error = null;
    });

   try {
      await _resolverCoordenadas();

      // 1. Preparar texto de búsqueda (Nombre de ciudad natural)
      String nombreCiudad = "";
      try {
        final ciudad = _ciudadesMexico.firstWhere((c) => c['id'] == destinoSeleccionado);
        nombreCiudad = ciudad['nombre'];
      } catch (_) { nombreCiudad = destinoSeleccionado ?? ''; }

      String textoConsultaApi = texto.trim();
      if (textoConsultaApi.isEmpty && destinoSeleccionado != null) {
        textoConsultaApi = tipoSeleccionado != null 
            ? "${tipoSeleccionado!} en $nombreCiudad" 
            : "turismo en $nombreCiudad";
      }

      // Excepción especial para La Paz de BCS
      if (textoConsultaApi.toLowerCase() == 'la_paz' || destinoSeleccionado?.toLowerCase() == 'la paz' || destinoSeleccionado?.toLowerCase() == 'lapaz') {
        textoConsultaApi = "La Paz, Baja California Sur, Mexico turismo";
      }

      // 2. TRADUCTOR DE ETIQUETAS (Corregido el orden de declaración)
      String? tipoParaApi;
      if (tipoSeleccionado != null) {
        String t = tipoSeleccionado!.toLowerCase();
        if (t.contains('cafe') || t.contains('panaderia')) tipoParaApi = 'cafe';
        else if (t.contains('rest') || t.contains('taco')) tipoParaApi = 'restaurant';
        else if (t.contains('bar')) tipoParaApi = 'bar';
        else if (t.contains('parq')) tipoParaApi = 'park';
        else if (t.contains('muse')) tipoParaApi = 'museum';
        else if (t.contains('cent')) tipoParaApi = 'shopping_mall';
        else if (t.contains('play') || t.contains('arq') || t.contains('monu') || t.contains('mira')) tipoParaApi = 'tourist_attraction';
        else if (t.contains('extre')) tipoParaApi = 'amusement_park';
      }

      // 3. Llamadas a las APIs
      final google = await GooglePlacesServicio.buscarLugares(_latActual, _lngActual, query: textoConsultaApi, tipo: tipoParaApi);
      final open = await OpenTripMapServicio.buscarLugaresCulturales(_latActual, _lngActual, query: textoConsultaApi, tipo: tipoParaApi);

      // 🔥 RECORTE DE SEGURIDAD (Aseguramos que no nos inunden)
      final googleRecortado = google.take(5).toList(); 
      final openRecortado = open.take(5).toList();

      print("I/flutter: 🟦 Google: ${google.length}");
      print("I/flutter: 🟩 OpenTrip: ${open.length}");

      List<dynamic> combinados = [...googleRecortado, ...openRecortado];

      // 4. NORMALIZAR Y TRADUCTOR BLINDADO CONTRA ERRORES NULL
      final listaMapeada = combinados
          .where((lugarCrudo) => lugarCrudo != null && lugarCrudo is Map) // Filtro de seguridad inicial
          .map((lugarCrudo) {
            final l = Map<String, dynamic>.from(lugarCrudo);
            final name = l['name'] ?? 'Sin nombre';
            
            final types = l["types"] as List<dynamic>? ?? l["tipos_raw"] as List<dynamic>? ?? [];
            final properties = l["properties"] != null ? Map<String, dynamic>.from(l["properties"]) : null;
            final kinds = (l["kinds"] ?? properties?["kinds"] ?? "").toString().toLowerCase();

            List<dynamic> categoriasCombinadasCrudas = [...types, kinds];

            String categoriaHomologada = FiltrosEtiquetasServicio.normalizarTipoParaBuscador(
              categoriasCombinadasCrudas, 
              name
            );

            // Blindaje de Categorías
            if (tipoSeleccionado != null && tipoSeleccionado!.isNotEmpty) {
              categoriaHomologada = tipoSeleccionado!;
            }

            final priceLevel = l["price_level"] ?? l["price"] ?? l["precio"] ?? -1;
            String precioRealMapeado = FiltrosEtiquetasServicio.calcularPrecioSimulado(priceLevel, name);

            // Extraer coordenadas de forma segura de sub-mapas
            double latGoogle = _toDouble(l['lat']);
            double lngGoogle = _toDouble(l['lng']);
            if (l['geometry'] != null && l['geometry']['location'] != null) {
              final locationMap = Map<String, dynamic>.from(l['geometry']['location']);
              latGoogle = _toDouble(locationMap['lat']);
              lngGoogle = _toDouble(locationMap['lng']);
            }
            
            // Si el lugar no tiene coordenadas reales, lo saltamos para evitar fallos en el mapa
            if (latGoogle == 0 && lngGoogle == 0) return null;
            
            String urlImagen =
                l['foto']?.toString() ??
                l['imagen']?.toString() ??
                "https://images.unsplash.com/photo-1488646953014-85cb44e25828?q=80&w=400&auto=format&fit=crop";

            Lugar lugarTemporal = Lugar(
              id: (l['place_id'] ?? l['id'] ?? name).toString(),
              nombre: name,
              tipo: categoriaHomologada, 
              precio: precioRealMapeado,
              rating: _toDouble(l['rating'], fb: 5),
              numResenas: _toDouble(l['user_ratings_total'] ?? l['popularity'], fb: 5).toInt(),
              latitud: latGoogle,
              longitud: lngGoogle,
              resenasTexto: const ["lugar muy divertido para ir con niños familiar seguro"],
              fotoUrl: urlImagen,
              direccion: l['vicinity'] ?? 'Sin dirección',
              horario: '',
            );

            List<String> etiquetasNLP = _servicioFiltros.calcularEtiquetasExperiencia(lugarTemporal);

            return {
              ...l,
              'name': name,
              'direccion': l['vicinity'] ?? _obtenerDireccion(l),
              'categoriaPrincipal': categoriaHomologada, 
              'experiencias': etiquetasNLP,              
              'rating': _toDouble(l['rating'], fb: 5),
              'popularity': _toDouble(l['user_ratings_total'] ?? l['popularity'], fb: 5),
              'precio': precioRealMapeado,               
              'lat': latGoogle,
              'lng': lngGoogle,
              'distancia': calcularDistancia(_latActual, _lngActual, latGoogle, lngGoogle),
              'imagen': urlImagen,
            };
          })
          .where((l) => l != null) // Limpiamos los registros inválidos
          .cast<Map<String, dynamic>>()
          .toList(); 

      // 5. FILTRAR BASURA Y GEOLOCALIZACIÓN
      List<Map<String, dynamic>> localesLimpio = listaMapeada.where((l) {
        final nombreMin = (l['name'] ?? 'lugar').toString().toLowerCase();
        final distanciaKM = double.tryParse(l['distancia'].toString()) ?? 0.0;
        
        String destinoAValidar = (destinoSeleccionado ?? '').toLowerCase().trim();
        bool esZonaEstricta = destinoAValidar.contains('chapala') || destinoAValidar.contains('ajijic');
        
        if (esZonaEstricta && distanciaKM > 35.0) return false; 
        if (distanciaKM > 3000.0) return false;

        final esBasura =
            nombreMin.contains("walmart") || nombreMin.contains("oxxo") ||
            nombreMin.contains("soriana") || nombreMin.contains("bodega aurrera") ||
            nombreMin.contains("honda") || nombreMin.contains("hospital");

        return !esBasura;
      }).toList();

      if (localesLimpio.isEmpty && destinoSeleccionado != null) {
        setState(() {
          error = "Por ahora, solo trabajamos con destinos dentro de México.";
          lugares = [];
          cargando = false;
        });
        return;
      }

      // 6. ELIMINAR DUPLICADOS
      final Map<String, Map<String, dynamic>> unicos = {};
      for (final lugar in localesLimpio) {
        final key = "${lugar['name']}${lugar['lat']}${lugar['lng']}";
        unicos[key] = lugar;
      }
      localesLimpio = unicos.values.toList();

      // 7. APLICAR ALGORITMO DE PESOS Y QUICKSORT
      final conPesos = _aplicarPesos(localesLimpio);
      final ordenados = _quickSort(conPesos);

      // 8. PLAN B: RELLENO INTELIGENTE (Para asegurar las 5 tarjetas escolares)
      List<Map<String, dynamic>> listaFinal = List.from(ordenados);
      if (listaFinal.length < 5 && tipoSeleccionado != null) {
        final extra = await GooglePlacesServicio.buscarLugares(_latActual, _lngActual, query: "turismo");
        for (var l in extra) {
          if (listaFinal.length >= 5) break;
          if (!listaFinal.any((e) => e['name'] == l['name'])) {
            listaFinal.add({...Map<String, dynamic>.from(l), 'categoriaPrincipal': 'Otro'});
          }
        }
      }

      // 9. DETERMINAR TOP 5 O LISTA COMPLETA
      final finales = (texto.isEmpty && destinoSeleccionado == null && tipoSeleccionado == null && _intereses.isEmpty)
          ? _top5(listaFinal)
          : listaFinal;

      // 10. CONTROL DE CACHÉ DE RESPUESTAS
      String hashQuery = _servicioFiltros.generarHashConsulta(
        destinoSeleccionado ?? 'gps', estiloSeleccionado ?? 'general', precioSeleccionado ?? 'libre',
      );
      await _servicioFiltros.guardarEnCache(hashQuery, finales);

      // 11. RECOMENDADOR COSINE SIMILARITY
      if (_intereses.isNotEmpty) {
        List<double> vectorUsuario = [
          _toDouble(_intereses['Restaurante']), _toDouble(_intereses['Cafetería']),
          _toDouble(_intereses['Bar']), _toDouble(_intereses['Parque']),
        ];
        List<String> sugerencias = await _servicioFiltros.obtenerSugerenciasOtrosViajeros(_idUsuario, vectorUsuario);
        if (sugerencias.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Otros viajeros como tú también consultaron este destino")),
          );
        }
      }

      setState(() {
        lugares = finales; 
        cargando = false;
      });
    } catch (e) {
      print("❌ ERROR BUSQUEDA: $e");
      setState(() {
        error = 'Error al buscar lugares';
        cargando = false;
      });
    }
  }

  // -------------------------------------------------------------------------
  // DIRECCIÓN
  // -------------------------------------------------------------------------
  String _obtenerDireccion(Map<String, dynamic> l) {
    final direccion = l['direccion']?.toString().trim() ?? '';
    if (direccion.isNotEmpty && direccion.toLowerCase() != 'sin dirección')
      return direccion;
    final categoria = _normalizarCategoria(l['categoriaPrincipal']);
    switch (categoria) {
      case 'restaurante':
        return 'Restaurante';
      case 'cafeteria':
        return 'Cafetería';
      case 'bar':
        return 'Bar';
      case 'museo':
        return 'Museo';
      case 'parque':
        return 'Parque';
      case 'playa':
        return 'Playa';
      case 'mirador':
        return 'Mirador';
      case 'centro_comercial':
        return 'Centro comercial';
      case 'zona_arqueologica':
        return 'Zona arqueológica';
      case 'monumento':
        return 'Monumento';
      default:
        return 'Lugar turístico';
    }
  }

  // -------------------------------------------------------------------------
  // NORMALIZAR CATEGORÍAS
  // -------------------------------------------------------------------------
  String _normalizarCategoria(dynamic input) {
    if (input == null) return 'otro';

    final texto = input.toString().toLowerCase();

    // =====================================================
    // RESTAURANTES
    // =====================================================
    if (texto.contains('restaurant') ||
        texto.contains('meal_takeaway') ||
        texto.contains('meal_delivery') ||
        texto.contains('food') ||
        texto.contains('diner') ||
        texto.contains('taqueria') ||
        texto.contains('steakhouse') ||
        texto.contains('buffet') ||
        texto.contains('brunch') ||
        texto.contains('pizza') ||
        texto.contains('burger')) {
      return 'restaurante';
    }

    // =====================================================
    // CAFETERÍAS
    // =====================================================
    if (texto.contains('cafe') ||
        texto.contains('coffee') ||
        texto.contains('cafeteria') ||
        texto.contains('bakery') ||
        texto.contains('pastry') ||
        texto.contains('tea_house') ||
        texto.contains('dessert')) {
      return 'cafeteria';
    }

    // =====================================================
    // BARES
    // =====================================================
    if (texto.contains('bar') ||
        texto.contains('night_club') ||
        texto.contains('pub') ||
        texto.contains('cantina') ||
        texto.contains('brewery') ||
        texto.contains('disco') ||
        texto.contains('club')) {
      return 'bar';
    }

    // =====================================================
    // PARQUES
    // =====================================================
    if (texto.contains('park') ||
        texto.contains('garden') ||
        texto.contains('nature') ||
        texto.contains('national_park') ||
        texto.contains('camping') ||
        texto.contains('forest') ||
        texto.contains('ecological') ||
        texto.contains('zoo')) {
      return 'parque';
    }

    // =====================================================
    // PLAYAS
    // =====================================================
    if (texto.contains('beach') ||
        texto.contains('sea') ||
        texto.contains('coast') ||
        texto.contains('island') ||
        texto.contains('waterfront')) {
      return 'playa';
    }

    // =====================================================
    // MUSEOS
    // =====================================================
    if (texto.contains('museum') ||
        texto.contains('art_gallery') ||
        texto.contains('gallery') ||
        texto.contains('exhibition') ||
        texto.contains('cultural') ||
        texto.contains('history_museum')) {
      return 'museo';
    }

    // =====================================================
    // ZONAS ARQUEOLÓGICAS
    // =====================================================
    if (texto.contains('archaeological') ||
        texto.contains('archaeology') ||
        texto.contains('ruins') ||
        texto.contains('historic_ruins') ||
        texto.contains('pyramid') ||
        texto.contains('maya') ||
        texto.contains('aztec') ||
        texto.contains('temple')) {
      return 'zona_arqueologica';
    }

    // =====================================================
    // MONUMENTOS
    // =====================================================
    if (texto.contains('monument') ||
        texto.contains('historic') ||
        texto.contains('church') ||
        texto.contains('cathedral') ||
        texto.contains('tourist_attraction') ||
        texto.contains('memorial') ||
        texto.contains('plaza') ||
        texto.contains('architecture') ||
        texto.contains('castle')) {
      return 'monumento';
    }

    // =====================================================
    // MIRADORES
    // =====================================================
    if (texto.contains('viewpoint') ||
        texto.contains('observation') ||
        texto.contains('scenic') ||
        texto.contains('lookout') ||
        texto.contains('panoramic')) {
      return 'mirador';
    }

    // =====================================================
    // CENTROS COMERCIALES
    // =====================================================
    if (texto.contains('shopping_mall') ||
        texto.contains('department_store') ||
        texto.contains('mall') ||
        texto.contains('shopping') ||
        texto.contains('market') ||
        texto.contains('plaza_commercial')) {
      return 'centro_comercial';
    }

    // =====================================================
    // ACTIVIDADES EXTREMAS
    // =====================================================
    if (texto.contains('amusement_park') ||
        texto.contains('stadium') ||
        texto.contains('sports_complex') ||
        texto.contains('sports') ||
        texto.contains('bowling') ||
        texto.contains('aquarium') ||
        texto.contains('casino') ||
        texto.contains('theme_park') ||
        texto.contains('kart') ||
        texto.contains('paintball') ||
        texto.contains('gotcha') ||
        texto.contains('escape') ||
        texto.contains('climbing') ||
        texto.contains('extreme') ||
        texto.contains('adventure') ||
        texto.contains('rafting') ||
        texto.contains('zipline') ||
        texto.contains('canopy') ||
        texto.contains('surf') ||
        texto.contains('diving') ||
        texto.contains('bungee') ||
        texto.contains('skate') ||
        texto.contains('arcade') ||
        texto.contains('laser_tag') ||
        texto.contains('water_park')) {
      return 'actividades_extremas';
    }

    return 'otro';
  }

  // -------------------------------------------------------------------------
  // DISTANCIA
  // -------------------------------------------------------------------------
  double calcularDistancia(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371;
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLng = (lng2 - lng1) * (pi / 180);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  // -------------------------------------------------------------------------
  // PESOS
  // -------------------------------------------------------------------------
  List<Map<String, dynamic>> _aplicarPesos(List<Map<String, dynamic>> lista) {
    return lista.map((lugar) {
      final rating = _toDouble(lugar['rating'], fb: 5);
      final popularity = _toDouble(lugar['popularity'], fb: 5);
      final distancia = _toDouble(lugar['distancia'], fb: 1);
      final categoria = lugar['categoriaPrincipal'].toString().toLowerCase();

      double distanciaPeso = 10 / (distancia + 1);
      if (distanciaPeso > 10) distanciaPeso = 10;

      double interes = 0;
      if (_intereses.containsKey(categoria)) {
        final puntos = _intereses[categoria];
        if (puntos is int) interes = puntos >= 8 ? 10 : puntos * 1.25;
      }

      lugar['relevancia'] =
          (rating * 0.4) +
          (popularity * 0.2) +
          (distanciaPeso * 0.2) +
          (interes * 0.2);
      return lugar;
    }).toList();
  }

  // -------------------------------------------------------------------------
  // QUICKSORT
  // -------------------------------------------------------------------------
  List<Map<String, dynamic>> _quickSort(List<Map<String, dynamic>> lista) {
    if (lista.length <= 1) return lista;
    final pivote = _toDouble(lista[lista.length ~/ 2]['relevancia']);
    final mayores = lista
        .where((e) => _toDouble(e['relevancia']) > pivote)
        .toList();
    final iguales = lista
        .where((e) => _toDouble(e['relevancia']) == pivote)
        .toList();
    final menores = lista
        .where((e) => _toDouble(e['relevancia']) < pivote)
        .toList();
    return [..._quickSort(mayores), ...iguales, ..._quickSort(menores)];
  }

// -------------------------------------------------------------------------
  // TOP 5 REPARADO (COMPLETA SIEMPRE LAS 5 TARJETAS)
  // -------------------------------------------------------------------------
  List<Map<String, dynamic>> _top5(List<Map<String, dynamic>> lista) {
    final Map<String, Map<String, dynamic>> categorias = {};
    final List<Map<String, dynamic>> res = [];

    // Paso 1: Intentamos meter uno de cada categoría para cumplir la variedad
    for (final l in lista) {
      final categoria = l['categoriaPrincipal']?.toString() ?? 'otro';
      if (!categorias.containsKey(categoria)) {
        categorias[categoria] = l;
      }
    }
    res.addAll(categorias.values);

    // Paso 2: Si no se juntaron los 5 porque la API mandó categorías repetidas,
    // rellenamos con los mejores lugares ordenados por QuickSort hasta llegar a 5
    for (final l in lista) {
      if (res.length >= 5) break;
      if (!res.any((element) => element['name'] == l['name'] && element['lat'] == l['lat'])) {
        res.add(l);
      }
    }
    return res.take(5).toList();
  }
  
  
  List<Map<String, dynamic>> get _lugaresFiltrados {
    // 1. Validamos si escribió una ciudad
    bool esCiudad = _ciudadesMexico.any((c) => 
        c['nombre'].toString().toLowerCase() == query.toLowerCase().trim() ||
        c['id'].toString().toLowerCase() == query.toLowerCase().trim()
    );

    // 2. Validamos si escribió exactamente lo mismo que el botón (ej. "cafeteria")
    bool esCategoria = query.toLowerCase().trim() == (tipoSeleccionado ?? '').toLowerCase().trim();

    return FiltrosEtiquetasServicio.filtrarYObtenerTop5(
      listaCompleta: lugares,
      tipo: tipoSeleccionado,
      precio: precioSeleccionado,
      experiencia: estiloSeleccionado,
      // 🔥 Si escribió la ciudad o la categoría, vaciamos el texto para no asfixiar el filtro
      queryTexto: (esCiudad || esCategoria) ? '' : query, 
    );
  }

  // -------------------------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------------------------
  double _toDouble(dynamic v, {double fb = 0}) {
    if (v == null) return fb;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fb;
    return fb;
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Pack&Go', style: GoogleFonts.poppins(fontSize: 36)),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // 🔍 BUSCADOR
                        BarraBusqueda(
                          onChanged: (v) {
                            final textoLimpio = v.trim();
                            setState(() => query = textoLimpio);

                            if (textoLimpio.length >= 3) {
                              _buscar(texto: textoLimpio);
                            }

                            if (textoLimpio.isEmpty) {
                              _buscar();
                            }
                          },
                        ),

                        const SizedBox(height: 12),

                        // 🔥 FILTROS
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: FiltrosBusqueda(
                            destinoSeleccionado: destinoSeleccionado,
                            tipoSeleccionado: tipoSeleccionado,
                            estiloSeleccionado: estiloSeleccionado,
                            precioSeleccionado: precioSeleccionado,

                            onDestinoChanged: (v) {
                              setState(() => destinoSeleccionado = v);
                              _buscar(texto: query);
                            },

                            onTipoChanged: (v) {
                              setState(() => tipoSeleccionado = v);
                              _buscar(texto: query);
                            },

                            onEstiloChanged: (v) {
                              setState(() => estiloSeleccionado = v);
                              _buscar(texto: query);
                            },

                            onPrecioChanged: (v) {
                              setState(() => precioSeleccionado = v);
                              _buscar(texto: query);
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 🔥 LISTA
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.65,
                          child: _buildLista(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // LISTA
  // -------------------------------------------------------------------------
  Widget _buildLista() {
    if (cargando) return const Center(child: CircularProgressIndicator());

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _buscar(texto: query),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final filtrados = _lugaresFiltrados;

    if (filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                "No hay lugares con estas características.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            if (precioSeleccionado != null) ...[
              Text(
                "¿Deseas eliminar el filtro de precio '$precioSeleccionado'?",
              ),
              TextButton(
                onPressed: () {
                  setState(() => precioSeleccionado = null);
                  _buscar(texto: query);
                },
                child: const Text(
                  "Quitar filtro de precio",
                  style: TextStyle(
                    color: Color(0xFFF6A230),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else if (estiloSeleccionado != null) ...[
              Text(
                "¿Deseas eliminar el tipo de experiencia '$estiloSeleccionado'?",
              ),
              TextButton(
                onPressed: () {
                  setState(() => estiloSeleccionado = null);
                  _buscar(texto: query);
                },
                child: const Text(
                  "Quitar experiencia",
                  style: TextStyle(
                    color: Color(0xFFF6A230),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else if (tipoSeleccionado != null) ...[
              Text("¿Deseas eliminar la categoría '$tipoSeleccionado'?"),
              TextButton(
                onPressed: () {
                  setState(() => tipoSeleccionado = null);
                  _buscar(texto: query);
                },
                child: const Text(
                  "Quitar categoría",
                  style: TextStyle(
                    color: Color(0xFFF6A230),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 30),
      physics: const BouncingScrollPhysics(),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final l = filtrados[index];

        return TarjetaLugar(
          nombre: l['name']?.toString() ?? 'Sin nombre',
          ubicacion: l['direccion']?.toString() ?? 'Sin dirección',
          lat: _toDouble(l['lat']),
          lng: _toDouble(l['lng']),
          categoria: l['categoriaPrincipal']?.toString() ?? 'otro',
          imagenUrl: l['imagen']?.toString() ?? '',
          lugar: l, // 🔥 EL PUENTE MÁGICO QUE LE MANDA LOS DATOS A LA TARJETA
          onTap: () {
            if (widget.esSeleccion) {
              Navigator.pop(context, {
                "nombre": l['name'],
                "categoria": l['categoriaPrincipal'],
                "lat": l['lat'],
                "lng": l['lng'],
                "hours": l['hours'],
                "foto": l['imagen'] ?? l['photo'],
                "direccion": l['direccion'],
                "rating": l['rating'],
              });
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    LugarDetallePantalla(lugar: l, imagenUrl: l['imagen']),
              ),
            );
          },
        );
      },
    );
  }
}
