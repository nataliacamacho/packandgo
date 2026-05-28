import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto/nucleo/servicios/resena_servicio.dart';
import 'package:proyecto/nucleo/utilidades/normalizador_lugares.dart';
import 'package:proyecto/nucleo/utilidades/constantes_ciudades.dart';

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
  File? imagenResena;
  bool subiendoFoto = false;

  // ===================================================================
  // 📸 FUNCIÓN UNIVERSAL CON DETECTOR DE IMPOSTORES
  // ===================================================================
  String _obtenerFotoFinal() {
    // 🛑 Este es el "impostor" que nos estaba engañando
    const impostor =
        "https://images.unsplash.com/photo-1488646953014-85cb44e25828?q=80&w=400&auto=format&fit=crop";

    // Función rápida para saber si la URL es una foto REAL y no el mapa de Unsplash
    bool esFotoReal(String? url) {
      return url != null && url.startsWith('http') && url != impostor;
    }

    // 1. Buscamos la foto REAL en todas las llaves posibles (sin dejarnos engañar)
    if (esFotoReal(widget.imagenUrl)) return widget.imagenUrl!;
    if (esFotoReal(widget.lugar?['foto']?.toString()))
      return widget.lugar!['foto'].toString();
    if (esFotoReal(widget.lugar?['imagen']?.toString()))
      return widget.lugar!['imagen'].toString();

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

  Future<void> _seleccionarImagen() async {
    final imagePicker = picker.ImagePicker();

    final imagen = await imagePicker.pickImage(
      source: picker.ImageSource.gallery,
      imageQuality: 70,
    );

    if (imagen != null) {
      setState(() {
        imagenResena = File(imagen.path);
      });
    }
  }

  Future<String?> _subirImagenResena() async {
    if (imagenResena == null) return null;

    try {
      setState(() {
        subiendoFoto = true;
      });

      final nombreArchivo =
          "resenas/${DateTime.now().millisecondsSinceEpoch}.jpg";

      final ref = FirebaseStorage.instance.ref().child(nombreArchivo);

      await ref.putFile(imagenResena!);

      final url = await ref.getDownloadURL();

      return url;
    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
      return null;
    } finally {
      setState(() {
        subiendoFoto = false;
      });
    }
  }

  // =========================
  // 📍 COORDENADAS Y MAPA
  // =========================
  double? getLat() {
    if (widget.lugar == null) return null;
    if (widget.lugar!['geometry'] != null &&
        widget.lugar!['geometry']['coordinates'] != null) {
      return widget.lugar!['geometry']['coordinates'][1];
    }
    if (widget.lugar!['geocodes']?['main']?['latitude'] != null) {
      return widget.lugar!['geocodes']['main']['latitude'];
    }
    return widget.lugar!['lat'];
  }

  double? getLng() {
    if (widget.lugar == null) return null;
    if (widget.lugar!['geometry'] != null &&
        widget.lugar!['geometry']['coordinates'] != null) {
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

  // =========================
  // ⭐ INTERFAZ DE RESEÑAS
  // =========================
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

  Widget _buildEstrellas() {
    return Row(
      children: List.generate(
        5,
        (index) => IconButton(
          icon: Icon(
            index < estrellas ? Icons.star : Icons.star_border,
            color: Colors.black,
          ),
          onPressed: () => setState(() => estrellas = index + 1),
        ),
      ),
    );
  }

  Widget _promedio(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return const Text("Sin calificaciones");
    double total = 0;
    for (var d in docs) {
      total += ((d.data() as Map<String, dynamic>)['estrellas'] ?? 0);
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
          if (data['foto'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                data['foto'],
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          if (data['foto'] != null) const SizedBox(height: 10),

          _buildEstrellasView(data['estrellas'] ?? 0),

          const SizedBox(height: 5),

          Text(
            data['texto'] ?? "",
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          if (data['id_usuario'] == uid) const SizedBox(height: 10),

          Row(
            children: [
              // ❤️ ME ENCANTA
              IconButton(
                onPressed: () async {
                  try {
                    await ResenaServicio.reaccionarResena(
                      idResena: doc.id,
                      tipo: 'love',
                      autorId: data['id_usuario'],
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("$e")));
                  }
                },
                icon: Icon(
                  Icons.favorite,
                  color: Colors.red.shade300,
                  size: 20,
                ),
              ),

              Text("${data['me_encanta'] ?? 0}"),

              const SizedBox(width: 10),

              // 👍 LIKE
              IconButton(
                onPressed: () async {
                  try {
                    await ResenaServicio.reaccionarResena(
                      idResena: doc.id,
                      tipo: 'like',
                      autorId: data['id_usuario'],
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("$e")));
                  }
                },
                icon: Icon(
                  Icons.thumb_up,
                  color: Colors.blue.shade300,
                  size: 20,
                ),
              ),

              Text("${data['likes'] ?? 0}"),

              StreamBuilder<bool>(
                stream: ResenaServicio.esFavorita(doc.id),
                builder: (context, snapshot) {
                  final esFavorita = snapshot.data ?? false;

                  return IconButton(
                    onPressed: () async {
                      await ResenaServicio.toggleFavorita(idResena: doc.id);
                    },
                    icon: Icon(
                      esFavorita ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.amber,
                    ),
                  );
                },
              ),

              // 🔥 EMPUJA EL BOTÓN ELIMINAR HASTA LA DERECHA
              const Spacer(),

              // 🗑️ ELIMINAR SOLO SI ES TU RESEÑA
              if (data['id_usuario'] == uid)
                TextButton.icon(
                  onPressed: () async {
                    final confirmar = await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: Color.fromARGB(255, 255, 255, 255),
                        title: const Text("Eliminar reseña"),
                        content: const Text(
                          "¿Seguro que deseas eliminar esta reseña?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              "Cancelar",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "Eliminar",
                              style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmar == true) {
                      await ResenaServicio.eliminarResena(doc.id);
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text("Eliminar"),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _publicar(String nombreLugar) async {
    final texto = resenaController.text.trim();

    if (texto.isEmpty || estrellas == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa la reseña y las estrellas")),
      );
      return;
    }

    final error = await ResenaServicio.validarTextoResena(texto);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    try {
      String? fotoUrl;

      // 🔥 SUBIR FOTO SI EL USUARIO SELECCIONÓ UNA
      if (imagenResena != null) {
        fotoUrl = await _subirImagenResena();
      }

      await ResenaServicio.guardarResena(
        idLugar: nombreLugar,
        nombreLugar: nombreLugar,
        texto: texto,
        estrellas: estrellas,
        fotoUrl: fotoUrl,
      );

      resenaController.clear();

      setState(() {
        estrellas = 0;
        imagenResena = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Reseña publicada")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al publicar: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    _registrarVisita();
  }

  Future<void> _registrarVisita() async {
    if (uid == null) return;

    final categoria = (widget.lugar?['categoriaPrincipal'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    // 🔥 AQUÍ USAMOS LA MISMA LÓGICA QUE EN TU BUILD PARA OBTENER LA UBICACIÓN LIMPIA
    final ubicacionLimpia =
        widget.lugar?['direccion'] ??
        widget.ubicacion ??
        NormalizadorLugares.obtenerDireccion(widget.lugar) ??
        'Guadalajara';

    if (categoria.isEmpty || categoria == 'otro') return;

    try {
      // Usamos el mismo filtro inteligente que ya probamos, pero aplicado a la variable limpia
      String destino = _extraerCiudadDeDireccion(ubicacionLimpia);

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'historialEtiquetas': {categoria: FieldValue.increment(1)},
        'historialDestinos': {destino: FieldValue.increment(1)},
        'ultimaInteraccion': {
          'lugar': widget.lugar?['name'] ?? 'desconocido',
          'categoria': categoria,
          'destino': destino,
          'fecha': DateTime.now(),
        },
      }, SetOptions(merge: true));

      debugPrint("✅ Registro exitoso: $categoria en $destino");
    } catch (e) {
      debugPrint("❌ Error: $e");
    }
  }

  String _extraerCiudadDeDireccion(String direccionRaw) {
    // Convertimos a minúsculas una sola vez al principio
    String dir = direccionRaw.toLowerCase();

    // 1. Buscamos primero en tu lista oficial
    for (var ciudad in ciudadesMexico) {
      // 🔥 USAMOS 'dir' (que ya es minúsculas) para comparar
      if (dir.contains(ciudad['nombre'].toString().toLowerCase())) {
        return ciudad['nombre'];
      }
    }

    // 2. Casos especiales (Si la lista no los atrapó)
    if (dir.contains('cdmx') ||
        dir.contains('df') ||
        dir.contains('ciudad de méxico'))
      return 'Ciudad de México';
    if (dir.contains('q.r.') || dir.contains('quintana roo')) return 'Cancún';

    // 3. Fallback seguro
    List<String> partes = direccionRaw.split(',');
    return partes.length > 1 ? partes[partes.length - 2].trim() : "Otros";
  }

    // 1. Aquí pegas el helper, justo arriba del build
  String _formatearPrecioDinamico() {
    // Le agregué un signo de interrogación a widget.lugar? por si acaso
    final apiPriceLevel = widget.lugar?['price_level'] ?? widget.lugar?['price'];
    
    if (apiPriceLevel != null) {
      int level = int.tryParse(apiPriceLevel.toString()) ?? -1;
      if (level == 0 || level == 1) return "\$ - Económico";
      if (level == 2) return "\$\$ - Medio";
      if (level == 3) return "\$\$\$ - Costoso";
      if (level == 4) return "\$\$\$\$ - Muy Exclusivo";
    }
    
    return widget.lugar?['precio'] ?? "\$";
  }
      

 @override
  Widget build(BuildContext context) {
    final nombre =
        widget.lugar?['name'] ??
        widget.nombre ??
        NormalizadorLugares.obtenerNombre(widget.lugar);
    final categoria =
        widget.lugar?["categoriaPrincipal"] ?? "Atracción turística";
    final ubicacion =
        widget.lugar?['direccion'] ??
        widget.ubicacion ??
        NormalizadorLugares.obtenerDireccion(widget.lugar);
    final lat = getLat();
    final lng = getLng();

    // Calculamos cuál es la foto ganadora
    final fotoDefinitiva = _obtenerFotoFinal();

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
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: const Color(0xFF0066D2),
                      child: const Icon(
                        Icons.landscape,
                        size: 70,
                        color: Colors.white,
                      ),
                    );
                  },
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
              const SizedBox(height: 16),

              // ==============================================================
              // 🔥 AQUÍ ESTÁ LO NUEVO: PRECIO Y HORARIOS (YA INTEGRADOS)
              // ==============================================================
              Row(
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Color(0xFFF6A230), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Precio estimado: ${_formatearPrecioDinamico()}",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'Horarios de Atención',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8),

              if (widget.lugar?['opening_hours'] != null && widget.lugar?['opening_hours']['weekday_text'] != null) ...[
                Card(
                  elevation: 0,
                  color: Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (widget.lugar?['opening_hours']['weekday_text'] as List<dynamic>).map((diaTexto) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_filled_rounded, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  diaTexto.toString(),
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Establecimiento sin horarios registrados. Te recomendamos consultar directamente antes de tu visita.',
                          style: TextStyle(fontSize: 13, color: Colors.amber[900], fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // ==============================================================

              const SizedBox(height: 20),

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
                        .orderBy('ranking', descending: true)
                        .orderBy('fecha', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const CircularProgressIndicator();
                      final docs = snapshot.data!.docs;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _promedio(docs),

                          const SizedBox(height: 20),

                          // ⭐ Selección de estrellas
                          const Text(
                            "Califica este lugar",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 6),

                          _buildEstrellas(),

                          const SizedBox(height: 18),

                          // ✍️ Caja de reseña
                          TextField(
                            controller: resenaController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: "Cuéntanos tu experiencia...",
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.all(14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 📸 BOTÓN FOTO
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _seleccionarImagen,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0066D2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.photo),
                                label: const Text("Agregar foto"),
                              ),

                              const SizedBox(width: 12),

                              if (imagenResena != null)
                                const Expanded(
                                  child: Text(
                                    "Foto seleccionada",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // 👀 Preview de imagen
                          if (imagenResena != null) ...[
                            const SizedBox(height: 14),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                imagenResena!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // 🚀 BOTÓN PUBLICAR
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF6A230),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: subiendoFoto
                                  ? null
                                  : () => _publicar(nombre),
                              child: subiendoFoto
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      "Publicar reseña",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 📝 LISTA DE RESEÑAS
                          if (docs.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Text(
                                "Aún no hay reseñas para este lugar.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),

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
                      gestureRecognizers: {
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                      onMapCreated: (controller) => mapboxMap = controller,
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
