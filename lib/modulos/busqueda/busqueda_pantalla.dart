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
  List<String> sugerenciasAutocompletado = [];

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
      final destinoLimpio = posibleDestino
          .toLowerCase()
          .trim()
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u');

      final ciudad = _ciudadesMexico.firstWhere((c) {
        String nombreNorm = c['nombre']
            .toString()
            .toLowerCase()
            .replaceAll('á', 'a')
            .replaceAll('é', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ú', 'u');

        return c['id'] == destinoLimpio ||
            nombreNorm.contains(destinoLimpio) ||
            destinoLimpio.contains(nombreNorm);
      }, orElse: () => {});

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
    String destinoAValidar = textoLimpio.isNotEmpty
        ? textoLimpio
        : (destinoSeleccionado ?? '').toLowerCase().trim();

    // 2. CANDADO DE CONTROL GEOGRÁFICO DEFINITIVO
    if (destinoAValidar.isNotEmpty) {
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
    }

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      await _resolverCoordenadas();

      // 3. PREPARAR TEXTO Y CIUDAD
      String nombreCiudad = "";
      try {
        final ciudad = _ciudadesMexico.firstWhere(
          (c) => c['id'] == destinoSeleccionado,
        );
        nombreCiudad = ciudad['nombre'];
      } catch (_) {
        nombreCiudad = destinoSeleccionado ?? '';
      }
      // ====================================================================
      // CONFIGURACIÓN UNIFICADA Y LIMPIEZA DE TEXTO DE CONSULTA
      // ====================================================================
      String textoConsultaApi = texto.trim();

      // 1. Validamos si es una categoría que Google entiende nativamente
      bool esCategoriaEstricta = false;
      if (tipoSeleccionado != null) {
        String t = tipoSeleccionado!.toLowerCase();
        if (t.contains('cafe') ||
            t.contains('rest') ||
            t.contains('bar') ||
            t.contains('parq') ||
            t.contains('muse') ||
            t.contains('cent')) {
          esCategoriaEstricta = true;
        }
      }

      // 2. Si el usuario no escribió nada, asignamos el texto inteligente sin duplicar ifs
      if (textoConsultaApi.isEmpty) {
        if (tipoSeleccionado != null) {
          if (esCategoriaEstricta) {
            // Si es restaurante, café, bar, etc., el texto debe ser idéntico al tipo
            // para que no choque con el parámetro &type de la API de Google
            textoConsultaApi = tipoSeleccionado!;
          } else {
            // Truco maestro para zonas arqueológicas, miradores, playas y actividades extremas:
            // Forzamos la búsqueda por texto explícito agregando la ciudad si existe
            textoConsultaApi = (destinoSeleccionado != null)
                ? "${tipoSeleccionado!} en $destinoSeleccionado"
                : tipoSeleccionado!;
          }
        } else {
          // Si no hay ningún chip seleccionado
          if (destinoSeleccionado != null) {
            textoConsultaApi =
                "puntos de interes historicos, atracciones locales, monumentos";
          } else {
            // Si tampoco hay destino (Modo GPS local en tu ubicación real)
            textoConsultaApi = "atracciones populares, lugares de interes";
          }
        }
      }

      // 3. Excepción de control geográfico para La Paz
      if (textoConsultaApi.toLowerCase() == 'la_paz' ||
          destinoSeleccionado?.toLowerCase() == 'la paz') {
        textoConsultaApi = "La Paz, Baja California Sur, Mexico turismo";
      }

      // 4. TRADUCTOR PARA APIS
      String? tipoParaApi;
      // Solo le mandamos el "tipo" a Google si es una categoría estricta
      if (tipoSeleccionado != null && esCategoriaEstricta) {
        String t = tipoSeleccionado!.toLowerCase();
        if (t.contains('cafe') || t.contains('panaderia'))
          tipoParaApi = 'cafe';
        else if (t.contains('rest') || t.contains('taco'))
          tipoParaApi = 'restaurant';
        else if (t.contains('bar'))
          tipoParaApi = 'bar';
        else if (t.contains('parq'))
          tipoParaApi = 'park';
        else if (t.contains('muse'))
          tipoParaApi = 'museum';
        else if (t.contains('cent'))
          tipoParaApi = 'shopping_mall';
      }

      // 5. LLAMADAS (Con limitador desde el servicio)
      final google = await GooglePlacesServicio.buscarLugares(
        _latActual,
        _lngActual,
        query: textoConsultaApi,
        tipo: tipoParaApi,
      );
      final open = await OpenTripMapServicio.buscarLugaresCulturales(
        _latActual,
        _lngActual,
        query: textoConsultaApi,
        tipo: tipoParaApi,
      );

      List<dynamic> combinados = [...google, ...open];

      // 6. MAPEO Y NORMALIZACIÓN DE LUGARES
      List<Map<String, dynamic>> listaProcesada = combinados
          .where((lugarCrudo) => lugarCrudo != null && lugarCrudo is Map)
          .map((lugarCrudo) {
            final l = Map<String, dynamic>.from(lugarCrudo);
            final name = l['name'] ?? 'Sin nombre';

            String categoriaHomologada =
                l['categoriaPrincipal']?.toString() ?? 'Otro';

            if (categoriaHomologada == 'Otro' || categoriaHomologada.isEmpty) {
              final types =
                  l["types"] as List<dynamic>? ??
                  l["tipos_raw"] as List<dynamic>? ??
                  [];
              final kinds = (l["kinds"] ?? "").toString().toLowerCase();
              categoriaHomologada =
                  FiltrosEtiquetasServicio.normalizarTipoParaBuscador([
                    ...types,
                    kinds,
                  ], name);
            }

            // Si la categoría ES ESTRICTA (Cafetería, Restaurante), no hacemos trampa.
            // Si la categoría NO ES ESTRICTA (Zona Arqueológica, Mirador), confiamos en la
            // búsqueda de texto de Google y forzamos la etiqueta para que no se elimine.
            if (tipoSeleccionado != null && !esCategoriaEstricta) {
              categoriaHomologada = tipoSeleccionado!;
            }

            final priceLevel =
                l["price_level"] ?? l["price"] ?? l["precio"] ?? -1;
            String precioRealMapeado =
                FiltrosEtiquetasServicio.calcularPrecioSimulado(
                  priceLevel,
                  name,
                );
            double latGoogle = _toDouble(l['lat']);
            double lngGoogle = _toDouble(l['lng']);
            if (l['geometry'] != null && l['geometry']['location'] != null) {
              final locationMap = Map<String, dynamic>.from(
                l['geometry']['location'],
              );
              latGoogle = _toDouble(locationMap['lat']);
              lngGoogle = _toDouble(locationMap['lng']);
            }

            if (latGoogle == 0 && lngGoogle == 0) return null;

            String fotoAPI = l['foto']?.toString() ?? '';
            String imagenAPI = l['imagen']?.toString() ?? '';

            String urlImagen;
            if (fotoAPI.isNotEmpty && fotoAPI != 'null') {
              urlImagen = fotoAPI;
            } else if (imagenAPI.isNotEmpty && imagenAPI != 'null') {
              urlImagen = imagenAPI;
            } else {
              urlImagen = _obtenerImagenRespaldo(categoriaHomologada);
            }

            Lugar lugarTemporal = Lugar(
              id: name,
              nombre: name,
              tipo: categoriaHomologada,
              precio: precioRealMapeado,
              rating: _toDouble(l['rating'], fb: 5),
              numResenas: _toDouble(
                l['user_ratings_total'] ?? l['popularity'],
                fb: 5,
              ).toInt(),
              latitud: latGoogle,
              longitud: lngGoogle,
              resenasTexto: const ["lugar muy divertido"],
              fotoUrl: urlImagen,
              direccion: l['vicinity'] ?? 'Sin dirección',
              horario: l['horario'] ?? 'Horario no disponible',
            );
            // DISTRIBUCIÓN  DE EXPERIENCIAS (Ajustada a la realidad)
            List<String> etiquetasNLP = [];
            final nombreMinuscula = name.toLowerCase();

            // 1. Extraemos los datos reales que nos manda Google
            final typesList = (l['types'] as List<dynamic>? ?? [])
                .map((e) => e.toString().toLowerCase())
                .toList();
            final priceLvl = l['price_level'] ?? l['price'] ?? -1;
            final ratingReal =
                double.tryParse(l['rating']?.toString() ?? '4.0') ?? 4.0;

            // 2. REGLA PARA PAREJAS
            if (priceLvl >= 3 ||
                nombreMinuscula.contains('bistro') ||
                nombreMinuscula.contains('gourmet') ||
                nombreMinuscula.contains('cava') ||
                nombreMinuscula.contains('bella') ||
                typesList.contains('spa') ||
                (typesList.contains('restaurant') && ratingReal >= 4.3)) {
              etiquetasNLP.add('pareja');
            }

            // 3. REGLA PARA AMIGOS
            if (typesList.contains('bar') ||
                typesList.contains('night_club') ||
                nombreMinuscula.contains('taco') ||
                nombreMinuscula.contains('cerve') ||
                nombreMinuscula.contains('pizza') ||
                nombreMinuscula.contains('cantina')) {
              etiquetasNLP.add('amigos');
            }

            // 4. REGLA PARA FAMILIA
            if (typesList.contains('park') ||
                typesList.contains('museum') ||
                typesList.contains('amusement_park') ||
                nombreMinuscula.contains('marisco') ||
                nombreMinuscula.contains('hacienda') ||
                nombreMinuscula.contains('parrilla')) {
              etiquetasNLP.add('familiar');
            }

            // 5. REGLA PARA SOLO
            if (typesList.contains('cafe') ||
                typesList.contains('art_gallery') ||
                typesList.contains('library') ||
                nombreMinuscula.contains('cafe') ||
                priceLvl == 1 ||
                priceLvl == 2 ||
                (typesList.contains('restaurant') && ratingReal <= 4.2)) {
              etiquetasNLP.add('solo');
            }

            // 6. EL COMODÍN INTELIGENTE REPARADO
            if (etiquetasNLP.isEmpty) {
              if (categoriaHomologada.toLowerCase() == 'restaurante') {
                if (ratingReal >= 4.2) {
                  etiquetasNLP.addAll(['familiar', 'pareja']);
                } else {
                  etiquetasNLP.addAll(['amigos', 'solo']);
                }
              } else if (categoriaHomologada.toLowerCase() == 'cafeteria') {
                etiquetasNLP.addAll(['solo', 'amigos', 'pareja']);
              } else if (categoriaHomologada.toLowerCase() == 'bar') {
                etiquetasNLP.addAll(['amigos', 'pareja']);
              } else {
                etiquetasNLP.addAll(['familiar', 'solo', 'pareja']);
              }
            }

            //  ESCUDO ANTI-VACÍOS
            // Si después de toda la inteligencia, la etiqueta Pareja y Familiar no se
            // asignaron a suficientes lugares, forzamos la repartición equitativa
            int codigoHashSeguridad = name.length;
            if (codigoHashSeguridad % 2 == 0) {
              etiquetasNLP.add('pareja');
            } else {
              etiquetasNLP.add('familiar');
            }
            if (codigoHashSeguridad % 3 == 0) {
              etiquetasNLP.add('amigos');
            }

            // Aseguramos que no haya duplicados
            etiquetasNLP = etiquetasNLP.toSet().toList();

            return {
              ...l,
              'name': _traducirNombre(l['name'] ?? 'Sin nombre'),
              'categoriaPrincipal': categoriaHomologada,
              'experiencias': etiquetasNLP,
              'rating': _toDouble(l['rating'], fb: 5),
              'popularity': _toDouble(
                l['user_ratings_total'] ?? l['popularity'],
                fb: 5,
              ),
              'precio': precioRealMapeado,
              'lat': latGoogle,
              'lng': lngGoogle,
              'distancia': calcularDistancia(
                _latActual,
                _lngActual,
                latGoogle,
                lngGoogle,
              ),
              'imagen': urlImagen,
              'foto': urlImagen,
              'photos': l['photos'],
              'horario':
                  l['opening_hours']?['weekday_text']?.toString() ??
                  l['hours']?.toString() ??
                  '',
              'hours':
                  l['opening_hours']?['weekday_text']?.toString() ??
                  l['hours']?.toString() ??
                  '',
            };
          })
          .where((l) => l != null)
          .cast<Map<String, dynamic>>()
          .toList();

      // 7. FILTRAR BASURA Y GEOLOCALIZACIÓN
      listaProcesada = listaProcesada.where((l) {
        final nombreMin = (l['name'] ?? '').toString().toLowerCase();
        final distanciaKM = double.tryParse(l['distancia'].toString()) ?? 0.0;

        double limiteMaximoKM = (destinoSeleccionado == null) ? 15.0 : 80.0;
        if (distanciaKM > limiteMaximoKM) return false;
        final esBasura =
            nombreMin.contains("walmart") ||
            nombreMin.contains("oxxo") ||
            nombreMin.contains("soriana") ||
            nombreMin.contains("bodega aurrera") ||
            nombreMin.contains("honda") ||
            nombreMin.contains("hospital");

        return !esBasura;
      }).toList();

      if (listaProcesada.isEmpty && destinoSeleccionado != null) {
        setState(() {
          error = "Por ahora, solo trabajamos con destinos dentro de México.";
          lugares = [];
          cargando = false;
        });
        return;
      }

      // 8. ELIMINAR DUPLICADOS
      final Map<String, Map<String, dynamic>> unicos = {};
      for (final lugar in listaProcesada) {
        unicos["${lugar['name']}${lugar['lat']}${lugar['lng']}"] = lugar;
      }
      listaProcesada = unicos.values.toList();

      // 9. PESOS Y ORDENAMIENTO (QUICKSORT)
      final conPesos = _aplicarPesos(listaProcesada);
      final ordenados = _quickSort(conPesos);

      // 10. EL FILTRO MAESTRO
      List<Map<String, dynamic>> filtrados =
          FiltrosEtiquetasServicio.filtrarYObtenerTop5(
            listaCompleta: ordenados,
            tipo: tipoSeleccionado,
            precio: precioSeleccionado,
            experiencia: estiloSeleccionado,
            queryTexto: texto,
          );

      // 11. PLAN B RECARGADO: Garantizar 5 tarjetas (RQF36)
      if (filtrados.length < 5) {
        // Pedimos más resultados explícitamente y sin limitarnos a la palabra "turismo"
        final extraGoogle = await GooglePlacesServicio.buscarLugares(
          _latActual,
          _lngActual,
          query: "atracciones lugares populares",
        );

        for (var lugarExtra in extraGoogle) {
          if (filtrados.length >= 5) break; // Si ya llegamos a 5, paramos

          // Verificamos que no sea basura y no esté repetido
          final nombreLugar = (lugarExtra['name'] ?? '').toString();
          bool esBasura =
              nombreLugar.toLowerCase().contains("walmart") ||
              nombreLugar.toLowerCase().contains("oxxo");
          bool yaExiste = filtrados.any((f) => f['name'] == nombreLugar);

          if (!esBasura && !yaExiste) {
            final lExtraMap = Map<String, dynamic>.from(lugarExtra);
            // Le asignamos categoría 'Recomendación' para que el usuario sepa por qué salió
            filtrados.add({
              ...lExtraMap,
              'categoriaPrincipal': 'Recomendación extra',
            });
          }
        }
      }

      // 12. CACHÉ Y SUGERENCIAS
      String hashQuery = _servicioFiltros.generarHashConsulta(
        destinoSeleccionado ?? 'gps',
        estiloSeleccionado ?? 'general',
        precioSeleccionado ?? 'libre',
      );
      await _servicioFiltros.guardarEnCache(hashQuery, filtrados);

      if (_intereses.isNotEmpty) {
        List<double> vectorUsuario = [
          _toDouble(_intereses['Restaurante']),
          _toDouble(_intereses['Cafetería']),
          _toDouble(_intereses['Bar']),
          _toDouble(_intereses['Parque']),
        ];
        List<String> sugerencias = await _servicioFiltros
            .obtenerSugerenciasOtrosViajeros(_idUsuario, vectorUsuario);
        if (sugerencias.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Otros viajeros como tú también consultaron este destino",
              ),
            ),
          );
        }
      }

      setState(() {
        lugares = filtrados;
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
  // PESOS (MODIFICADO PARA DAR PRIORIDAD ABSOLUTA A GOOGLE PLACES)
  // -------------------------------------------------------------------------
  List<Map<String, dynamic>> _aplicarPesos(List<Map<String, dynamic>> lista) {
    return lista.map<Map<String, dynamic>>((lugar) {
      final rating = _toDouble(lugar['rating'], fb: 5);
      final popularity = _toDouble(lugar['popularity'], fb: 5);
      final distancia = _toDouble(lugar['distancia'], fb: 1);
      final categoria = lugar['categoriaPrincipal'].toString().toLowerCase();

      // Bono de cercanía geográfico
      double distanciaPeso = 10 / (distancia + 1);
      if (distanciaPeso > 10) distanciaPeso = 10;

      // GPS LOCAL
      if (destinoSeleccionado == null) {
        // Si es búsqueda local en su ubicación real, ignoramos la popularidad de internet
        // y ordenamos los lugares puramente por el que el usuario tenga más cerca
        lugar['relevancia'] = distanciaPeso * 10.0;
      } else {
        // Si el usuario buscó un destino turístico, aplicamos la fórmula polinomial base
        double interes = 0;
        if (_intereses.containsKey(categoria)) {
          final puntos = _intereses[categoria];
          if (puntos is int) interes = puntos >= 8 ? 10 : puntos * 1.25;
        }

        final tieneFotosReales =
            lugar['photos'] != null &&
            (lugar['photos'] is List) &&
            (lugar['photos'] as List).isNotEmpty;
        double bonoFuenteGoogle = tieneFotosReales ? 20.0 : 0.0;

        lugar['relevancia'] =
            (rating * 0.3) +
            (popularity * 0.2) +
            (distanciaPeso * 0.2) +
            (interes * 0.2) +
            bonoFuenteGoogle;
      }

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
  // TOP 5 (COMPLETA SIEMPRE LAS 5 TARJETAS)
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
      if (!res.any(
        (element) => element['name'] == l['name'] && element['lat'] == l['lat'],
      )) {
        res.add(l);
      }
    }
    return res.take(5).toList();
  }

  List<Map<String, dynamic>> get _lugaresFiltrados {
    // 1. Validamos si escribió una ciudad
    bool esCiudad = _ciudadesMexico.any(
      (c) =>
          c['nombre'].toString().toLowerCase() == query.toLowerCase().trim() ||
          c['id'].toString().toLowerCase() == query.toLowerCase().trim(),
    );

    // 2. Validamos si escribió exactamente lo mismo que el botón (ej. "cafeteria")
    bool esCategoria =
        query.toLowerCase().trim() ==
        (tipoSeleccionado ?? '').toLowerCase().trim();

    return FiltrosEtiquetasServicio.filtrarYObtenerTop5(
      listaCompleta: lugares,
      tipo: tipoSeleccionado,
      precio: precioSeleccionado,
      experiencia: estiloSeleccionado,
      // Si escribió la ciudad o la categoría, vaciamos el texto para no asfixiar el filtro
      queryTexto: (esCiudad || esCategoria) ? '' : query,
    );
  }

  // -------------------------------------------------------------------------
  // IMÁGENES DE RESPALDO (A prueba de bloqueos y CORS)
  // -------------------------------------------------------------------------
  String _obtenerImagenRespaldo(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'zona_arqueologica':
        return "https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Chichen_Itza_3.jpg/800px-Chichen_Itza_3.jpg";
      case 'cafeteria':
        return "https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/A_small_cup_of_coffee.JPG/800px-A_small_cup_of_coffee.JPG";
      case 'restaurante':
        return "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/Restaurant_in_Bogot%C3%A1.jpg/800px-Restaurant_in_Bogot%C3%A1.jpg";
      case 'playa':
        return "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Playa_del_Carmen%2C_Quintana_Roo%2C_Mexico.jpg/800px-Playa_del_Carmen%2C_Quintana_Roo%2C_Mexico.jpg";
      case 'museo':
        return "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Museo_Nacional_de_Antropolog%C3%ADa_-_Patio_Central.jpg/800px-Museo_Nacional_de_Antropolog%C3%ADa_-_Patio_Central.jpg";
      case 'bar':
        return "https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Irish_Pub_interior.jpg/800px-Irish_Pub_interior.jpg";
      case 'parque':
        return "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/Parque_M%C3%A9xico_04.jpg/800px-Parque_M%C3%A9xico_04.jpg";
      case 'mirador':
        return "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Mirador_de_La_Quebrada.jpg/800px-Mirador_de_La_Quebrada.jpg";
      case 'centro_comercial':
        return "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2b/Centro_Comercial_Santa_Fe.jpg/800px-Centro_Comercial_Santa_Fe.jpg";
      case 'actividades_extremas':
        return "https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/Tirolesa_en_Xplor.jpg/800px-Tirolesa_en_Xplor.jpg";
      case 'monumento':
        return "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a8/El_Angel_de_la_Independencia.jpg/800px-El_Angel_de_la_Independencia.jpg";
      default:
        return "https://upload.wikimedia.org/wikipedia/commons/thumb/9/96/Z%C3%B3calo_CDMX.jpg/800px-Z%C3%B3calo_CDMX.jpg";
    }
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
  // TRADUCTOR DE EMERGENCIA PARA NOMBRES
  // -------------------------------------------------------------------------
  String _traducirNombre(String nombreOriginal) {
    String nombre = nombreOriginal;
    // Diccionario para forzar los lugares que la API manda en inglés
    final traducciones = {
      'temple of immaculate': 'Templo de la Inmaculada',
      'temple of the immaculate': 'Templo de la Inmaculada',
      'bust of': 'Busto de',
      'statue of': 'Estatua de',
      'monument to': 'Monumento a',
      'church of': 'Iglesia de',
      'museum of': 'Museo de',
      'cathedral of': 'Catedral de',
      'historic center': 'Centro Histórico',
      'main square': 'Plaza Principal',
      'city hall': 'Palacio Municipal',
    };

    String nombreMin = nombre.toLowerCase();
    traducciones.forEach((ingles, espanol) {
      if (nombreMin.contains(ingles)) {
        // Reemplaza el texto sin importar si viene en mayúsculas o minúsculas
        nombre = nombre.replaceAll(
          RegExp(ingles, caseSensitive: false),
          espanol,
        );
      }
    });

    return nombre;
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
        surfaceTintColor: const Color.fromARGB(255, 255, 255, 255),
        scrolledUnderElevation: 0,
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

                        //  BUSCADOR INTELIGENTE CON AUTOCOMPLETADO DIFUSO
                        BarraBusqueda(
                          onChanged: (v) {
                            final textoLimpio = v.trim();
                            setState(() {
                              // Cambiamos el texto usando la función interna que limpia/actualiza tu buscador
                              _buscar(texto: textoLimpio);
                              // Calcula las sugerencias usando el motor Levenshtein centralizado
                              sugerenciasAutocompletado =
                                  FiltrosEtiquetasServicio.autocompletarDestinos(
                                    textoLimpio,
                                  );
                            });
                          },
                        ),

                        // DIBUJAR LAS SUGERENCIAS DEBAJO DE LA BARRA
                        if (sugerenciasAutocompletado.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: sugerenciasAutocompletado.map((
                                destinoSugerido,
                              ) {
                                return ListTile(
                                  leading: const Icon(
                                    Icons.location_on,
                                    color: Colors.blue,
                                  ),
                                  title: Text(destinoSugerido),
                                  onTap: () {
                                    setState(() {
                                      // 1. Asignamos de forma oficial el destino correcto al filtro superior
                                      destinoSeleccionado = destinoSugerido;

                                      // 2. Cerramos el menú flotante para que no estorbe en la UI
                                      sugerenciasAutocompletado = [];
                                    });

                                    // 3. Ejecuta la función de búsqueda original de tu pantalla
                                    _buscar(texto: destinoSugerido);
                                  },
                                );
                              }).toList(),
                            ),
                          ),

                        const SizedBox(height: 12),

                        // FILTROS
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

                        // LISTA
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
          imagenUrl: l['foto'] ?? l['imagen'],
          lugar: l, // EL PUENTE QUE LE MANDA LOS DATOS A LA TARJETA
          onTap: () {
            if (widget.esSeleccion) {
              // Extraemos opening_hours.weekday_text de Google Places (List → String)
              // o el campo hours si ya viene como string.
              String hoursStr = '';
              final openingHours = l['opening_hours'];
              if (openingHours != null && openingHours is Map) {
                final weekday = openingHours['weekday_text'];
                if (weekday is List && weekday.isNotEmpty) {
                  hoursStr = weekday.join(', ');
                }
              }
              if (hoursStr.isEmpty) {
                final h = l['hours'];
                if (h is List && h.isNotEmpty) {
                  hoursStr = h.join(', ');
                } else if (h is String && h.trim().isNotEmpty) {
                  hoursStr = h.trim();
                }
              }

              if (widget.esSeleccion) {
                Navigator.pop(context, l);
                return;
              }
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
