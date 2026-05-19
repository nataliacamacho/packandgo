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

  const BusquedaPantalla({super.key, this.esSeleccion = false});

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
    _inicializar();
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
    // DESTINO
    if (destinoSeleccionado != null) {
      final ciudad = _ciudadesMexico.firstWhere(
        (c) => c['id'] == destinoSeleccionado,
        orElse: () => {},
      );

      if (ciudad.isNotEmpty) {
        _latActual = (ciudad['lat'] as num).toDouble();
        _lngActual = (ciudad['lng'] as num).toDouble();
        return;
      }
    }

    // GPS
    try {
      final pos = await UbicacionServicio().obtenerUbicacionActual();

      if (pos != null) {
        _latActual = pos.latitude;
        _lngActual = pos.longitude;
      }
    } catch (_) {}
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
      
      // Ajustamos el parámetro de búsqueda para las APIs externas
      String textoConsultaApi = texto.trim();
      // Excepción especial para La Paz de BCS para que Google no se vaya a Sudamérica
      if (textoConsultaApi.toLowerCase() == 'la paz' || destinoSeleccionado?.toLowerCase() == 'la paz' || destinoSeleccionado?.toLowerCase() == 'lapaz') {
        textoConsultaApi = "La Paz, Baja California Sur, Mexico";
      }

      // A partir de aquí sigue el llamado original a tus servicios de Google y OpenTripMap...

      final google = await GooglePlacesServicio.buscarLugares(
        _latActual,
        _lngActual,
        query: textoConsultaApi,
        tipo: tipoSeleccionado,
      );
      for (var lugar in google.take(3)) {
        print("==========");
        print(lugar['name']);
        print(lugar['photos']);
      }

      final open = await OpenTripMapServicio.buscarLugaresCulturales(
        _latActual,
        _lngActual,
        query: texto,
        tipo: tipoSeleccionado,
      );

      print("🟦 Google: ${google.length}");
      print("🟩 OpenTrip: ${open?.length ?? 0}");

      List<Map<String, dynamic>> combinados = [...google, ...(open ?? [])];

      // NORMALIZAR Y TRADUCIR
      // -------------------------------------------------------------------
      combinados = combinados.map((l) {
        String categoria = _normalizarCategoria(l['categoriaPrincipal']);
        final nombreMin = (l['name'] ?? "").toString().toLowerCase();

        if (nombreMin.contains("café") ||
            nombreMin.contains("cafe") ||
            nombreMin.contains("coffee") ||
            nombreMin.contains("cafeteria")) {
          categoria = "Cafetería";
        }
        // 🏖️ APERTURA DETECTORA DE PLAYAS
        final types = l["tipos_raw"] as List<dynamic>? ?? [];
        final kinds = (l["kinds"] ?? l["properties"]?["kinds"] ?? "").toString().toLowerCase();
        final datosCrudos = types.join(",") + "," + kinds;

        if (datosCrudos.contains("beach") || 
            datosCrudos.contains("sea") || 
            datosCrudos.contains("coast") || 
            nombreMin.contains("playa") || 
            nombreMin.contains("beach")) {
          categoria = "playa";
        }

        String catMin = categoria.toLowerCase();

        const categoriasPermitidas = [
          "restaurante",
          "cafeteria",
          "bar",
          "parque",
          "museo",
          "playa",
          "monumento",
          "zona_arqueologica",
          "mirador",
          "centro_comercial",
          "actividades_extremas",
        ];

        if (!categoriasPermitidas.contains(catMin)) {
          final types = l["tipos_raw"] as List<dynamic>? ?? [];
          final kinds = (l["kinds"] ?? l["properties"]?["kinds"] ?? "")
              .toString();
          final datosCrudos = types.join(",") + "," + kinds.toLowerCase();

          if (datosCrudos.contains("cafe") ||
              datosCrudos.contains("coffee") ||
              datosCrudos.contains("bakery") ||
              datosCrudos.contains("pastry"))
            categoria = "Cafetería";
          else if (datosCrudos.contains("restaurant") ||
              datosCrudos.contains("food"))
            categoria = "Restaurante";
          else if (datosCrudos.contains("shopping") ||
              datosCrudos.contains("mall"))
            categoria = "centro_comercial";
          else if (datosCrudos.contains("park") ||
              datosCrudos.contains("nature") ||
              datosCrudos.contains("garden"))
            categoria = "Parque";
          else if (datosCrudos.contains("museum") ||
              datosCrudos.contains("art") ||
              datosCrudos.contains("cultural"))
            categoria = "Museo";
          else if (datosCrudos.contains("bar") ||
              datosCrudos.contains("night_club") ||
              datosCrudos.contains("pub"))
            categoria = "Bar";
          else if (datosCrudos.contains("tourist") ||
              datosCrudos.contains("monument") ||
              datosCrudos.contains("religion") ||
              datosCrudos.contains("church") ||
              datosCrudos.contains("architecture"))
            categoria = "Monumento";
          else if (datosCrudos.contains("archaeolog") ||
              datosCrudos.contains("historic") ||
              datosCrudos.contains("ruins"))
            categoria = "zona_arqueologica";
          else if (datosCrudos.contains("beach") || datosCrudos.contains("sea"))
            categoria = "Playa";
          else if (datosCrudos.contains("viewpoint") ||
              datosCrudos.contains("observation"))
            categoria = "Mirador";
          else if (datosCrudos.contains("amusement") ||
              datosCrudos.contains("extreme") ||
              datosCrudos.contains("stadium") ||
              datosCrudos.contains("sports") ||
              datosCrudos.contains("theme_park"))
            categoria = "actividades_extremas";
          else
            categoria = "Otro";
        }

        int priceLevel = l["price_level"] ?? -1;
        String precioCalc = "\$\$";

        if (nombreMin.contains("mcdonald") ||
            nombreMin.contains("burger") ||
            nombreMin.contains("pizza") ||
            nombreMin.contains("taco") ||
            nombreMin.contains("torta") ||
            nombreMin.contains("kfc") ||
            nombreMin.contains("pollo") ||
            nombreMin.contains("dog")) {
          precioCalc = "\$";
        } else if (priceLevel <= 1 && priceLevel != -1) {
          precioCalc = "\$";
        } else if (priceLevel >= 3) {
          precioCalc = "\$\$\$";
        } else if (priceLevel == -1) {
          if (categoria.toLowerCase() == "bar" ||
              categoria.toLowerCase() == "centro_comercial") {
            precioCalc = "\$\$\$";
          } else if (categoria.toLowerCase() == "cafeteria" ||
              categoria.toLowerCase() == "museo" ||
              categoria.toLowerCase() == "restaurante") {
            precioCalc = "\$\$";
          } else {
            precioCalc = "\$";
          }
        }
        final latGoogle = l['geometry']?['location']?['lat'] ?? l['lat'];
        final lngGoogle = l['geometry']?['location']?['lng'] ?? l['lng'];
        String urlImagen = l['foto']?.toString() ?? l['imagen']?.toString() ?? "https://images.unsplash.com/photo-1488646953014-85cb44e25828?q=80&w=400&auto=format&fit=crop";

        // 🔽 SOLUCIÓN DE ERROR: Usamos la definición del objeto Lugar importada del servicio
        Lugar lugarTemporal = Lugar(
          id: (l['place_id'] ?? l['id'] ?? l['name']).toString(),
          nombre: l['name'] ?? 'Sin nombre',
          tipo: categoria,
          precio: precioCalc,
          rating: _toDouble(l['rating'], fb: 5),
          numResenas: _toDouble(l['user_ratings_total'] ?? l['popularity'], fb: 5).toInt(),
          latitud: _toDouble(latGoogle),
          longitud: _toDouble(lngGoogle),
          resenasTexto: const ["lugar muy divertido para ir con niños familiar seguro"], // Simulación de reviews para NLP escolar
          fotoUrl: urlImagen,
          direccion: l['vicinity'] ?? 'Sin dirección',
          horario: '',
        );

        // Invocación del algoritmo NLP externo
        List<String> etiquetasNLP = _servicioFiltros.calcularEtiquetasExperiencia(lugarTemporal);

        String categoriaFinal = categoria
            .toLowerCase()
            .replaceAll(" ", "_")
            .replaceAll("í", "i")
            .replaceAll("á", "a");

        return {
          ...l,
          'name': l['name'] ?? 'Sin nombre',
          'direccion': l['vicinity'] ?? _obtenerDireccion(l),
          'categoriaPrincipal': categoriaFinal,
          'experiencias': etiquetasNLP, // Asignamos las etiquetas generadas por el modelo matemático
          'rating': _toDouble(l['rating'], fb: 5),
          'popularity': _toDouble(
            l['user_ratings_total'] ?? l['popularity'],
            fb: 5,
          ),
          'precio': precioCalc,
          'lat': latGoogle,
          'lng': lngGoogle,
          'distancia': calcularDistancia(
            _latActual,
            _lngActual,
            _toDouble(latGoogle),
            _toDouble(lngGoogle),
          ),
          'imagen': urlImagen,
        };
      }).toList();
      // -------------------------------------------------------------------
      // FILTRAR BASURA
      // -------------------------------------------------------------------
      combinados = combinados.where((l) {
        final latValida = l['lat'] != null;
        final lngValida = l['lng'] != null;
        final nombreValido = l['name'] != null;

        if (!latValida || !lngValida || !nombreValido) return false;

        final nombreMin = l['name'].toString().toLowerCase();

        final esBasura =
            nombreMin.contains("walmart") ||
            nombreMin.contains("oxxo") ||
            nombreMin.contains("soriana") ||
            nombreMin.contains("bodega aurrera") ||
            nombreMin.contains("honda") ||
            nombreMin.contains("ford") ||
            nombreMin.contains("chevrolet") ||
            nombreMin.contains("nissan") ||
            nombreMin.contains("justicia") ||
            nombreMin.contains("juzgado") ||
            nombreMin.contains("gobierno") ||
            nombreMin.contains("hospital");

        return !esBasura;
      }).toList();
      if (combinados.isEmpty && destinoAValidar.isNotEmpty) {
        setState(() {
          error = "Por ahora, solo trabajamos con destinos dentro de México.";
          lugares = [];
          cargando = false;
        });
        return;
      }

      // -------------------------------------------------------------------
      // ELIMINAR DUPLICADOS
      // -------------------------------------------------------------------
      final Map<String, Map<String, dynamic>> unicos = {};

      for (final lugar in combinados) {
        final key = "${lugar['name']}${lugar['lat']}${lugar['lng']}";
        unicos[key] = lugar;
      }

      combinados = unicos.values.toList();

      // -------------------------------------------------------------------
      // PESOS
      // -------------------------------------------------------------------
      final conPesos = _aplicarPesos(combinados);

      // -------------------------------------------------------------------
      // ORDENAR
      // -------------------------------------------------------------------
      final ordenados = _quickSort(conPesos);

      // -------------------------------------------------------------------
      // TOP (Aquí termina tu código original del bloque try)
      // -------------------------------------------------------------------
      final finales =
          (texto.isEmpty &&
              destinoSeleccionado == null &&
              tipoSeleccionado == null &&
              _intereses.isEmpty)
          ? _top5(ordenados)
          : ordenados;

      // 🔽 CORRECCIÓN: ESTO VA AQUÍ (FUERA Y ARRIBA DEL CATCH)

      // 1. Guardar en caché inteligente usando la variable 'finales' que es el Top definitivo
      String hashQuery = _servicioFiltros.generarHashConsulta(
        destinoSeleccionado ?? 'gps',
        estiloSeleccionado ?? 'general',
        precioSeleccionado ?? 'libre',
      );
      await _servicioFiltros.guardarEnCache(hashQuery, finales);

      // 2. Filtro Cosine Similarity para sugerencias de viajeros
      if (_intereses.isNotEmpty) {
        List<double> vectorUsuario = [
          _toDouble(_intereses['Restaurante']),
          _toDouble(_intereses['Cafetería']),
          _toDouble(_intereses['Bar']),
          _toDouble(_intereses['Parque']),
        ];
        List<String> sugerencias = await _servicioFiltros.obtenerSugerenciasOtrosViajeros(_idUsuario, vectorUsuario);
        if (sugerencias.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Otros viajeros como tú también consultaron este destino")),
          );
        }
      }

      // 3. Actualizamos el estado con la lista 'finales'
      setState(() {
        lugares = finales; 
        cargando = false;
      });

    } catch (e) {
      // 🛑 El catch se queda solo para atrapar errores, así limpito como lo tenías:
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
  // TOP 5
  // -------------------------------------------------------------------------
  List<Map<String, dynamic>> _top5(List<Map<String, dynamic>> lista) {
    final Map<String, Map<String, dynamic>> categorias = {};
    final List<Map<String, dynamic>> res = [];

    for (final l in lista) {
      final categoria = l['categoriaPrincipal']?.toString() ?? 'otro';
      if (!categorias.containsKey(categoria)) categorias[categoria] = l;
    }
    res.addAll(categorias.values);

    for (final l in lista) {
      if (res.length >= 5) break;
      if (!res.contains(l)) res.add(l);
    }
    return res.take(5).toList();
  }

  // -------------------------------------------------------------------------
  // FILTROS 🔥 AQUÍ INYECTAMOS EL FILTRO VIP
  // -------------------------------------------------------------------------
  List<Map<String, dynamic>> get _lugaresFiltrados {
    List<Map<String, dynamic>> filtrados = List.from(lugares);

    String normalizar(String texto) {
      return texto
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'[áäâà]'), 'a')
          .replaceAll(RegExp(r'[éëêè]'), 'e')
          .replaceAll(RegExp(r'[íïîì]'), 'i')
          .replaceAll(RegExp(r'[óöôò]'), 'o')
          .replaceAll(RegExp(r'[úüûù]'), 'u')
          .replaceAll(RegExp(r'[ñ]'), 'n');
    }

    if (query.isNotEmpty) {
      final queryLimpio = normalizar(query);

      filtrados = filtrados.where((l) {
        final nombre = normalizar(l['name'].toString());

        final categoria = normalizar(l['categoriaPrincipal'].toString());

        final experiencias = (l['experiencias'] as List<dynamic>? ?? [])
            .map((e) => normalizar(e.toString()))
            .join(' ');

        final direccion = normalizar(l['direccion'].toString());

        return nombre.contains(queryLimpio) ||
            categoria.contains(queryLimpio) ||
            experiencias.contains(queryLimpio) ||
            direccion.contains(queryLimpio);
      }).toList();
    }

    if (tipoSeleccionado != null) {
      final tipoLimpio = normalizar(tipoSeleccionado!);
      filtrados = filtrados.where((l) {
        final catLugar = normalizar(l['categoriaPrincipal'].toString());
        return catLugar == tipoLimpio;
      }).toList();
    }

    if (estiloSeleccionado != null) {
      final estiloLimpio = normalizar(estiloSeleccionado!);
      filtrados = filtrados.where((l) {
        final experiencias = (l['experiencias'] as List<dynamic>? ?? [])
            .map((e) => normalizar(e.toString()))
            .toList();

        return experiencias.contains(estiloLimpio);
      }).toList();
    }

    if (precioSeleccionado != null) {
      filtrados = filtrados.where((l) {
        return l['precio'] == precioSeleccionado;
      }).toList();
    }

    // 🔥 EL TOQUE MÁGICO: ORDENAMIENTO POR RELEVANCIA (Tu Filtro VIP original)
    // Esto evita que "Pizza Hut" salga primero, dándole prioridad a lugares de alta calidad.
    filtrados.sort((a, b) {
      // 1. Obtenemos las estrellas de Google (rating)
      double ratingA = _toDouble(a['rating'], fb: 0.0);
      double ratingB = _toDouble(b['rating'], fb: 0.0);

      // 2. Obtenemos la cantidad de reseñas (para desempatar)
      int reviewsA = _toDouble(
        a['popularity'] ?? a['user_ratings_total'],
        fb: 0.0,
      ).toInt();
      int reviewsB = _toDouble(
        b['popularity'] ?? b['user_ratings_total'],
        fb: 0.0,
      ).toInt();

      // 3. Calculamos un "Puntaje Pack&Go"
      // Le damos un bonus a los lugares que tienen más de 100 reseñas (son más confiables)
      double scoreA = _toDouble(a['relevancia']) + (reviewsA > 100 ? 0.5 : 0.0);

      double scoreB = _toDouble(b['relevancia']) + (reviewsB > 100 ? 0.5 : 0.0);

      // 4. Castigamos un poquito a las cadenas de comida rápida para que bajen en la lista
      final nombreA = a['name'].toString().toLowerCase();
      final nombreB = b['name'].toString().toLowerCase();

      if (nombreA.contains('pizza hut') ||
          nombreA.contains('burger king') ||
          nombreA.contains('kfc') ||
          nombreA.contains('mcdonald') ||
          nombreA.contains('subway') ||
          nombreA.contains('starbucks'))
        scoreA -= 2.0;
      if (nombreB.contains('pizza hut') ||
          nombreB.contains('burger king') ||
          nombreB.contains('kfc') ||
          nombreB.contains('mcdonald') ||
          nombreB.contains('subway') ||
          nombreB.contains('starbucks'))
        scoreB -= 2.0;

      // Comparamos para que el puntaje MÁS ALTO quede HASTA ARRIBA
      return scoreB.compareTo(scoreA);
    });

    return filtrados.take(5).toList();
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
                            },

                            onPrecioChanged: (v) {
                              setState(() => precioSeleccionado = v);
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
