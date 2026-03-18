import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:proyecto/nucleo/servicios/ubicacion_servicio.dart';

class LugarelegidoPantalla extends StatefulWidget {
  final String nombre;
  final String ubicacion;
  final double lat;
  final double lng;

  const LugarelegidoPantalla({
    super.key,
    required this.nombre,
    required this.ubicacion,
    required this.lat,
    required this.lng,
  });

  @override
  State<LugarelegidoPantalla> createState() => _LugarelegidoPantallaState();
}

class _LugarelegidoPantallaState extends State<LugarelegidoPantalla> {
  late MapboxMap mapboxMap;
  final UbicacionServicio ubicacionServicio = UbicacionServicio();
  final TextEditingController resenaController = TextEditingController();

  int estrellas = 0;

  Future<void> _configurarMapa() async {
    await mapboxMap.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(widget.lng, widget.lat)),
        zoom: 14,
      ),
    );

    final annotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();

    await annotationManager.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(widget.lng, widget.lat)),
      ),
    );
  }

  Widget _buildEstrellas() {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < estrellas ? Icons.star : Icons.star_border,
            color: Colors.black,
          ),
          onPressed: () {
            setState(() {
              estrellas = index + 1;
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),

      appBar: AppBar(
        title: Text("Pack&Go", style: GoogleFonts.poppins(fontSize: 36)),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "Imagen",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.ubicacion,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Text("Horario"),

                  const SizedBox(height: 10),

                  ExpansionTile(
                    tilePadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: -10,
                    ),
                    childrenPadding: EdgeInsets.zero,
                    title: const Text(
                      "Reseñas",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),

                    children: [
                      _buildEstrellas(),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: resenaController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: "Evitar palabras ofensivas",
                                hintStyle: const TextStyle(fontSize: 14),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF6A230),
                            ),
                            onPressed: () {
                              //aquí luego conectaremos Firebase
                            },
                            child: const Text(
                              "Publicar",
                              style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Reseñas...",
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 250,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MapWidget(
                    styleUri: MapboxStyles.MAPBOX_STREETS,

                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },

                    onMapCreated: (controller) {
                      mapboxMap = controller;

                      mapboxMap.scaleBar.updateSettings(
                        ScaleBarSettings(enabled: false),
                      );
                    },

                    onStyleLoadedListener: (style) async {
                      await _configurarMapa();
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
