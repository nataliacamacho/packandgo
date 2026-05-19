import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  Map<String, int> perfilUsuario = {};
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  double bonusKNNGlobal = 0;

  final Map<String, List<String>> mapeoTags = {
    'parque': ['park'],
    'parques': ['park'],
    'restaurante': ['restaurant'],
    'cafeteria': ['cafe'],
    'museo': ['museum'],
    'playa': ['beach'],
    'bar': ['bar'],
  };

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

  // =========================
  Future<bool> _esUsuarioNuevo() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();

    if (!doc.exists) return true;

    final data = doc.data();
    final historial = data?['historialEtiquetas'];

    if (historial == null || (historial as Map).isEmpty) return true;

    // ✅ Usuario nuevo si no tiene NINGUNA etiqueta con valor mayor a 0
    return !(historial as Map).values.any((v) => (v as num) > 0);
  }

  // =========================
  Future<void> _inicializarExploracion() async {
    final esNuevo = await _esUsuarioNuevo();

    if (esNuevo) {
      await _cargarCiudadesPopulares();
    } else {
      await _cargarLugaresPersonalizados();
    }
  }

  // =========================
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

  // =========================
  Future<void> _cargarCiudadesPopulares() async {
    setState(() => estaCargando = true);

    List<dynamic> lista = [];

    for (final c in ciudadesPopulares) {
      final lugares = await GooglePlacesServicio.buscarLugares(
        c['lat'],
        c['lng'],
        radio: 8000,
      );

      lista.addAll(lugares);
    }

    lista = _procesar(lista);

    _set(lista);
  }

  // =========================
  Future<void> _cargarLugaresPersonalizados() async {
    setState(() => estaCargando = true);

    try {
      await _actualizarPerfilUsuario();
      bonusKNNGlobal = await obtenerBonusKNN();

      final pos = await UbicacionServicio().obtenerUbicacionActual();
      if (pos == null) {
        _set([]);
        return;
      }

      List<Map<String, dynamic>> lugares;

      if (perfilUsuario.isNotEmpty) {
        // ✅ Busca específicamente las categorías que le interesan al usuario
        // Toma las top 4 categorías con más interacciones
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
        // Sin perfil: búsqueda genérica de turismo
        lugares = await GooglePlacesServicio.buscarLugares(
          pos.latitude,
          pos.longitude,
          tipo: 'monumento', // tourist_attraction, mucho mejor que sin tipo
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

  // =========================
  List<dynamic> _procesar(List<dynamic> input) {
    // Solo excluir categorías que no son turísticas
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

  // =========================
  double _score(Map l) {
    final rating = (l['rating'] ?? 0).toDouble();
    final pop = (l['user_ratings_total'] ?? 0).toDouble();

    // ✅ Usar categoriaPrincipal (ya en español) en vez de types (en inglés)
    final categoria = (l['categoriaPrincipal'] ?? '').toString().toLowerCase();

    double score = 0;
    score += rating * 3;
    score += log(pop + 1);

    if (perfilUsuario.isNotEmpty) {
      // Match directo con la categoría del lugar
      if (perfilUsuario.containsKey(categoria)) {
        score += perfilUsuario[categoria]! * 4.0;
        debugPrint(
          "✅ Match directo: $categoria +${perfilUsuario[categoria]! * 4.0}",
        );
      }

      // Bonus KNN
      score *= (1 + bonusKNNGlobal);
    }

    return score;
  }

  // =========================
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

  // =========================
  void _set(List<dynamic> lista) {
    if (!mounted) return;

    setState(() {
      lugaresRecomendados = lista.take(6).toList();
      estaCargando = false;
      indiceActual = 0;
    });
  }

  // =========================
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

  @override
  Widget build(BuildContext context) {
    String nombre = 'Desconocido';

    if (lugaresRecomendados.isNotEmpty) {
      final lugar = lugaresRecomendados[indiceActual];
      nombre = lugar['name'] ?? 'Lugar sin nombre';
    }

    Map<String, dynamic>? lugar;

    if (lugaresRecomendados.isNotEmpty) {
      lugar = lugaresRecomendados[indiceActual];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "¡Tu app favorita de viajes!",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 25),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Recomendaciones",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                height: 250,
                child: estaCargando
                    ? const Center(child: CircularProgressIndicator())
                    : lugaresRecomendados.isEmpty
                    ? const Center(child: Text("No hay recomendaciones"))
                    : Row(
                        children: [
                          GestureDetector(
                            onTap: indiceActual > 0 ? _anteriorLugar : null,
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

                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                final lugar = lugaresRecomendados[indiceActual];

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LugarDetallePantalla(
                                      lugar: lugar,
                                      // 🔥 Le pasamos la foto de Natalia ('foto') a la variable que acabamos de crear
                                      imagenUrl:
                                          lugar['foto'] ??
                                          "https://images.unsplash.com/photo-1488646953014-85cb44e25828?q=80&w=400&auto=format&fit=crop",
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0066D2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(15),
                                            ),
                                        child: lugar?['foto'] != null
                                            ? Image.network(
                                                lugar?['foto'],
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) {
                                                  return Container(
                                                    color: Colors.blueAccent,
                                                    child: const Icon(
                                                      Icons.landscape,
                                                      color: Colors.white,
                                                      size: 70,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: Colors.blueAccent,
                                                child: const Icon(
                                                  Icons.landscape,
                                                  color: Colors.white,
                                                  size: 70,
                                                ),
                                              ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Text(
                                        nombre,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          GestureDetector(
                            onTap: indiceActual < lugaresRecomendados.length - 1
                                ? _siguienteLugar
                                : null,
                            child: Container(
                              width: 40,
                              height: 80,
                              decoration: BoxDecoration(
                                color:
                                    indiceActual <
                                        lugaresRecomendados.length - 1
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
              ),

              const SizedBox(height: 40),

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
            ],
          ),
        ),
      ),
    );
  }
}
