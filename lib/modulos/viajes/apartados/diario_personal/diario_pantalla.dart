import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

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
  List<DateTime> fechasFotos = [];
  TextEditingController diarioController = TextEditingController();

  List<TextEditingController> captionsControllers = [];
  List<TextEditingController> actividadControllers = [];
  List<TextEditingController> lugarControllers = [];

  Future<bool> _solicitarPermisoGaleria() async {
    PermissionStatus estado;

    if (Platform.isAndroid) {
      estado = await Permission.photos.request();
    } else {
      estado = await Permission.photos.request();
    }

    if (estado.isGranted) {
      return true;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Puedes seguir usando el diario aunque no otorgues permisos.",
          ),
        ),
      );
    }

    return false;
  }

  // Función para tomar o elegir foto y guardarla localmente
  Future<void> _obtenerFoto(ImageSource fuente) async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: fuente,
        imageQuality: 70,
      );

      if (foto == null) return;

      // 📁 Carpeta privada permanente de la app
      final directorioBase = await getApplicationDocumentsDirectory();

      // 📁 Carpeta específica del viaje
      final carpetaViaje = Directory(
        '${directorioBase.path}/diarios/${widget.idViaje}',
      );

      // Crear carpeta si no existe
      if (!await carpetaViaje.exists()) {
        await carpetaViaje.create(recursive: true);
      }

      // Nombre único para la foto
      final nombreArchivo = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Ruta final
      final rutaDestino = '${carpetaViaje.path}/$nombreArchivo';

      // ✅ Copiar imagen a almacenamiento local permanente
      final fotoGuardada = await File(foto.path).copy(rutaDestino);

      // 🔍 Verificar ruta guardada
      debugPrint('Foto guardada en: ${fotoGuardada.path}');

      setState(() {
        fotosLocales.add(fotoGuardada);

        captionsControllers.add(TextEditingController());
        actividadControllers.add(TextEditingController());
        lugarControllers.add(TextEditingController());

        fechasFotos.add(DateTime.now());
      });

      // ✅ Guardado automático
      await guardarDiario();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto guardada correctamente")),
        );
      }
    } catch (e) {
      debugPrint("❌ Error al obtener foto: $e");
    }
  }

  Future<void> guardarDiario() async {
    try {
      List<Map<String, dynamic>> fotosConDescripcion = [];

      for (int i = 0; i < fotosLocales.length; i++) {
        fotosConDescripcion.add({
          'ruta': fotosLocales[i].path,
          'descripcion': captionsControllers[i].text,
          'actividad': actividadControllers[i].text,
          'lugar': lugarControllers[i].text,
          'fechaAgregado': fechasFotos[i],
        });
      }
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
            'fotos_locales': fotosConDescripcion,
          }, SetOptions(merge: true));
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
          List<dynamic> fotosGuardadas = data['fotos_locales'];
          fotosGuardadas.sort((a, b) {
            final fechaA = (a['fechaAgregado'] as Timestamp).toDate();
            final fechaB = (b['fechaAgregado'] as Timestamp).toDate();

            return fechaA.compareTo(fechaB);
          });

          for (var item in fotosGuardadas) {
            final ruta = item['ruta'];

            File archivo = File(ruta);

            if (await archivo.exists()) {
              fotosRecuperadas.add(archivo);

              captionsControllers.add(
                TextEditingController(text: item['descripcion'] ?? ''),
              );
              actividadControllers.add(
                TextEditingController(text: item['actividad'] ?? ''),
              );

              lugarControllers.add(
                TextEditingController(text: item['lugar'] ?? ''),
              );
            }
          }
        }

        // Actualizamos la pantalla con el texto y las fotos validadas
        setState(() {
          diarioController.text = data['texto'] ?? '';
          fotosLocales = fotosRecuperadas;
          fechasFotos = [];
          for (var item in data['fotos_locales'] ?? []) {
            fechasFotos.add((item['fechaAgregado'] as Timestamp).toDate());
          }
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
  void dispose() {
    diarioController.dispose();

    for (var controller in captionsControllers) {
      controller.dispose();
    }
    for (var controller in actividadControllers) {
      controller.dispose();
    }

    for (var controller in lugarControllers) {
      controller.dispose();
    }

    super.dispose();
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
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                        onPressed: () async {
                          final permitido = await _solicitarPermisoGaleria();

                          if (permitido) {
                            _obtenerFoto(ImageSource.gallery);
                          }
                        },
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
                    height: 420,
                    child: fotosLocales.isEmpty
                        ? const Center(child: Text("Aún no hay fotos"))
                        : PageView.builder(
                            controller: PageController(viewportFraction: 0.82),
                            itemCount: fotosLocales.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),

                                child: Column(
                                  children: [
                                    // 📸 FOTO
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),

                                          child: Image.file(
                                            fotosLocales[index],
                                            width: double.infinity,
                                            height: 180,
                                            fit: BoxFit.cover,
                                          ),
                                        ),

                                        // ❌ ELIMINAR
                                        Positioned(
                                          top: 8,
                                          right: 8,

                                          child: GestureDetector(
                                            onTap: () async {
                                              final confirmar =
                                                  await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                          "Eliminar foto",
                                                        ),

                                                        content: const Text(
                                                          "¿Deseas eliminar esta foto?",
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
                                                              "Cancelar",
                                                            ),
                                                          ),

                                                          ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                context,
                                                                true,
                                                              );
                                                            },

                                                            child: const Text(
                                                              "Eliminar",
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );

                                              if (confirmar != true) return;

                                              final foto = fotosLocales[index];

                                              if (await foto.exists()) {
                                                await foto.delete();
                                              }

                                              captionsControllers[index]
                                                  .dispose();

                                              setState(() {
                                                fotosLocales.removeAt(index);

                                                captionsControllers[index]
                                                    .dispose();

                                                captionsControllers[index]
                                                    .dispose();
                                                captionsControllers.removeAt(
                                                  index,
                                                );

                                                actividadControllers[index]
                                                    .dispose();
                                                actividadControllers.removeAt(
                                                  index,
                                                );

                                                lugarControllers[index]
                                                    .dispose();
                                                lugarControllers.removeAt(
                                                  index,
                                                );

                                                fechasFotos.removeAt(index);
                                              });

                                              await guardarDiario();
                                            },

                                            child: Container(
                                              padding: const EdgeInsets.all(5),

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

                                    const SizedBox(height: 12),

                                    // 📝 PIE DE FOTO
                                    SizedBox(
                                      width: 240,

                                      child: TextField(
                                        controller: captionsControllers[index],

                                        textAlign: TextAlign.center,

                                        maxLines: 2,

                                        onChanged: (_) {
                                          guardarDiario();
                                        },

                                        decoration: InputDecoration(
                                          hintText: "Pie de foto",
                                          isDense: true,

                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),

                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    SizedBox(
                                      width: 240,
                                      child: TextField(
                                        controller: actividadControllers[index],
                                        textAlign: TextAlign.center,

                                        onChanged: (_) {
                                          guardarDiario();
                                        },

                                        decoration: InputDecoration(
                                          hintText: "Actividad",
                                          isDense: true,

                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),

                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    SizedBox(
                                      width: 240,
                                      child: TextField(
                                        controller: lugarControllers[index],
                                        textAlign: TextAlign.center,

                                        onChanged: (_) {
                                          guardarDiario();
                                        },

                                        decoration: InputDecoration(
                                          hintText: "Lugar",
                                          isDense: true,

                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),

                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                      onChanged: (_) {
                        guardarDiario();
                      },
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
    );
  }
}
