import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiarioPantalla extends StatefulWidget {
  final String idViaje;
  final DateTime dia;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  const DiarioPantalla({
    super.key,
    required this.dia,
    required this.idViaje,
    required this.fechaInicio,
    required this.fechaFin,
  });

  @override
  State<DiarioPantalla> createState() => _DiarioPantallaState();
}

class _DiarioPantallaState extends State<DiarioPantalla> {
  final ImagePicker _picker = ImagePicker();
  List<File> fotosLocales = [];
  TextEditingController diarioController = TextEditingController();

  // Función para tomar o elegir foto y guardarla localmente
  Future<void> _obtenerFoto(ImageSource fuente) async {
    try {
      // 1. Abrimos cámara/galería con calidad 70 (Optimización requerida en tu DER)
      final XFile? foto = await _picker.pickImage(
        source: fuente,
        imageQuality: 70,
      );

      if (foto != null) {
        // 2. Obtenemos la ruta de documentos seguros del celular
        final directorio = await getApplicationDocumentsDirectory();

        // 3. Creamos un nuevo nombre para la foto usando la fecha exacta
        final nombreArchivo = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final rutaDestino = '${directorio.path}/$nombreArchivo';

        // 4. Movemos la foto temporal a la memoria permanente
        final fotoGuardada = await File(foto.path).copy(rutaDestino);

        setState(() {
          fotosLocales.add(fotoGuardada);
        });
      }
    } catch (e) {
      print("❌ Error al obtener la foto: $e");
    }
  }

  Future<void> guardarDiario() async {
    try {
      List<String> rutasDeFotos = fotosLocales
          .map((foto) => foto.path)
          .toList();

      // 🔥 Obtenemos el ID de tu usuario que inició sesión
      String uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('usuarios') // 🔥 Entramos a usuarios
          .doc(uid) // 🔥 Buscamos a este usuario
          .collection('viajes') // 🔥 Entramos a sus viajes
          .doc(widget.idViaje)
          .collection('diario')
          .doc(widget.dia.toIso8601String().split('T')[0])
          .set({
            'texto': diarioController.text,
            'fecha': widget.dia,
            'fotos_locales': rutasDeFotos,
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Diario guardado!"),
            backgroundColor: Color.fromARGB(255, 150, 150, 150),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
      }
    }
  }

  Future<void> cargarDiario() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String diaId = widget.dia.toIso8601String().split('T')[0];

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('viajes')
          .doc(widget.idViaje)
          .collection('diario')
          .doc(diaId)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        List<File> fotosRecuperadas = [];

        // Verificamos si hay fotos guardadas
        if (data['fotos_locales'] != null) {
          List<dynamic> rutas = data['fotos_locales'];

          for (var ruta in rutas) {
            File archivo = File(ruta.toString());
            // Validamos que el archivo siga existiendo en la memoria de tu celular
            if (await archivo.exists()) {
              fotosRecuperadas.add(archivo);
            } else {
              debugPrint(
                "La foto en la ruta $ruta ya no existe en el celular.",
              );
            }
          }
        }

        // Actualizamos la pantalla con el texto y las fotos validadas
        setState(() {
          diarioController.text = data['texto'] ?? '';
          fotosLocales = fotosRecuperadas;
        });
      }
    } catch (e) {
      debugPrint("Error al cargar el diario: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    // 🔥 Esto hace que la app busque tus recuerdos apenas entres a la pantalla
    cargarDiario();
  }

  @override
  Widget build(BuildContext context) {
    String fechaStr =
        "${widget.dia.day}/${widget.dia.month}/${widget.dia.year}";
    int numeroDia = widget.dia.difference(widget.fechaInicio).inDays + 1;

    return Scaffold(
      extendBodyBehindAppBar: false,
      
      appBar: AppBar(
  toolbarHeight: 180,
  backgroundColor: const Color(0xFFF6A230),
  elevation: 0,
  automaticallyImplyLeading: false,

  flexibleSpace: SafeArea(
    child: Stack(
      children: [

        /// CONTENIDO CENTRADO
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Día $numeroDia",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                fechaStr,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        /// BOTÓN REGRESO
        Positioned(
          top: 0,
          left: 0,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    ),
  ),
),

      /// 🔥 CONTENIDO TIPO ITINERARIO (CARDS)
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          /// 📸 FOTOS
          Card(
            color: const Color.fromARGB(255, 255, 255, 255),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Momentos del día",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _obtenerFoto(ImageSource.camera),
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066D2),
                        ),
                        label: const Text(
                          "Cámara",
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _obtenerFoto(ImageSource.gallery),
                        icon: const Icon(
                          Icons.photo_library,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066D2),
                        ),
                        label: const Text(
                          "Galería",
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    height: 120,
                    child: fotosLocales.isEmpty
                        ? const Center(child: Text("Aún no hay fotos"))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: fotosLocales.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Stack(
                                  children: [
                                    /// FOTO
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        fotosLocales[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),

                                    /// BOTÓN ELIMINAR
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () async {
                                          final confirmar = await showDialog<bool>(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                                                title: const Text(
                                                  "Eliminar foto",
                                                ),
                                                content: const Text(
                                                  "¿Estás seguro de que deseas eliminar esta foto?",
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "Cancelar", style: TextStyle(color: Color.fromARGB(255, 126, 126, 126)),
                                                    ),
                                                  ),

                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red.shade400,
                                                        ),
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "Eliminar",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          // Si canceló
                                          if (confirmar != true) return;

                                          final foto = fotosLocales[index];

                                          // Eliminar archivo físico
                                          if (await foto.exists()) {
                                            await foto.delete();
                                          }

                                          // Eliminar de la lista
                                          setState(() {
                                            fotosLocales.removeAt(index);
                                          });

                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text("Foto eliminada"),
                                              ),
                                            );
                                          }
                                        },

                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          /// 📝 TEXTO DIARIO
          Card(
            color: const Color.fromARGB(255, 255, 255, 255),
            elevation: 4,
            margin: const EdgeInsets.only(top: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Querido diario...",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 180,
                    child: TextField(
                      controller: diarioController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: "Hoy visité...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      /// 💾 BOTÓN GUARDAR IGUAL ESTILO
      floatingActionButton: FloatingActionButton.extended(
        onPressed: guardarDiario,
        backgroundColor: const Color(0xFF0066D2),
        icon: const Icon(Icons.save, color: Color.fromARGB(255, 255, 255, 255)),
        label: const Text(
          "Guardar",
          style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        ),
      ),
    );
  }
}
