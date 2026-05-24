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
      // Busca solo 1 lugar turístico representativo de cada ciudad
      final lugares = await GooglePlacesServicio.buscarLugares(
        c['lat'],
        c['lng'],
        tipo: 'monumento', // tourist_attraction → trae fotos bonitas
        radio: 3000, // radio chico para que salga algo del centro
      );

      if (lugares.isNotEmpty) {
        // Toma el mejor (primero = mejor rating de Google)
        final mejor = lugares.first;

        // Sobreescribe el nombre con el de la ciudad
        mejor['name'] = c['name'];

        lista.add(mejor);
      }
    }

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
        await _cargarCiudadesPopulares();
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
  // RQF10: Ordenar resultados de mayor a menor puntaje
  List<dynamic> _procesar(List<dynamic> input) {
    const categoriasExcluidas = {'otro'};

    final filtrados = input.where((l) {
      final cat = (l['categoriaPrincipal'] ?? 'otro').toString();
      return !categoriasExcluidas.contains(cat);
    }).toList();

    // Calculamos el score de similitud para cada lugar
    for (final l in filtrados) {
      l['score'] = _score(l);
    }

    // RQF10: Método sort() para ordenar de MAYOR a MENOR (descendente)
    filtrados.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    for(var lugar in filtrados){
  debugPrint("Lugar: ${lugar['name']} - Score Final: ${lugar['score']}");
  }
    return filtrados;
  }

  // =========================
  // RQF8 y RQF9: Cálculo de puntaje de similitud y asignación de 1 punto
  double _score(Map l) {
    final rating = (l['rating'] ?? 0).toDouble();
    final pop = (l['user_ratings_total'] ?? 0).toDouble();
    final categoria = (l['categoriaPrincipal'] ?? '').toString().toLowerCase();

    double scoreBase = (rating * 3) + log(pop + 1); // Lo que ya tenías de popularidad
    double puntajeSimilitud = 0.0; // RQF8: Inicializamos el puntaje de similitud

    if (perfilUsuario.isNotEmpty) {
      // Comparamos las etiquetas del destino con las del perfil
      if (perfilUsuario.containsKey(categoria)) {
        // RQF9: Asignar 1 punto por cada coincidencia
        puntajeSimilitud += 1.0; 
        
        // (Opcional) Le sumamos un peso extra basado en la frecuencia para mejor precisión
        puntajeSimilitud += (perfilUsuario[categoria]! * 0.5); 
        debugPrint("✅ Match directo: $categoria -> +1 punto de similitud (RQF9)");
      }

      // Bonus KNN que tenías
      puntajeSimilitud *= (1 + bonusKNNGlobal);
    }

    // El score total es la suma de la base + la similitud
    return scoreBase + puntajeSimilitud;
  }

  // =========================
  // RQF11: Registro de interacciones con Filtro Inteligente de Ciudades
  Future<void> registrarInteraccion(Map lugar) async {
    if (uid.isEmpty) return;

    final categoria = (lugar['categoriaPrincipal'] ?? 'otro').toString().toLowerCase();
    final nombreLugar = (lugar['name'] ?? 'desconocido').toString();
    
    // 🔥 LÍNEA DE ORO: Te imprimirá en la consola de tu editor todo el objeto 
    // para que veas qué datos trae el lugar cuando le das clic.
    debugPrint("🔍 Click en: $nombreLugar | Datos del mapa: $lugar");

    // 1. Buscamos la dirección en cualquier formato que use la API
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

    // 2. Filtro inteligente: Analizamos el texto para guardar la ciudad limpia
    String destino = 'Guadalajara'; // Ciudad por defecto si todo lo demás falla
    String direccionMinusculas = direccionDeAPI.toLowerCase();

    if (direccionMinusculas.contains('acapulco')) {
      destino = 'Acapulco';
    } else if (direccionMinusculas.contains('guadalajara') || 
               direccionMinusculas.contains('tlaquepaque') || 
               direccionMinusculas.contains('zapopan')) {
      destino = 'Guadalajara';
    } else if (direccionMinusculas.contains('méxico') || 
               direccionMinusculas.contains('cdmx') || 
               direccionMinusculas.contains('df')) {
      destino = 'Ciudad de México';
    } else if (direccionMinusculas.contains('monterrey')) {
      destino = 'Monterrey';
    } else if (direccionMinusculas.contains('cancún') || 
               direccionMinusculas.contains('cancun')) {
      destino = 'Cancún';
    } else if (direccionMinusculas.contains('oaxaca')) {
      destino = 'Oaxaca';
    } else if (direccionDeAPI != 'Desconocido') {
      // Si es otra ciudad diferente a las anteriores, guarda lo que mande la API
      destino = direccionDeAPI; 
    }

    final ref = FirebaseFirestore.instance.collection('usuarios').doc(uid);
    final doc = await ref.get();

    Map<String, dynamic> historialEtiquetas = {};
    Map<String, dynamic> historialDestinos = {};

    if (doc.exists) {
      final data = doc.data();
      historialEtiquetas = Map<String, dynamic>.from(data?['historialEtiquetas'] ?? {});
      historialDestinos = Map<String, dynamic>.from(data?['historialDestinos'] ?? {});
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
      if (lugaresRecomendados.length >= 3) {
        indiceActual = 2; 
      } else {
        indiceActual = 0;
      }
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
                                onTap: () async {
                                  final lugar =
                                      lugaresRecomendados[indiceActual];

                                  // 🔥 registrar interacción
                                  await registrarInteraccion(lugar);

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
                              onTap:
                                  indiceActual < lugaresRecomendados.length - 1
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

                const SizedBox(height: 110),

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
      ),
    );
  }
}
