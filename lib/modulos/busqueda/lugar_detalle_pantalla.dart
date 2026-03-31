import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class LugarDetallePantalla extends StatefulWidget {
  final Map<String, dynamic>? lugar; // Datos de Foursquare o OpenTripMap
  final String? nombre;
  final String? ubicacion;

  const LugarDetallePantalla({
    super.key,
    this.lugar,
    this.nombre,
    this.ubicacion,
  });

  @override
  State<LugarDetallePantalla> createState() => _LugarDetallePantallaState();
}

class _LugarDetallePantallaState extends State<LugarDetallePantalla> {
  late MapboxMap mapboxMap;
  final TextEditingController resenaController = TextEditingController();
  int estrellas = 0;

  // Normaliza lat/lng según API
  double? getLat() {
    if (widget.lugar == null) return null;

    // Si vienen de OpenTripMap
    if (widget.lugar!['geometry'] != null && widget.lugar!['geometry']['coordinates'] != null) {
      final coords = widget.lugar!['geometry']['coordinates'];
      return coords[1] as double?;
    }

    // Si vienen de Foursquare
    if (widget.lugar!['geocodes']?['main']?['latitude'] != null) {
      return widget.lugar!['geocodes']['main']['latitude'] as double?;
    }

    // Si vienen ya adaptadas
    return widget.lugar!['lat'] as double?;
  }

  double? getLng() {
    if (widget.lugar == null) return null;

    // OpenTripMap
    if (widget.lugar!['geometry'] != null && widget.lugar!['geometry']['coordinates'] != null) {
      final coords = widget.lugar!['geometry']['coordinates'];
      return coords[0] as double?;
    }

    // Foursquare
    if (widget.lugar!['geocodes']?['main']?['longitude'] != null) {
      return widget.lugar!['geocodes']['main']['longitude'] as double?;
    }

    // Ya adaptadas
    return widget.lugar!['lng'] as double?;
  }

  Future<void> _configurarMapa() async {
    final lat = getLat();
    final lng = getLng();

    if (lat == null || lng == null) return;

    await mapboxMap.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: 14,
      ),
    );

    final annotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    await annotationManager.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
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
            setState(() => estrellas = index + 1);
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.lugar?['name'] ?? widget.nombre ?? 'Lugar desconocido';
    final categoria = (widget.lugar?['categories'] != null &&
            widget.lugar!['categories'].isNotEmpty)
        ? widget.lugar!['categories'][0]['name']
        : 'Atracción turística';
    final ubicacion = widget.lugar?['location']?['formatted_address'] ?? widget.ubicacion ?? 'Ubicación desconocida';

    final lat = getLat();
    final lng = getLng();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0066D2)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pack&Go",
          style: TextStyle(color: Color(0xFF0066D2), fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen placeholder
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF0066D2),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.landscape, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 16),
              // Información
              Text(nombre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(categoria, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFF6A230)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(ubicacion)),
                ],
              ),
              const SizedBox(height: 12),
              // Reseñas
              ExpansionTile(
                title: const Text("Reseñas", style: TextStyle(fontWeight: FontWeight.bold)),
                iconColor: const Color(0xFF0066D2),
                children: [
                  _buildEstrellas(),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: resenaController,
                          decoration: InputDecoration(
                            hintText: "Escribe tu reseña",
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
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF6A230)),
                        onPressed: () {
                          // Aquí publicar la reseña a Firebase
                        },
                        child: const Text("Publicar"),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Mapa Mapbox
              if (lat != null && lng != null)
                SizedBox(
                  height: 250,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MapWidget(
                      styleUri: MapboxStyles.MAPBOX_STREETS,
                      gestureRecognizers: {
                        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                      },
                      onMapCreated: (controller) {
                        mapboxMap = controller;
                      },
                      onStyleLoadedListener: (_) async => await _configurarMapa(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}