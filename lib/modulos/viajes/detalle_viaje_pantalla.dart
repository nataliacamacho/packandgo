import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import 'package:proyecto/modulos/viajes/apartados/hospedaje/hospedaje_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/maleta/maleta_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/diario_personal/lista_diario_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/transporte_pantalla.dart';
import 'package:proyecto/modulos/viajes/apartados/itinerario/itinerario_pantalla.dart';

import 'package:proyecto/nucleo/utilidades/formatear_destino.dart';
import 'package:proyecto/nucleo/servicios/generador_maleta_servicio.dart';

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
  final String tipoViaje;
  final List<dynamic> actividades;

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
    required this.tipoViaje,
    required this.actividades,
  });

  @override
  State<DetalleViajePantalla> createState() => _DetalleViajePantallaState();
}

class _DetalleViajePantallaState extends State<DetalleViajePantalla> {
  File? imagenLocal;
  String? imagenUrl;

  final ImagePicker picker = ImagePicker();

  final GeneradorMaletaServicio generador = GeneradorMaletaServicio();

  String climaEsperado = "Cargando clima...";

  @override
  void initState() {
    super.initState();
    cargarImagen();
    cargarClima();
  }

  // =========================
  // CARGAR CLIMA
  // =========================

  Future<void> cargarClima() async {
    final existe = await generador.destinoExiste(widget.destino);

    if (!existe) {
      setState(() {
        climaEsperado = "Destino no encontrado";
      });

      return;
    }

    final destinoNormalizado = widget.destino
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');

    final ciudadDoc = await FirebaseFirestore.instance
        .collection('ciudades')
        .doc(destinoNormalizado)
        .get();

    String clima = 'Templado';

    if (ciudadDoc.exists) {
      final data = ciudadDoc.data()!;

      final mes = widget.fechaInicio.month;

      if (mes == 12 || mes == 1 || mes == 2) {
        clima = data['climaInvierno'] ?? 'Frío';
      } else if (mes >= 3 && mes <= 5) {
        clima = data['climaPrimavera'] ?? 'Templado';
      } else if (mes >= 6 && mes <= 8) {
        clima = data['climaVerano'] ?? 'Calor';
      } else {
        clima = data['climaOtono'] ?? 'Templado';
      }
    }

    clima = clima[0].toUpperCase() + clima.substring(1);

    setState(() {
      climaEsperado = clima;
    });
  }

  // =========================
  // IMAGEN
  // =========================

  Future<void> seleccionarImagen() async {
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen == null) return;

    final file = File(imagen.path);

    setState(() {
      imagenLocal = file;
    });

    final url = await subirImagen(file);

    if (url != null) {
      setState(() {
        imagenUrl = url;
      });

      await FirebaseFirestore.instance
          .collection('viajes')
          .doc(widget.idViaje)
          .update({'imagen': url});
    }
  }

  Future<String?> subirImagen(File imagen) async {
    try {
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

  // =========================
  // VALIDACIONES
  // =========================

  bool viajeIniciado() {
    final hoy = DateTime.now();

    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);

    final inicio = DateTime(
      widget.fechaInicio.year,
      widget.fechaInicio.month,
      widget.fechaInicio.day,
    );

    return hoySinHora.isAtSameMomentAs(inicio) || hoySinHora.isAfter(inicio);
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

  // =========================
  // CANCELAR VIAJE
  // =========================

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

  // =========================
  // CARGAR IMAGEN
  // =========================

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

    bool puedePlanear() {
      final hoy = DateTime.now();

      final fin = DateTime(
        widget.fechaFin.year,
        widget.fechaFin.month,
        widget.fechaFin.day,
      );

      return hoy.isBefore(fin) || hoy.isAtSameMomentAs(fin);
    }

    bool viajeIniciadoSistema() {
      final hoy = DateTime.now();

      final inicio = DateTime(
        widget.fechaInicio.year,
        widget.fechaInicio.month,
        widget.fechaInicio.day,
      );

      return hoy.isAfter(inicio) || hoy.isAtSameMomentAs(inicio);
    }

    return Scaffold(
      extendBodyBehindAppBar: false,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(260),

        child: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: const Color(0xFF0066D2),
          elevation: 0,

          iconTheme: const IconThemeData(color: Colors.white),

          flexibleSpace: Stack(
            fit: StackFit.expand,

            children: [
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

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,

                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.7),
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
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 10),

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),

              child: Container(
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        const Icon(Icons.place, color: Color(0xFF0066D2)),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            widget.destino,

                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,

                      children: [
                        infoChip(Icons.luggage, widget.tipoViaje),

                        infoChip(Icons.wb_sunny, climaEsperado),

                        infoChip(
                          Icons.calendar_month,
                          "${widget.fechaFin.difference(widget.fechaInicio).inDays + 1} días",
                        ),
                      ],
                    ),

                    if (widget.actividades.isNotEmpty) ...[
                      const SizedBox(height: 18),

                      Text(
                        "Actividades",

                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,

                        children: widget.actividades.map((actividad) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),

                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF3FF),
                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: Text(
                              actividad.toString(),

                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF0066D2),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    if (widget.descripcion.isNotEmpty) ...[
                      const SizedBox(height: 18),

                      Text(
                        "Descripción",

                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        widget.descripcion,

                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            item(
              context,
              Icons.directions_car,
              "Transporte",
              "Opciones para llegar al destino",

              onTap: () {
                if (!puedePlanear()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "El viaje ya terminó, no se puede modificar planificación.",
                      ),
                    ),
                  );

                  return;
                }

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
                if (!puedePlanear()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Las funciones del viaje estarán disponibles cuando inicie el viaje.",
                      ),
                    ),
                  );

                  return;
                }

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
                if (!puedePlanear()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Las funciones del viaje estarán disponibles cuando inicie el viaje.",
                      ),
                    ),
                  );

                  return;
                }

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
                if (!puedePlanear()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Las funciones del viaje estarán disponibles cuando inicie el viaje.",
                      ),
                    ),
                  );

                  return;
                }

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
                if (!viajeIniciadoSistema()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "El diario personal estará disponible cuando inicie el viaje.",
                      ),
                    ),
                  );

                  return;
                }

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

  Widget infoChip(IconData icono, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(14),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icono, size: 18, color: const Color(0xFF0066D2)),

          const SizedBox(width: 8),

          Text(
            texto,

            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
