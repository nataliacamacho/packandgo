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
  // 🔵 DETECTAR USUARIO NUEVO
  Future<bool> _esUsuarioNuevo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!doc.exists) return true;

      final data = doc.data();

      final historial = data?['historial'] ?? [];

      return (historial as List).isEmpty;
    } catch (e) {
      debugPrint("Error verificando usuario nuevo: $e");
      return true;
    }
  }

  // =========================
  // CONTROLADOR PRINCIPAL
  // =========================
  Future<void> _inicializarExploracion() async {
    final esNuevo = await _esUsuarioNuevo();

    if (esNuevo) {
      _cargarCiudadesPopulares();
    } else {
      _cargarLugaresPersonalizados();
    }
  }

  Future<void> _actualizarPerfilUsuario() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data();

      if (data == null) return;

      // 👇 aquí asumimos que guardas etiquetas como mapa
      final Map<String, dynamic> etiquetas = Map<String, dynamic>.from(
        data['etiquetas'] ?? {},
      );

      perfilUsuario = etiquetas.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } catch (e) {
      debugPrint("Error cargando perfil: $e");
    }
  }

  // =========================
  // 🔵 COLD START (NUEVO USUARIO)
  // =========================
  Future<void> _cargarCiudadesPopulares() async {
    setState(() => estaCargando = true);

    List<dynamic> adaptadas = [];

    for (var c in ciudadesPopulares) {
      final lugares = await GooglePlacesServicio.buscarLugares(
        c['lat'],
        c['lng'],
        query: c['name'],
        radio: 5000,
      );

      if (lugares.isNotEmpty) {
        adaptadas.add(lugares.first);
      }
    }

    setState(() {
      lugaresRecomendados = adaptadas;
      estaCargando = false;
      indiceActual = 0;
    });
  }

  // =========================
  // 🟡 USUARIO CON HISTORIAL
  // =========================
  Future<void> _cargarLugaresPersonalizados() async {
    setState(() => estaCargando = true);

    try {
      await _actualizarPerfilUsuario();

      final posicion = await UbicacionServicio().obtenerUbicacionActual();

      if (posicion == null) {
        throw Exception('No se pudo obtener la ubicación del usuario.');
      }

      final latUsuario = posicion.latitude;
      final lngUsuario = posicion.longitude;

      final lugares = await GooglePlacesServicio.buscarLugares(
        latUsuario,
        lngUsuario,
        radio: 15000,
      );

      if (mounted) {
        setState(() {
          lugaresRecomendados = ordenarRecomendaciones(lugares);
          estaCargando = false;
          indiceActual = 0;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');

      if (mounted) {
        setState(() => estaCargando = false);
      }
    }
  }

  // =========================
  // 🔷 SISTEMA DE RECOMENDACIÓN (MEJORADO)
  // =========================

  double calcularScoreLugar(Map lugar) {
    List<String> etiquetasLugar = (lugar['types'] ?? [])
        .map<String>((e) => e.toString())
        .toList();

    double score = 0;

    etiquetasLugar.forEach((etiqueta) {
      if (perfilUsuario.containsKey(etiqueta)) {
        score += perfilUsuario[etiqueta]!.toDouble();
      }
    });

    return score;
  }

  List<dynamic> ordenarRecomendaciones(List<dynamic> lugares) {
    lugares.sort((a, b) {
      double scoreA = calcularScoreLugar(a);
      double scoreB = calcularScoreLugar(b);

      return scoreB.compareTo(scoreA); // descendente
    });

    return lugares;
  }

  // =========================
  // NAVEGACIÓN
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
