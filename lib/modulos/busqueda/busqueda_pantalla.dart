import 'dart:async';
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
  Timer? _debounce;

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
    if (destinoSeleccionado != null) {
      final ciudad = _ciudadesMexico.firstWhere(
        (c) => c['id'] == destinoSeleccionado,
        orElse: () => {},
      );

      if (ciudad.isNotEmpty && ciudad['lat'] != null) {
        _latActual = (ciudad['lat'] as num).toDouble();
        _lngActual = (ciudad['lng'] as num).toDouble();
        return;
      }
    }

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

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      await _resolverCoordenadas();

      final google = await GooglePlacesServicio.buscarLugares(
        _latActual,
        _lngActual,
        query: texto.isEmpty ? 'turismo' : texto,
        tipo: tipoSeleccionado,
      );

      final open = await OpenTripMapServicio.buscarLugaresCulturales(
        _latActual,
        _lngActual,
        query: texto,
        tipo: tipoSeleccionado,
      );

      // 1. combinar
      List<Map<String, dynamic>> combinados = [...google, ...(open ?? [])];

      // 2. normalizar
      combinados = combinados.map((l) {
        final categoria = _normalizarCategoria(l['categoriaPrincipal']);

        return {
          ...l,
          'categoriaPrincipal': categoria,
          'name': l['name'] ?? 'Sin nombre',
          'direccion': _obtenerDireccion(l),
          'rating': _toDouble(l['rating'], fb: 5),
          'popularity': _toDouble(l['popularity'], fb: 5),
          'precio': l['precio'],
          'lat': l['lat'],
          'lng': l['lng'],
          'distancia': calcularDistancia(
            _latActual,
            _lngActual,
            _toDouble(l['lat']),
            _toDouble(l['lng']),
          ),
        };
      }).toList();

      // 3. limpiar inválidos
      combinados = combinados
          .where(
            (l) => l['lat'] != null && l['lng'] != null && l['name'] != null,
          )
          .toList();

      // 4. eliminar duplicados
      final Map<String, Map<String, dynamic>> unicos = {};
      for (final l in combinados) {
        final key = "${l['name']}_${l['lat']}_${l['lng']}";
        unicos[key] = l;
      }

      combinados = unicos.values.toList();

      // 5. pesos
      final conPesos = _aplicarPesos(combinados);

      // 6. FILTROS (solo aquí)
      final filtrados = conPesos.where(_applyFilters).toList();

      // 7. orden
      final ordenados = _quickSort(filtrados);

      // 8. top 5 SOLO sin filtros activos
      final sinFiltros =
          texto.isEmpty &&
          destinoSeleccionado == null &&
          tipoSeleccionado == null &&
          precioSeleccionado == null;

      final finales = sinFiltros ? _top5(ordenados) : ordenados;

      setState(() {
        lugares = finales;
        cargando = false;
      });
    } catch (e) {
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

    if (direccion.isNotEmpty && direccion.toLowerCase() != 'sin dirección') {
      return direccion;
    }

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

    // 🥇 CAFETERÍA (PRIORIDAD MÁXIMA)
    if (texto.contains('cafe') ||
        texto.contains('café') ||
        texto.contains('coffee') ||
        texto.contains('coffee_shop') ||
        texto.contains('bakery') ||
        texto.contains('espresso')) {
      return 'cafeteria';
    }

    // 🍻 BAR (ANTES QUE RESTAURANTE)
    if (texto.contains('bar') ||
        texto.contains('pub') ||
        texto.contains('night_club')) {
      return 'bar';
    }

    // 🍽️ RESTAURANTE (SOLO SI NO ES CAFÉ)
    if (texto.contains('restaurant') ||
        texto.contains('food') ||
        texto.contains('diner') ||
        texto.contains('eatery')) {
      return 'restaurante';
    }

    // 🌴 PLAYA
    if (texto.contains('beach') &&
        !texto.contains('club') &&
        !texto.contains('bar') &&
        !texto.contains('restaurant')) {
      return 'playa';
    }

    // 🌳 PARQUE
    if (texto.contains('park') || texto.contains('garden')) {
      return 'parque';
    }

    // 🏛️ MUSEO
    if (texto.contains('museum') || texto.contains('gallery')) {
      return 'museo';
    }

    // 🛍️ CENTRO COMERCIAL
    if (texto.contains('mall') || texto.contains('shopping')) {
      return 'centro_comercial';
    }

    // 📍 MIRADOR
    if (texto.contains('viewpoint') || texto.contains('view')) {
      return 'mirador';
    }

    // 🏺 HISTÓRICO
    if (texto.contains('monument') || texto.contains('historic')) {
      return 'monumento';
    }

    // 🏺 ARQUEOLÓGICO
    if (texto.contains('archaeology')) {
      return 'zona_arqueologica';
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

      if (distanciaPeso > 10) {
        distanciaPeso = 10;
      }

      double interes = 0;

      if (_intereses.containsKey(categoria)) {
        final puntos = _intereses[categoria];

        if (puntos is int) {
          interes = puntos >= 8 ? 10 : puntos * 1.25;
        }
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

    final mayores = lista.where((e) {
      return _toDouble(e['relevancia']) > pivote;
    }).toList();

    final iguales = lista.where((e) {
      return _toDouble(e['relevancia']) == pivote;
    }).toList();

    final menores = lista.where((e) {
      return _toDouble(e['relevancia']) < pivote;
    }).toList();

    return [..._quickSort(mayores), ...iguales, ..._quickSort(menores)];
  }

  // -------------------------------------------------------------------------
  // TOP 5
  // -------------------------------------------------------------------------
  List<Map<String, dynamic>> _top5(List<Map<String, dynamic>> lista) {
    lista.sort(
      (a, b) =>
          _toDouble(b['relevancia']).compareTo(_toDouble(a['relevancia'])),
    );

    final Map<String, Map<String, dynamic>> categorias = {};
    final List<Map<String, dynamic>> res = [];

    for (final l in lista) {
      final cat = l['categoriaPrincipal'] ?? 'otro';
      if (!categorias.containsKey(cat)) {
        categorias[cat] = l;
      }
    }

    res.addAll(categorias.values);

    for (final l in lista) {
      if (res.length >= 5) break;
      if (!res.contains(l)) res.add(l);
    }

    return res.take(5).toList();
  }

  // -------------------------------------------------------------------------
  // FILTRO CENTRAL (REEMPLAZA TODO EL ERROR DE DOBLE FILTRADO)
  // -------------------------------------------------------------------------
  bool _applyFilters(Map<String, dynamic> l) {
    final categoria = (l['categoriaPrincipal'] ?? '').toString().toLowerCase();

    if (tipoSeleccionado != null) {
      final filtro = _normalizarCategoria(tipoSeleccionado);
      if (categoria != filtro) return false;
    }

    if (precioSeleccionado != null) {
      final precio = l['precio']?.toString();
      if (precio == null || precio != precioSeleccionado) return false;
    }

    if (query.isNotEmpty) {
      final nombre = (l['name'] ?? '').toString().toLowerCase();
      if (!nombre.contains(query.toLowerCase())) return false;
    }

    return true;
  }

  // -------------------------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------------------------
  double _toDouble(dynamic v, {double fb = 0}) {
    if (v == null) return fb;

    if (v is double) return v;

    if (v is int) return v.toDouble();

    if (v is String) {
      return double.tryParse(v) ?? fb;
    }

    return fb;
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Pack&Go', style: GoogleFonts.poppins(fontSize: 36)),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),

        child: Column(
          children: [
            const SizedBox(height: 16),

            // -------------------------------------------------------------
            // BARRA
            // -------------------------------------------------------------
            BarraBusqueda(
              onChanged: (v) {
                setState(() {
                  query = v;
                });

                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  if (v.length >= 3) {
                    _buscar(texto: v);
                  }

                  if (v.isEmpty) {
                    _buscar();
                  }
                });
              },
            ),

            const SizedBox(height: 12),

            // -------------------------------------------------------------
            // FILTROS
            // -------------------------------------------------------------
            FiltrosBusqueda(
              destinoSeleccionado: destinoSeleccionado,

              tipoSeleccionado: tipoSeleccionado,

              estiloSeleccionado: estiloSeleccionado,

              precioSeleccionado: precioSeleccionado,

              onDestinoChanged: (v) {
                setState(() {
                  destinoSeleccionado = v;
                });

                _buscar(texto: query);
              },

              onTipoChanged: (v) {
                setState(() {
                  tipoSeleccionado = v;
                });

                _buscar(texto: query);
              },

              onEstiloChanged: (v) {
                setState(() {
                  estiloSeleccionado = v;
                });
              },

              onPrecioChanged: (v) {
                setState(() {
                  precioSeleccionado = v;
                });
              },
            ),

            const SizedBox(height: 16),

            // -------------------------------------------------------------
            // LISTA
            // -------------------------------------------------------------
            Expanded(child: _buildLista()),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // LISTA
  // -------------------------------------------------------------------------
  Widget _buildLista() {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

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
              onPressed: () {
                _buscar(texto: query);
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final filtrados = lugares;

    if (filtrados.isEmpty) {
      return const Center(child: Text('No se encontraron lugares'));
    }

    return ListView.builder(
      itemCount: filtrados.length,

      itemBuilder: (context, index) {
        final l = filtrados[index];

        return TarjetaLugar(
          nombre: l['name']?.toString() ?? 'Sin nombre',

          ubicacion: l['direccion']?.toString() ?? 'Sin dirección',

          lat: _toDouble(l['lat']),
          lng: _toDouble(l['lng']),

          categoria: l['categoriaPrincipal']?.toString() ?? 'otro',

          onTap: () {
            // ---------------------------------------------------
            // SI VIENE DESDE ITINERARIO
            // ---------------------------------------------------
            if (widget.esSeleccion) {
              Navigator.pop(context, {
                "nombre": l['name'],
                "categoria": l['categoriaPrincipal'],
                "lat": l['lat'],
                "lng": l['lng'],
                "hours": l['hours'],
                "foto": l['photo'],
                "direccion": l['direccion'],
                "rating": l['rating'],
              });

              return;
            }

            // ---------------------------------------------------
            // MODO NORMAL
            // ---------------------------------------------------
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LugarDetallePantalla(lugar: l)),
            );
          },
        );
      },
    );
  }
}
