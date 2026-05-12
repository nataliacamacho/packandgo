import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto/modulos/viajes/apartados/hospedaje/hospedaje_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/maleta/maleta_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/diario_personal/lista_diario_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/transporte_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/itinerario/itinerario_pantalla.dart';
import 'package:proyecto/nucleo/utilidades/formatear_destino.dart';
import 'package:path/path.dart' as path;

class DetalleViajePantalla extends StatefulWidget {
  final String idViaje;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String descripcion;
  final String destino;
  final double destinoLat;
  final double destinoLng;
  final String origen;

  const DetalleViajePantalla({
    super.key,
    required this.idViaje,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.descripcion,
    required this.destino,
    required this.destinoLat,
    required this.destinoLng,
    required this.origen,
  });

  @override
  State<DetalleViajePantalla> createState() => _DetalleViajePantallaState();
}

class _DetalleViajePantallaState extends State<DetalleViajePantalla> {
  File? imagenLocal;
  String? imagenUrl;
  final ImagePicker picker = ImagePicker();

  Future<void> seleccionarImagen() async {
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen == null) return;

    final file = File(imagen.path);

    setState(() {
      imagenLocal = file; // muestra inmediato
    });

    final url = await subirImagen(file);

    if (url != null) {
      setState(() {
        imagenUrl = url; // actualiza desde Firebase
      });

      await FirebaseFirestore.instance
          .collection('viajes')
          .doc(widget.idViaje)
          .update({'imagen': url});
    }
  }

  Future<String?> subirImagen(File imagen) async {
    try {
      final nombre = path.basename(imagen.path);

      final ref = FirebaseStorage.instance.ref().child(
        'viajes/${widget.idViaje}/portada.jpg',
      );

      await ref.putFile(imagen);

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
      return null;
    }
  }

  bool yaTerminoViaje() {
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = DateTime(
      widget.fechaFin.year,
      widget.fechaFin.month,
      widget.fechaFin.day,
    );

    return hoySinHora.isAfter(fin);
  }

  void mostrarDialogoCancelar(BuildContext context, String idViaje) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.cancel_outlined, color: Color(0xFFF6A230)),
            SizedBox(width: 8),
            Text(
              "Cancelar viaje",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "Este viaje se marcará como CANCELADO y pasará a viajes pasados.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF6A230),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("viajes")
                  .doc(idViaje)
                  .update({'cancelado': true});

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Viaje cancelado")));
            },
            child: const Text("Cancelar"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    cargarImagen();
  }

  Future<void> cargarImagen() async {
    final doc = await FirebaseFirestore.instance
        .collection('viajes')
        .doc(widget.idViaje)
        .get();

    final data = doc.data();

    if (data != null && data['imagen'] != null) {
      setState(() {
        imagenUrl = data['imagen'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    FormateadorDestino.formatear(widget.destino);
    final fechaInicioTexto =
        "${widget.fechaInicio.day}/${widget.fechaInicio.month}/${widget.fechaInicio.year}";
    final fechaFinTexto =
        "${widget.fechaFin.day}/${widget.fechaFin.month}/${widget.fechaFin.year}";

    final viajeTerminado = yaTerminoViaje();

    return Scaffold(
      extendBodyBehindAppBar: false,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: const Color(0xFF0066D2),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),

          flexibleSpace: Stack(
            fit: StackFit.expand,
            children: [
              // 🔥 PRIMERO el fondo
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  image: (imagenLocal != null)
                      ? DecorationImage(
                          image: FileImage(imagenLocal!),
                          fit: BoxFit.cover,
                        )
                      : (imagenUrl != null)
                      ? DecorationImage(
                          image: NetworkImage(imagenUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),

              // Gradiente encima del fondo
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),

              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: seleccionarImagen,
                    child: Center(
                      child: (imagenLocal == null && imagenUrl == null)
                          ? const Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.white70,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              // Texto
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nombre,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 4),

                    if (widget.descripcion.isNotEmpty)
                      Text(
                        widget.descripcion,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "$fechaInicioTexto - $fechaFinTexto",
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 12),

            item(
              context,
              Icons.directions_car,
              "Transporte",
              "Opciones para llegar al destino",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransportePantalla(
                      origen: widget.origen,
                      destino: widget.destino,
                      destinoLat: widget.destinoLat,
                      destinoLng: widget.destinoLng,
                    ),
                  ),
                );
              },
            ),

            item(
              context,
              Icons.hotel,
              "Hospedaje",
              "Hoteles disponibles en la zona",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HospedajePantalla(
                      lat: widget.destinoLat,
                      lng: widget.destinoLng,
                      fechaInicio: widget.fechaInicio,
                      fechaFin: widget.fechaFin,
                      destino: widget.destino,
                    ),
                  ),
                );
              },
            ),

            item(
              context,
              Icons.backpack,
              "Maleta",
              "Lista recomendada para tu viaje",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MaletaPantalla(
                      idViaje: widget.idViaje,
                      destino: widget.destino,
                    ),
                  ),
                );
              },
            ),

            item(
              context,
              Icons.map,
              "Itinerario",
              "Planea tus actividades por día",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItinerarioPantalla(
                      idViaje: widget.idViaje,
                      fechaInicio: widget.fechaInicio,
                      fechaFin: widget.fechaFin,
                    ),
                  ),
                );
              },
            ),

            item(
              context,
              Icons.book,
              "Diario Personal",
              "Registra tus recuerdos",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListaDiarioPantalla(
                      idViaje: widget.idViaje,
                      fechaInicio: widget.fechaInicio,
                      fechaFin: widget.fechaFin,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            if (viajeTerminado)
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('viajes')
                            .doc(widget.idViaje)
                            .update({'realizado': true});

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Viaje realizado")),
                        );

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade300,
                      ),
                      child: const Text(
                        "Se realizó",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(width: 20),

                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('viajes')
                            .doc(widget.idViaje)
                            .update({'realizado': false});

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No se realizó")),
                        );

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade300,
                      ),
                      child: const Text(
                        "No se realizó",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

            if (!viajeTerminado)
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      mostrarDialogoCancelar(context, widget.idViaje);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text(
                      "Cancelar viaje",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget item(
    BuildContext context,
    IconData icono,
    String titulo,
    String subtitulo, {
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(icono, color: const Color(0xFF0066D2)),
          title: Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(subtitulo, style: GoogleFonts.poppins(fontSize: 14)),
          onTap: onTap,
        ),
      ),
    );
  }
}
