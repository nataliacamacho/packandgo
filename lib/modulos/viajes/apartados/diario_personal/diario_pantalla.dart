import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io'; 

class DiarioPantalla extends StatefulWidget {
  final String idViaje;
  final DateTime dia;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  const DiarioPantalla({super.key, required this.dia, required this.idViaje, required this.fechaInicio, required this.fechaFin});

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
      List<String> rutasDeFotos = fotosLocales.map((foto) => foto.path).toList();
      
      // 🔥 Obtenemos el ID de tu usuario que inició sesión
      String uid = FirebaseAuth.instance.currentUser!.uid; 

      await FirebaseFirestore.instance
          .collection('usuarios') // 🔥 Entramos a usuarios
          .doc(uid)               // 🔥 Buscamos a este usuario
          .collection('viajes')   // 🔥 Entramos a sus viajes
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
            content: Text("¡Querido diario guardado con éxito! 📖✨"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e")),
        );
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
              debugPrint("La foto en la ruta $ruta ya no existe en el celular.");
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
    String fechaStr = "${widget.dia.day}/${widget.dia.month}/${widget.dia.year}";

    return Scaffold(
      appBar: AppBar(title: Text("Diario - $fechaStr")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Momentos del día", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 10),

            // Botones de Cámara y Galería
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _obtenerFoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Cámara"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _obtenerFoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Galería"),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // 🔥 LÍNEA DEL TIEMPO HORIZONTAL
            SizedBox(
              height: 160,
              child: fotosLocales.isEmpty 
                ? const Center(child: Text("Aún no hay fotos. ¡Captura un momento!"))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: fotosLocales.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                fotosLocales[index],
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Pie de foto opcional
                            const SizedBox(
                              width: 100,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Pie de foto...",
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),

            const SizedBox(height: 20),

            // Texto descriptivo detallado
            const Text(
              "Querido diario...", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: diarioController,
                maxLines: null, // Permite que crezca hacia abajo
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: "¿Qué tal estuvo tu día? Escribe aquí todos los detalles...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          guardarDiario();
        },
        icon: const Icon(Icons.save),
        label: const Text("Guardar Diario"),
        backgroundColor: const Color(0xFF0066D2),
      ),
    );
  }
}