import 'package:flutter/material.dart';
import 'package:proyecto/modulos/busqueda/lugar_detalle_pantalla.dart';
import 'package:proyecto/modulos/viajes/crear_viaje_pantalla.dart';
import '../../nucleo/servicios/opentripmap_servicio.dart';
import '../../nucleo/servicios/ubicacion_servicio.dart';
import 'package:google_fonts/google_fonts.dart';

class ExploracionPantalla extends StatefulWidget {
  const ExploracionPantalla({super.key});

  @override
  State<ExploracionPantalla> createState() => _ExploracionPantallaState();
}

class _ExploracionPantallaState extends State<ExploracionPantalla> {
  List<dynamic> lugaresRecomendados = [];
  bool estaCargando = true;
  int indiceActual = 0;

  @override
  void initState() {
    super.initState();
    _cargarLugares();
  }

  Future<void> _cargarLugares() async {
    setState(() => estaCargando = true);

    try {
      final posicion = await UbicacionServicio().obtenerUbicacionActual();
      if (posicion == null) {
        throw Exception('No se pudo obtener la ubicación del usuario.');
      }

      final latUsuario = posicion.latitude;
      final lngUsuario = posicion.longitude;

      final lugaresCulturales =
          await OpenTripMapServicio.buscarLugaresCulturales(
            latUsuario,
            lngUsuario,
            radius: 500,
          );

      List<dynamic> lugaresAdaptados = [];

      final categoriasDeseadas = [
        'museum',
        'monument',
        'historic',
        'park',
        'natural',
        'architecture',
        'cultural',
        'recreation_ground',
      ];

      for (var item in lugaresCulturales) {
        final propiedades = item['properties'];
        final coordinates = item['geometry']?['coordinates'];

        final lng = coordinates != null ? coordinates[0] as double? : null;
        final lat = coordinates != null ? coordinates[1] as double? : null;

        if (propiedades != null &&
            propiedades['name'] != '' &&
            lat != null &&
            lng != null) {
          final kinds = propiedades['kinds'] as String?;
          final listaCategorias = kinds != null
              ? kinds.split(',').map((e) => {'name': e.trim()}).toList()
              : [
                  {'name': 'Desconocida'},
                ];

          if (listaCategorias.any(
            (c) => categoriasDeseadas.contains(c['name']),
          )) {
            lugaresAdaptados.add({
              'name': propiedades['name'],
              'categories': listaCategorias,
              'location': {
                'formatted_address':
                    propiedades['address'] ??
                    '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
              },
              'lat': lat,
              'lng': lng,
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          lugaresRecomendados = lugaresAdaptados;
          estaCargando = false;
          indiceActual = 0;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => estaCargando = false);
    }
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

  @override
  Widget build(BuildContext context) {
    String nombre = 'Desconocido';

    if (lugaresRecomendados.isNotEmpty) {
      final lugar = lugaresRecomendados[indiceActual];
      nombre = lugar['name'] ?? 'Lugar sin nombre';
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
                          // Flecha izquierda
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
                              child: const Center(
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          // TARJETA
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                final lugar = lugaresRecomendados[indiceActual];

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        LugarDetallePantalla(lugar: lugar),
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
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.blueAccent,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(15),
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
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

                          // Flecha derecha
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
