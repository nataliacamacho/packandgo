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

  final uid = FirebaseAuth.instance.currentUser?.uid;

  // =========================
  // 📍 COORDENADAS
  // =========================
  double? getLat() {
    if (widget.lugar == null) return null;

    if (widget.lugar!['geometry'] != null) {
      return widget.lugar!['geometry']['coordinates'][1];
    }

    if (widget.lugar!['geocodes']?['main']?['latitude'] != null) {
      return widget.lugar!['geocodes']['main']['latitude'];
    }

    return widget.lugar!['lat'];
  }

  double? getLng() {
    if (widget.lugar == null) return null;

    if (widget.lugar!['geometry'] != null) {
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

    await mapboxMap.setCamera(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 16),
    );

    final manager = await mapboxMap.annotations.createPointAnnotationManager();

    await manager.create(
      PointAnnotationOptions(geometry: Point(coordinates: Position(lng, lat))),
    );
  }

  void _editarDialog(String id, Map<String, dynamic> data) {
    final controller = TextEditingController(text: data['texto']);
    int estrellasEdit = data['estrellas'];

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Editar reseña"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller),

              Row(
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < estrellasEdit ? Icons.star : Icons.star_border,
                    ),
                    onPressed: () {
                      estrellasEdit = i + 1;
                      (context as Element).markNeedsBuild();
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Guardar"),
              onPressed: () async {
                await ResenaServicio.editarResena(
                  id: id,
                  texto: controller.text,
                  estrellas: estrellasEdit,
                );

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  String obtenerCategoria(Map<String, dynamic>? lugar) {
    if (lugar == null) return 'Atracción turística';

    // =========================
    // 🟢 GOOGLE PLACES
    // =========================
    if (lugar['types'] != null && lugar['types'] is List) {
      final List<String> tipos = List<String>.from(
        lugar['types'].map((e) => e.toString().toLowerCase()),
      );

      // 🔥 PRIORIDAD (importante)
      if (tipos.any((t) => t.contains('restaurant'))) return 'Restaurante';
      if (tipos.any((t) => t.contains('cafe'))) return 'Cafetería';
      if (tipos.any((t) => t.contains('bar'))) return 'Bar';
      if (tipos.any((t) => t.contains('park'))) return 'Parque';
      if (tipos.any((t) => t.contains('museum'))) return 'Museo';
      if (tipos.any((t) => t.contains('shopping_mall')))
        return 'Centro comercial';

      // 🔥 ESTE SIEMPRE AL FINAL (porque es muy genérico)
      if (tipos.any((t) => t.contains('tourist_attraction'))) {
        return 'Atracción turística';
      }
    }

    // =========================
    // 🟡 OPENTRIPMAP
    // =========================
    if (lugar['kinds'] != null) {
      String kinds = lugar['kinds'];

      if (kinds.contains('restaurants')) return 'Restaurante';
      if (kinds.contains('cafes')) return 'Cafetería';
      if (kinds.contains('bars')) return 'Bar';
      if (kinds.contains('parks')) return 'Parque';
      if (kinds.contains('museums')) return 'Museo';
      if (kinds.contains('beaches')) return 'Playa';
      if (kinds.contains('historic')) return 'Monumento';
      if (kinds.contains('archaeological')) return 'Zona arqueológica';
      if (kinds.contains('view_points')) return 'Mirador';
      if (kinds.contains('shopping')) return 'Centro comercial';
    }

    // =========================
    // 🔵 FOURSQUARE (por si acaso)
    // =========================
    if (lugar['categories'] != null &&
        lugar['categories'] is List &&
        lugar['categories'].isNotEmpty) {
      return lugar['categories'][0]['name'];
    }

    return 'Atracción turística';
  }

  void _eliminarDialog(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar reseña"),
        content: const Text("¿Seguro que quieres eliminarla?"),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Eliminar"),
            onPressed: () async {
              await ResenaServicio.eliminarResena(id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // =========================
  // ⭐ INPUT
  // =========================
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

  Widget _buildEstrellasView(int e) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < e ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.orange,
        ),
      ),
    );
  }

  // =========================
  // 🧠 RANKING
  // =========================
  int _calcularRanking(Map<String, dynamic> r) {
    return (r['estrellas'] * 10) + (r['likes'] * 1) + (r['me_encanta'] * 2);
  }

  Future<void> _actualizarRanking(String id, Map<String, dynamic> data) async {
    final ranking = _calcularRanking(data);

    await FirebaseFirestore.instance.collection('resenas').doc(id).update({
      'ranking': ranking,
    });
  }

  // =========================
  // 👍 LIKE SIN DUPLICADOS
  // =========================
  Future<void> _like(String id, Map<String, dynamic> data) async {
    final ref = FirebaseFirestore.instance.collection('resenas').doc(id);

    List usuarios = data['usuarios_like'] ?? [];

    if (usuarios.contains(uid)) {
      await ref.update({
        'usuarios_like': FieldValue.arrayRemove([uid]),
        'likes': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'usuarios_like': FieldValue.arrayUnion([uid]),
        'likes': FieldValue.increment(1),
      });
    }

    final nuevo = await ref.get();
    final newData = nuevo.data() as Map<String, dynamic>;
    await _actualizarRanking(id, newData);
  }

  // =========================
  // ❤️ LOVE SIN DUPLICADOS
  // =========================
  Future<void> _love(String id, Map<String, dynamic> data) async {
    final ref = FirebaseFirestore.instance.collection('resenas').doc(id);

    List usuarios = data['usuarios_love'] ?? [];

    if (usuarios.contains(uid)) {
      await ref.update({
        'usuarios_love': FieldValue.arrayRemove([uid]),
        'me_encanta': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'usuarios_love': FieldValue.arrayUnion([uid]),
        'me_encanta': FieldValue.increment(1),
      });
    }

    final nuevo = await ref.get();
    final newData = nuevo.data() as Map<String, dynamic>;
    await _actualizarRanking(id, newData);
  }

  // =========================
  // 📝 PUBLICAR
  // =========================
  Future<void> _publicar(String nombreLugar) async {
    final texto = resenaController.text;

    final error = await ResenaServicio.validarTextoResena(texto);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (estrellas == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Selecciona estrellas")));
      return;
    }

    await FirebaseFirestore.instance.collection('resenas').add({
      'id_usuario': uid,
      'id_lugar': nombreLugar,
      'nombre_lugar': nombreLugar,
      'texto': texto,
      'estrellas': estrellas,
      'likes': 0,
      'me_encanta': 0,
      'usuarios_like': [],
      'usuarios_love': [],
      'ranking': estrellas * 10,
      'fecha': FieldValue.serverTimestamp(),
    });

    resenaController.clear();
    setState(() => estrellas = 0);
  }

  Widget _promedio(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return const Text("Sin calificaciones");

    double total = 0;

    for (var d in docs) {
      final data = d.data() as Map<String, dynamic>;
      total += (data['estrellas'] ?? 0);
    }

    double promedio = total / docs.length;

    return Row(
      children: [
        Text(
          promedio.toStringAsFixed(1),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 5),
        _buildEstrellasView(promedio.round()),
        const SizedBox(width: 5),
        Text("(${docs.length})"),
      ],
    );
  }

  Widget _card(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final esMia = data['id_usuario'] == uid;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEstrellasView(data['estrellas'] ?? 0),
          const SizedBox(height: 5),
          Text(data['texto'] ?? ""),

          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.thumb_up,
                  size: 18,
                  color: (data['usuarios_like'] ?? []).contains(uid)
                      ? Colors.blue
                      : Colors.grey,
                ),
                onPressed: () => _like(doc.id, data),
              ),
              Text("${data['likes'] ?? 0}"),

              IconButton(
                icon: Icon(
                  Icons.favorite,
                  size: 18,
                  color: (data['usuarios_love'] ?? []).contains(uid)
                      ? Colors.red
                      : Colors.grey,
                ),
                onPressed: () => _love(doc.id, data),
              ),
              Text("${data['me_encanta'] ?? 0}"),
              if (esMia)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _editarDialog(doc.id, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _eliminarDialog(doc.id),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = NormalizadorLugares.obtenerNombre(widget.lugar);

    final categoria = widget.lugar?["categoriaPrincipal"] ?? "Atracción turística";

    final ubicacion = NormalizadorLugares.obtenerDireccion(widget.lugar);

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
          style: TextStyle(
            color: Color(0xFF0066D2),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF0066D2),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.landscape,
                  color: Colors.white,
                  size: 60,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

              // 🔥 RESEÑAS
              ExpansionTile(
                title: const Text(
                  "Reseñas",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                iconColor: const Color(0xFF0066D2),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('resenas')
                        .where('id_lugar', isEqualTo: nombre)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final docs = snapshot.data!.docs;

                      docs.sort((a, b) {
                        final dataA = Map<String, dynamic>.from(
                          a.data() as Map,
                        );
                        final dataB = Map<String, dynamic>.from(
                          b.data() as Map,
                        );

                        return (dataB['ranking'] ?? 0).compareTo(
                          dataA['ranking'] ?? 0,
                        );
                      });

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _promedio(docs),

                          const SizedBox(height: 10),

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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF6A230),
                                ),
                                onPressed: () => _publicar(nombre),
                                child: const Text(
                                  "Publicar",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
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

              // MAPA
              if (lat != null && lng != null)
                SizedBox(
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
                      },
                      onStyleLoadedListener: (_) async =>
                          await _configurarMapa(),
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
