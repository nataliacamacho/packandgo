import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto/nucleo/servicios/resena_servicio.dart';
import 'package:proyecto/nucleo/utilidades/normalizador_lugares.dart';

class LugarDetallePantalla extends StatefulWidget {
  final Map<String, dynamic>? lugar;
  final String? nombre;
  final String? ubicacion;
  final String? imagenUrl;

  const LugarDetallePantalla({
    super.key,
    this.lugar,
    this.nombre,
    this.ubicacion,
    this.imagenUrl,
  });

  @override
  State<LugarDetallePantalla> createState() => _LugarDetallePantallaState();
}

class _LugarDetallePantallaState extends State<LugarDetallePantalla> {
  late MapboxMap mapboxMap;
  final TextEditingController resenaController = TextEditingController();
  int estrellas = 0;
  final uid = FirebaseAuth.instance.currentUser?.uid;

// ===================================================================
  // 📸 FUNCIÓN UNIVERSAL CON DETECTOR DE IMPOSTORES
  // ===================================================================
  String _obtenerFotoFinal() {
    // 🛑 Este es el "impostor" que nos estaba engañando
    const impostor = "https://images.unsplash.com/photo-1488646953014-85cb44e25828?q=80&w=400&auto=format&fit=crop";

    // Función rápida para saber si la URL es una foto REAL y no el mapa de Unsplash
    bool esFotoReal(String? url) {
      return url != null && url.startsWith('http') && url != impostor;
    }

    // 1. Buscamos la foto REAL en todas las llaves posibles (sin dejarnos engañar)
    if (esFotoReal(widget.imagenUrl)) return widget.imagenUrl!;
    if (esFotoReal(widget.lugar?['foto']?.toString())) return widget.lugar!['foto'].toString();
    if (esFotoReal(widget.lugar?['imagen']?.toString())) return widget.lugar!['imagen'].toString();

    // 2. EL SÚPER SEGURO: Extraemos de Google directamente si todo lo de arriba falla
    if (widget.lugar?['photos'] != null) {
      final list = widget.lugar!['photos'] as List<dynamic>;
      if (list.isNotEmpty) {
        final ref = list[0]['photo_reference'].toString().trim();
        final apiKey = "AIzaSyARaWdvsXGpJZD4uMUNoeAEXDoMcl3GGuQ";
        return "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$ref&key=$apiKey";
      }
    }

    // 3. Si de plano no tiene (ej. un Oxxo), ahora sí dejamos pasar al impostor (Unsplash)
    return impostor;
  }

  // =========================
  // 📍 COORDENADAS Y MAPA
  // =========================
  double? getLat() {
    if (widget.lugar == null) return null;
    if (widget.lugar!['geometry'] != null && widget.lugar!['geometry']['coordinates'] != null) {
      return widget.lugar!['geometry']['coordinates'][1];
    }
    if (widget.lugar!['geocodes']?['main']?['latitude'] != null) {
      return widget.lugar!['geocodes']['main']['latitude'];
    }
    return widget.lugar!['lat'];
  }

  double? getLng() {
    if (widget.lugar == null) return null;
    if (widget.lugar!['geometry'] != null && widget.lugar!['geometry']['coordinates'] != null) {
      return widget.lugar!['geometry']['coordinates'][0];
    }
    if (widget.lugar!['geocodes']?['main']?['longitude'] != null) {
      return widget.lugar!['geocodes']['main']['longitude'];
    }
    return widget.lugar!['lng'];
  }

  Future<void> _configurarMapa() async {
    final lat = getLat();
    final lng = getLng();
    if (lat == null || lng == null) return;
    await mapboxMap.setCamera(CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 16));
    final manager = await mapboxMap.annotations.createPointAnnotationManager();
    await manager.create(PointAnnotationOptions(geometry: Point(coordinates: Position(lng, lat))));
  }

  // =========================
  // ⭐ INTERFAZ DE RESEÑAS
  // =========================
  Widget _buildEstrellasView(int e) {
    return Row(children: List.generate(5, (i) => Icon(i < e ? Icons.star : Icons.star_border, size: 16, color: Colors.orange)));
  }

  Widget _buildEstrellas() {
    return Row(children: List.generate(5, (index) => IconButton(icon: Icon(index < estrellas ? Icons.star : Icons.star_border, color: Colors.black), onPressed: () => setState(() => estrellas = index + 1))));
  }

  Widget _promedio(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return const Text("Sin calificaciones");
    double total = 0;
    for (var d in docs) { total += ((d.data() as Map<String, dynamic>)['estrellas'] ?? 0); }
    double promedio = total / docs.length;
    return Row(children: [ Text(promedio.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(width: 5), _buildEstrellasView(promedio.round()), const SizedBox(width: 5), Text("(${docs.length})") ]);
  }

  Widget _card(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEstrellasView(data['estrellas'] ?? 0),
          const SizedBox(height: 5),
          Text(data['texto'] ?? ""),
        ],
      ),
    );
  }

  Future<void> _publicar(String nombreLugar) async {
    final texto = resenaController.text;
    if (texto.isEmpty || estrellas == 0) return;
    await FirebaseFirestore.instance.collection('resenas').add({
      'id_usuario': uid, 'id_lugar': nombreLugar, 'nombre_lugar': nombreLugar, 'texto': texto, 'estrellas': estrellas, 'ranking': estrellas * 10, 'fecha': FieldValue.serverTimestamp(),
    });
    resenaController.clear();
    setState(() => estrellas = 0);
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.lugar?['name'] ?? widget.nombre ?? NormalizadorLugares.obtenerNombre(widget.lugar);
    final categoria = widget.lugar?["categoriaPrincipal"] ?? "Atracción turística";
    final ubicacion = widget.lugar?['direccion'] ?? widget.ubicacion ?? NormalizadorLugares.obtenerDireccion(widget.lugar);
    final lat = getLat();
    final lng = getLng();

    // Calculamos cuál es la foto ganadora
    final fotoDefinitiva = _obtenerFotoFinal();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0066D2)), onPressed: () => Navigator.pop(context)),
        title: const Text("Pack&Go", style: TextStyle(color: Color(0xFF0066D2), fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MUESTRA LA FOTO CALCULADA POR EL SÚPER SEGURO
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  fotoDefinitiva,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(height: 200, width: double.infinity, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(height: 200, width: double.infinity, color: const Color(0xFF0066D2), child: const Icon(Icons.landscape, size: 70, color: Colors.white));
                  },
                ),
              ),

              const SizedBox(height: 16),
              Text(nombre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(categoria, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Row(children: [const Icon(Icons.location_on, color: Color(0xFFF6A230)), const SizedBox(width: 6), Expanded(child: Text(ubicacion))]),
              const SizedBox(height: 12),

              ExpansionTile(
                title: const Text("Reseñas", style: TextStyle(fontWeight: FontWeight.bold)),
                iconColor: const Color(0xFF0066D2),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('resenas').where('id_lugar', isEqualTo: nombre).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final docs = snapshot.data!.docs;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _promedio(docs), const SizedBox(height: 10), _buildEstrellas(),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: resenaController, decoration: InputDecoration(hintText: "Escribe tu reseña", filled: true, fillColor: Colors.grey[200], border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))),
                              const SizedBox(width: 10),
                              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF6A230)), onPressed: () => _publicar(nombre), child: const Text("Publicar", style: TextStyle(color: Colors.white))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (docs.isEmpty) const Text("Sin reseñas aún"),
                          ...docs.map(_card),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (lat != null && lng != null)
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MapWidget(
                      styleUri: MapboxStyles.MAPBOX_STREETS,
                      gestureRecognizers: { Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()) },
                      onMapCreated: (controller) => mapboxMap = controller,
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