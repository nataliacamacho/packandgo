import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/mixtas/rutamixta_pantalla.dart';
import 'package:proyecto/nucleo/servicios/mapbox_servicio.dart';
import 'package:proyecto/nucleo/servicios/ubicacion_servicio.dart';

class CarroPantalla extends StatefulWidget {
  final double destinoLat;
  final double destinoLng;
  final String destinoNombre;
  final String origen;

  const CarroPantalla({
    super.key,
    required this.destinoLat,
    required this.destinoLng,
    required this.destinoNombre, 
    required this.origen,
  });

  @override
  State<CarroPantalla> createState() => _CarroPantallaState();
}

class _CarroPantallaState extends State<CarroPantalla> {
  final MapboxServicio _mapboxServicio = MapboxServicio();
  final UbicacionServicio _ubicacionServicio = UbicacionServicio();

  final MapController _mapController = MapController();

  List<LatLng> ruta = [];
  LatLng? origen;
  LatLng? destino;

  double distancia = 0;
  double duracion = 0;
  bool cargando = true;
  String mensaje = '';

  final token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  @override
  void initState() {
    super.initState();
    _cargarRuta();
  }

  LatLngBounds _calcularBounds(List<LatLng> puntos) {
    double minLat = puntos.first.latitude;
    double maxLat = puntos.first.latitude;
    double minLng = puntos.first.longitude;
    double maxLng = puntos.first.longitude;

    for (var p in puntos) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  void _ajustarMapa() {
    if (ruta.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bounds = _calcularBounds(ruta);

      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    });
  }

  Future<void> _cargarRuta() async {
    final posicion = await _ubicacionServicio.obtenerUbicacionActual();

    if (posicion == null) {
      if (!mounted) return;
      setState(() {
        mensaje = "No se pudo obtener ubicación";
        cargando = false;
      });
      return;
    }

    origen = LatLng(posicion.latitude, posicion.longitude);
    destino = LatLng(widget.destinoLat, widget.destinoLng);

    final data = await _mapboxServicio.obtenerRuta(
      origenLat: posicion.latitude,
      origenLng: posicion.longitude,
      destinoLat: widget.destinoLat,
      destinoLng: widget.destinoLng,
    );

    if (data == null ||
        data['coordenadas'] == null ||
        (data['coordenadas'] as List).isEmpty) {
      if (!mounted) return;
      setState(() {
        mensaje = "No se pudo generar la ruta";
        cargando = false;
      });
      return;
    }

    final distanciaKm = data['distancia'] / 1000;
    final duracionMin = data['duracion'] / 60;

    if (distanciaKm > 500) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RutaMixtaPantalla(
            destinoLat: widget.destinoLat,
            destinoLng: widget.destinoLng,
            destinoNombre: widget.destinoNombre,
            origen: widget.origen,
          ),
        ),
      );

      return;
    }

    final nuevaRuta = (data['coordenadas'] as List)
        .map((coord) => LatLng(coord[1], coord[0]))
        .toList();

    if (!mounted) return;
    setState(() {
      ruta = nuevaRuta;
      distancia = distanciaKm;
      duracion = duracionMin;
      cargando = false;
    });

    _ajustarMapa();
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String text,
    String? subtext,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (subtext != null)
                    Text(subtext, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (mensaje.isNotEmpty) {
      return Scaffold(body: Center(child: Text(mensaje)));
    }

    return Scaffold(
      // ================= APPBAR CORREGIDO =================
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 50,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: const BoxDecoration(color: Color(0xFFF6A230)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(height: 10),

                  Center(
                    child: Text(
                      "Ruta en carro",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  Center(
                    child: Text(
                      "Información estimada",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🔥 DESTINO ABAJO IZQUIERDA
                  Text(
                    widget.destinoNombre,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // 🔙 BACK BUTTON FIJO ARRIBA IZQUIERDA
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                bottom: false,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ================= MAPA =================
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: ruta.isNotEmpty
                    ? ruta.first
                    : const LatLng(0, 0),
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=$token",
                ),
                PolylineLayer(
                  polylines: [Polyline(points: ruta, strokeWidth: 4)],
                ),
                MarkerLayer(
                  markers: [
                    if (origen != null)
                      Marker(
                        point: origen!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 35,
                        ),
                      ),
                    if (destino != null)
                      Marker(
                        point: destino!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.flag,
                          color: Colors.red,
                          size: 35,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ================= INFO =================
          Positioned(
            top: 25,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    backgroundColor: Color.fromARGB(255, 255, 255, 255),
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Información de la ruta",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 15),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Tiempo estimado"),
                                Text("${duracion.toStringAsFixed(0)} min"),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Distancia"),
                                Text("${distancia.toStringAsFixed(2)} km"),
                              ],
                            ),

                            const SizedBox(height: 20),

                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFF6A230),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _ajustarMapa,
                              icon: const Icon(Icons.center_focus_strong),
                              label: const Text("Recentrar ruta"),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6),
                    ],
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
