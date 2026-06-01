import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:proyecto/modulos/busqueda/lugar_detalle_pantalla.dart';
import 'package:proyecto/modulos/viajes/crear_viaje_pantalla.dart';
import 'package:proyecto/nucleo/servicios/google_places_servicio.dart';
import '../../nucleo/servicios/ubicacion_servicio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExploracionPantalla extends StatefulWidget {
  const ExploracionPantalla({super.key});

  @override
  State<ExploracionPantalla> createState() => _ExploracionPantallaState();
}

class _ExploracionPantallaState extends State<ExploracionPantalla> {
  List<dynamic> lugaresRecomendados = [];
  bool estaCargando = true;
  int indiceActual = 0;
  int indiceDestinoSimilar = 0;

  Map<String, int> perfilUsuario = {};
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<Map<String, dynamic>> destinosSimilares = [];

  double bonusKNNGlobal = 0;

  final List<Map<String, dynamic>> ciudadesPopulares = [
    {'name': 'Ciudad de México', 'lat': 19.4326, 'lng': -99.1332},
    {'name': 'Guadalajara', 'lat': 20.6597, 'lng': -103.3496},
    {'name': 'Monterrey', 'lat': 25.6866, 'lng': -100.3161},
    {'name': 'Cancún', 'lat': 21.1619, 'lng': -86.8515},
    {'name': 'Oaxaca', 'lat': 17.0732, 'lng': -96.7266},
  ];

  @override
  void initState() {
    super.initState();
    _inicializarExploracion();
  }

  Future<bool> _esUsuarioNuevo() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();

    if (!doc.exists) return true;
    final data = doc.data();
    final historial = data?['historialEtiquetas'];
    if (historial == null || (historial as Map).isEmpty) return true;
    return !(historial as Map).values.any((v) => (v as num) > 0);
  }

  Future<void> _inicializarExploracion() async {
    final esNuevo = await _esUsuarioNuevo();
    if (esNuevo) {
      await _cargarCiudadesPopulares();
    } else {
      await _cargarLugaresPersonalizados();
    }
  }

  Future<void> _actualizarPerfilUsuario() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();

    if (!doc.exists) return;
    final data = doc.data();
    final etiquetas = Map<String, dynamic>.from(
      data?['historialEtiquetas'] ?? {},
    );
    perfilUsuario = etiquetas.map(
      (key, value) => MapEntry(key.toLowerCase(), (value as num).toInt()),
    );
  }

  Future<void> _cargarCiudadesPopulares() async {
    setState(() => estaCargando = true);

    List<dynamic> lista = [];

    for (final c in ciudadesPopulares) {
      final lugares = await GooglePlacesServicio.buscarLugares(
        c['lat'],
        c['lng'],
        tipo: 'monumento',
        radio: 3000,
      );

      if (lugares.isNotEmpty) {
        final mejor = lugares.first;
        mejor['name'] = c['name'];
        lista.add(mejor);
      }
    }

    _set(lista);
  }

  Future<void> _cargarLugaresPersonalizados() async {
    setState(() => estaCargando = true);

    try {
      await _actualizarPerfilUsuario();
      await cargarDestinosViajerosSimilares();

      indiceDestinoSimilar = 0;

      bonusKNNGlobal = await obtenerBonusKNN();

      final pos = await UbicacionServicio().obtenerUbicacionActual();
      if (pos == null) {
        await _cargarCiudadesPopulares();
        return;
      }

      List<Map<String, dynamic>> lugares;

      if (perfilUsuario.isNotEmpty) {
        final topCategorias = perfilUsuario.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final categorias = topCategorias.take(4).map((e) => e.key).toList();
        debugPrint("🎯 Buscando categorías del perfil: $categorias");

        lugares = await GooglePlacesServicio.buscarPorCategorias(
          pos.latitude,
          pos.longitude,
          categorias: categorias,
          radio: 15000,
        );
      } else {
        lugares = await GooglePlacesServicio.buscarLugares(
          pos.latitude,
          pos.longitude,
          tipo: 'monumento',
          radio: 15000,
        );
      }

      List<dynamic> lista = _procesar(lugares);
      _set(lista);
    } catch (e) {
      debugPrint("ERROR: $e");
      _set([]);
    }
  }

  List<dynamic> _procesar(List<dynamic> input) {
    const categoriasExcluidas = {'otro'};

    final filtrados = input.where((l) {
      final cat = (l['categoriaPrincipal'] ?? 'otro').toString();
      return !categoriasExcluidas.contains(cat);
    }).toList();

    for (final l in filtrados) {
      l['score'] = _score(l);
    }

    filtrados.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    return filtrados;
  }

  double _score(Map l) {
    final rating = (l['rating'] ?? 0).toDouble();
    final pop = (l['user_ratings_total'] ?? 0).toDouble();
    final categoria = (l['categoriaPrincipal'] ?? '').toString().toLowerCase();

    double scoreBase = (rating * 3) + log(pop + 1);
    double puntajeSimilitud = 0.0;

    if (perfilUsuario.isNotEmpty) {
      if (perfilUsuario.containsKey(categoria)) {
        puntajeSimilitud += 1.0;
        puntajeSimilitud += (perfilUsuario[categoria]! * 0.5);
      }
      puntajeSimilitud *= (1 + bonusKNNGlobal);
    }

    return scoreBase + puntajeSimilitud;
  }

  Future<void> registrarInteraccion(Map lugar) async {
    if (uid.isEmpty) return;

    final categoria = (lugar['categoriaPrincipal'] ?? 'otro')
        .toString()
        .toLowerCase();
    final nombreLugar = (lugar['name'] ?? 'desconocido').toString();

    String direccionDeAPI = 'Desconocido';
    if (lugar['vicinity'] != null) {
      direccionDeAPI = lugar['vicinity'].toString();
    } else if (lugar['formatted_address'] != null) {
      direccionDeAPI = lugar['formatted_address'].toString();
    } else if (lugar['formattedAddress'] != null) {
      direccionDeAPI = lugar['formattedAddress'].toString();
    } else if (lugar['address'] != null) {
      direccionDeAPI = lugar['address'].toString();
    } else if (lugar['location'] != null && lugar['location']['city'] != null) {
      direccionDeAPI = lugar['location']['city'].toString();
    }

    String destino = 'Guadalajara';
    String dir = direccionDeAPI.toLowerCase();

    if (dir.contains('acapulco')) {
      destino = 'Acapulco';
    } else if (dir.contains('guadalajara') ||
        dir.contains('tlaquepaque') ||
        dir.contains('zapopan')) {
      destino = 'Guadalajara';
    } else if (dir.contains('méxico') ||
        dir.contains('cdmx') ||
        dir.contains('df')) {
      destino = 'Ciudad de México';
    } else if (dir.contains('monterrey')) {
      destino = 'Monterrey';
    } else if (dir.contains('cancún') || dir.contains('cancun')) {
      destino = 'Cancún';
    } else if (dir.contains('oaxaca')) {
      destino = 'Oaxaca';
    } else if (direccionDeAPI != 'Desconocido') {
      destino = direccionDeAPI;
    }

    final ref = FirebaseFirestore.instance.collection('usuarios').doc(uid);
    final doc = await ref.get();

    Map<String, dynamic> historialEtiquetas = {};
    Map<String, dynamic> historialDestinos = {};

    if (doc.exists) {
      final data = doc.data();
      historialEtiquetas = Map<String, dynamic>.from(
        data?['historialEtiquetas'] ?? {},
      );
      historialDestinos = Map<String, dynamic>.from(
        data?['historialDestinos'] ?? {},
      );
    }

    historialEtiquetas[categoria] = (historialEtiquetas[categoria] ?? 0) + 1;
    historialDestinos[destino] = (historialDestinos[destino] ?? 0) + 1;

    await ref.set({
      'historialEtiquetas': historialEtiquetas,
      'historialDestinos': historialDestinos,
      'ultimaInteraccion': {
        'lugar': nombreLugar,
        'categoria': categoria,
        'destino': destino,
        'fecha': DateTime.now(),
      },
    }, SetOptions(merge: true));
  }

  Future<double> obtenerBonusKNN() async {
    final snap = await FirebaseFirestore.instance.collection('usuarios').get();
    double best = 0;

    for (final d in snap.docs) {
      if (d.id == uid) continue;
      final data = d.data();
      final etiquetasRaw = Map<String, dynamic>.from(
        data['historialEtiquetas'] ?? {},
      );
      final other = etiquetasRaw.map(
        (k, v) => MapEntry(k.toLowerCase(), (v as num).toInt()),
      );
      final sim = _cosine(perfilUsuario, other);
      if (sim > best) best = sim;
    }

    return best;
  }

  double _cosine(Map<String, int> a, Map<String, int> b) {
    double dot = 0, ma = 0, mb = 0;
    final keys = {...a.keys, ...b.keys};

    for (final k in keys) {
      final va = (a[k] ?? 0).toDouble();
      final vb = (b[k] ?? 0).toDouble();
      dot += va * vb;
      ma += va * va;
      mb += vb * vb;
    }

    if (ma == 0 || mb == 0) return 0;
    return dot / (sqrt(ma) * sqrt(mb));
  }

  void _set(List<dynamic> lista) {
    if (!mounted) return;
    setState(() {
      lugaresRecomendados = lista.take(6).toList();
      estaCargando = false;
      // Empieza en el primer lugar (índice 0)
      indiceActual = 0;
    });
  }

  // RQF30: carga hasta 3 destinos de viajeros similares
  Future<void> cargarDestinosViajerosSimilares() async {
    final snap = await FirebaseFirestore.instance.collection('usuarios').get();
    Map<String, int> destinosContador = {};

    for (final d in snap.docs) {
      if (d.id == uid) continue;

      final data = d.data();
      final etiquetas = Map<String, dynamic>.from(
        data['historialEtiquetas'] ?? {},
      );
      final perfilOtro = etiquetas.map(
        (k, v) => MapEntry(k.toLowerCase(), (v as num).toInt()),
      );

      final similitud = _cosine(perfilUsuario, perfilOtro);

      debugPrint(
        "👥 Usuario: ${d.id} -> similitud = ${similitud.toStringAsFixed(3)}",
      );

      if (similitud >= 0.7) {
        final destinos = Map<String, dynamic>.from(
          data['historialDestinos'] ?? {},
        );
        for (final destino in destinos.keys) {
          destinosContador[destino] = (destinosContador[destino] ?? 0) + 1;
        }
      }
    }

    final ordenados = destinosContador.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    destinosSimilares.clear();

    // RQF30: intenta cargar hasta 3 destinos similares
    for (final destino in ordenados.take(3)) {
      final ciudad = ciudadesPopulares.firstWhere(
        (c) => c['name'].toString().toLowerCase() == destino.key.toLowerCase(),
        orElse: () => {},
      );

      if (ciudad.isNotEmpty) {
        final lugares = await GooglePlacesServicio.buscarLugares(
          ciudad['lat'],
          ciudad['lng'],
          tipo: 'monumento',
          radio: 3000,
        );

        if (lugares.isNotEmpty) {
          final lugar = Map<String, dynamic>.from(lugares.first);
          lugar['name'] = ciudad['name'];
          lugar['esDestino'] = true;
          destinosSimilares.add(lugar);
          debugPrint(
            "✅ RQF30: Destino similar cargado -> ${ciudad['name']} (foto: ${lugar['foto'] != null})",
          );
        }
      }
    }

    debugPrint(
      "📊 RQF30: Total destinos similares cargados: ${destinosSimilares.length}",
    );

    debugPrint("📍 Destinos encontrados: $destinosContador");
  }

  void _siguienteLugar() {
    if (indiceActual < lugaresRecomendados.length - 1) {
      setState(() => indiceActual++);
    }
  }

  void _anteriorLugar() {
    if (indiceActual > 0) {
      setState(() => indiceActual--);
    }
  }

  void _siguienteDestinoSimilar() {
    if (indiceDestinoSimilar < destinosSimilares.length - 1) {
      setState(() => indiceDestinoSimilar++);
    }
  }

  void _anteriorDestinoSimilar() {
    if (indiceDestinoSimilar > 0) {
      setState(() => indiceDestinoSimilar--);
    }
  }

  // =========================
  // Tarjeta — imagen cubre el 100% sin bordes
  // La clave: AspectRatio + LayoutBuilder para darle
  // constraints reales a la imagen antes de pintar.
  Widget _buildTarjetaLugar({
    required Map<String, dynamic> lugar,
    required VoidCallback onTap,
  }) {
    final String nombre = lugar['name'] ?? 'Lugar sin nombre';
    final String? fotoUrl = lugar['foto'];

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Altura total del carrusel es 250; barra de texto = 45
            const double alturaTexto = 45.0;
            final double alturaImagen = constraints.maxHeight > 0
                ? constraints.maxHeight - alturaTexto
                : 205.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagen con constraints explícitos del padre
                SizedBox(
                  width: constraints.maxWidth,
                  height: alturaImagen,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: fotoUrl != null
                        ? Image.network(
                            fotoUrl,
                            fit: BoxFit.cover,
                            width: constraints.maxWidth,
                            height: alturaImagen,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: const Color(0xFF1a7fd4),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF1a7fd4),
                              child: const Icon(
                                Icons.landscape,
                                color: Colors.white,
                                size: 70,
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF1a7fd4),
                            child: const Icon(
                              Icons.landscape,
                              color: Colors.white,
                              size: 70,
                            ),
                          ),
                  ),
                ),

                // Barra azul con nombre — altura fija
                Container(
                  height: alturaTexto,
                  width: constraints.maxWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  child: Text(
                    nombre,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================
  Widget _buildCarrusel({
    required bool estaCargando,
    required List<dynamic> items,
    required int indiceActual,
    required VoidCallback onAnterior,
    required VoidCallback onSiguiente,
    required Widget Function(Map<String, dynamic> item) buildTarjeta,
  }) {
    return SizedBox(
      height: 250,
      child: estaCargando
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const Center(child: Text("No hay recomendaciones"))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: indiceActual > 0 ? onAnterior : null,
                  child: Container(
                    width: 40,
                    height: 80,
                    decoration: BoxDecoration(
                      color: indiceActual > 0
                          ? const Color(0xFF0066D2)
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                // La tarjeta ocupa todo el espacio restante del Row,
                // y el SizedBox padre le da height: 250 — así LayoutBuilder
                // recibe constraints correctos (ancho Y alto definidos)
                Expanded(
                  child: buildTarjeta(
                    items[indiceActual] as Map<String, dynamic>,
                  ),
                ),

                const SizedBox(width: 15),

                GestureDetector(
                  onTap: indiceActual < items.length - 1 ? onSiguiente : null,
                  child: Container(
                    width: 40,
                    height: 80,
                    decoration: BoxDecoration(
                      color: indiceActual < items.length - 1
                          ? const Color(0xFF0066D2)
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Pack&Go",
          style: TextStyle(
            color: Color(0xFF0066D2),
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_outline,
              color: Color(0xFF0066D2),
              size: 32,
            ),
            onPressed: () => Navigator.pushNamed(context, '/EditarPerfil'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF0066D2),
        onRefresh: () async {
          await _inicializarExploracion();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "¡Tu app favorita de viajes!",
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 25),

                // ── Recomendaciones ──
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Recomendaciones",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 15),

                _buildCarrusel(
                  estaCargando: estaCargando,
                  items: lugaresRecomendados,
                  indiceActual: indiceActual,
                  onAnterior: _anteriorLugar,
                  onSiguiente: _siguienteLugar,
                  buildTarjeta: (lugar) => _buildTarjetaLugar(
                    lugar: lugar,
                    onTap: () async {
                      await registrarInteraccion(lugar);
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LugarDetallePantalla(
                            lugar: lugar,
                            imagenUrl:
                                lugar['foto'] ??
                                "https://images.unsplash.com/photo-1488646953014-85cb44e25828?q=80&w=400&auto=format&fit=crop",
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── RQF30: Viajeros similares ──
                if (destinosSimilares.isNotEmpty) ...[
                  const SizedBox(height: 25),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Otros viajeros como tú también consultaron...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildCarrusel(
                    estaCargando: false,
                    items: destinosSimilares,
                    indiceActual: indiceDestinoSimilar,
                    onAnterior: _anteriorDestinoSimilar,
                    onSiguiente: _siguienteDestinoSimilar,
                    buildTarjeta: (destino) => _buildTarjetaLugar(
                      lugar: destino,
                      onTap: () async {
                        await registrarInteraccion(destino);
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LugarDetallePantalla(
                              lugar: destino,
                              imagenUrl:
                                  destino['foto'] ??
                                  "https://images.unsplash.com/photo-1488646953014-85cb44e25828?q=80&w=400&auto=format&fit=crop",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 70),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CrearViajePantalla(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    "Crear Viaje",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6A230),
                  ),
                ),

                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 158, 158, 158),
                  ),
                  onPressed: () async {
                    await Geolocator.openLocationSettings();
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text(
                    "Activar/Desactivar ubicación",
                    style: TextStyle(
                      color: Color.fromARGB(255, 158, 158, 158),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
