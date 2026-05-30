import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto/compartidos/widgets/filtros_busqueda.dart';
import 'package:proyecto/modulos/viajes/detalle_viaje_pantalla.dart';
import 'package:proyecto/nucleo/servicios/storage_servicio.dart';
import 'package:proyecto/nucleo/servicios/viaje_servicio.dart';
import 'package:proyecto/nucleo/servicios/geocoding_servicio.dart';
import 'package:proyecto/nucleo/utilidades/formatear_destino.dart';

class CrearViajePantalla extends StatefulWidget {
  const CrearViajePantalla({super.key});

  @override
  State<CrearViajePantalla> createState() => _CrearViajePantallaState();
}

class _CrearViajePantallaState extends State<CrearViajePantalla> {
  String? destinoSeleccionado;
  String? tipoViajeSeleccionado;

  final descripcionController = TextEditingController();
  final geocoding = GeocodingServicio();
  final viajeServicio = ViajeServicio();
  File? imagenSeleccionada;
  final ImagePicker picker = ImagePicker();
  final StorageServicio storageServicio = StorageServicio();

  DateTimeRange? rangofechas;
  DateTime? fechaInicio;
  DateTime? fechaFin;

  bool cargando = false;

  List<String> actividadesSeleccionadas = [];
  final List<String> tiposViaje = [
    'Aventura',
    'Relajación',
    'Familiar',
    'Negocios',
    'Romántico',
    'Cultural',
  ];

  @override
  void dispose() {
    descripcionController.dispose();
    super.dispose();
  }

  void limpiarFormulario() {
    setState(() {
      destinoSeleccionado = null;
      tipoViajeSeleccionado = null;
      descripcionController.clear();

      rangofechas = null;

      fechaInicio = null;

      fechaFin = null;

      actividadesSeleccionadas.clear();

      imagenSeleccionada = null;
    });
  }

  static const Map<String, String> _aliases = {
    'gdl': 'Guadalajara',
    'mty': 'Monterrey',
    'cdmx': 'Ciudad de México',
    'mex': 'Ciudad de México',
    'cun': 'Cancún',
    'tij': 'Tijuana',
    'pue': 'Puebla',
    'qro': 'Querétaro',
    'oax': 'Oaxaca',
    'mid': 'Mérida',
  };

  final List<String> actividadesDisponibles = [
    'senderismo',
    'natacion',
    'camping',
    'playa',
    'esqui',
    'negocios',
    'fotografia',
    'ciclismo',
    'gym',
    'pesca',
    'moto',
    'buceo',
    'festival',
    'excursion',
    'aventura',
  ];

  String normalizarDestino(String destino) {
    final lower = destino.toLowerCase().trim();
    return _aliases[lower] ?? destino;
  }

  Future<void> seleccionarFecha() async {
    final seleccion = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDateRange: rangofechas,
    );

    if (seleccion != null) {
      setState(() {
        rangofechas = seleccion;
        fechaInicio = seleccion.start;
        fechaFin = seleccion.end;
      });
    }
  }

  Future<void> seleccionarImagen() async {
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      setState(() {
        imagenSeleccionada = File(imagen.path);
      });
    }
  }

  Future<void> crearViaje() async {
    if (destinoSeleccionado == null ||
        tipoViajeSeleccionado == null ||
        fechaInicio == null ||
        fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona destino y fechas")),
      );
      return;
    }

    setState(() => cargando = true);
    try {
      final destinoNormalizado = normalizarDestino(destinoSeleccionado!);
      final coords = await geocoding.obtenerCoordenadas(destinoNormalizado);

      if (!mounted) return;

      if (coords == null || coords['lat'] == null || coords['lng'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo obtener ubicación")),
        );
        setState(() => cargando = false);
        return;
      }

      final destinoLat = coords['lat']!;
      final destinoLng = coords['lng']!;

      // 1. Primero formatear
      final destinoFormateado = FormateadorDestino.formatear(
        destinoNormalizado,
      );

      // 2. Luego buscar el nombre bonito en Firestore
      String nombreMostrar = destinoFormateado;
      final ciudadDoc = await FirebaseFirestore.instance
          .collection('ciudades')
          .doc(destinoNormalizado.toLowerCase().trim())
          .get();

      if (ciudadDoc.exists && ciudadDoc.data()?['nombre'] != null) {
        nombreMostrar = ciudadDoc.data()!['nombre'];
      }

      // 3. Crear el viaje con el nombre correcto
      final idViaje = await viajeServicio.crearViaje(
        destino: nombreMostrar, // 👈 cambiado
        fechaInicio: fechaInicio!,
        fechaFin: fechaFin!,
        descripcion: descripcionController.text,
        actividades: actividadesSeleccionadas,
        lat: destinoLat,
        lng: destinoLng,
        origen: '',
        usuarioId: FirebaseAuth.instance.currentUser!.uid,
        tipoViaje: tipoViajeSeleccionado!,
      );

      String? imagenUrl;

      if (imagenSeleccionada != null) {
        imagenUrl = await storageServicio.subirImagenViaje(
          imagenSeleccionada!,
          idViaje,
        );
        await FirebaseFirestore.instance
            .collection('viajes')
            .doc(idViaje)
            .update({'imagen': imagenUrl});
      }

      if (!mounted) return;

      final inicioTemp = fechaInicio!;
      final finTemp = fechaFin!;
      final descripcionTemp = descripcionController.text;
      final tipoViajeTemp = tipoViajeSeleccionado!;
      final actividadesTemp = List<String>.from(actividadesSeleccionadas);

      limpiarFormulario();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleViajePantalla(
            nombre: nombreMostrar, // 👈 cambiado
            destino: nombreMostrar, // 👈 cambiado
            fechaInicio: inicioTemp,
            fechaFin: finTemp,
            descripcion: descripcionTemp,
            idViaje: idViaje,
            destinoLat: destinoLat,
            destinoLng: destinoLng,
            origen: '',
            tipoViaje: tipoViajeTemp,
            actividades: actividadesTemp,
          ),
        ),
      );
    } catch (e) {
      debugPrint("ERROR CREAR VIAJE: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al crear el viaje")));
    }
    if (mounted) {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        surfaceTintColor: const Color.fromARGB(255, 255, 255, 255),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: Text("Pack&Go", style: GoogleFonts.poppins(fontSize: 32)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),

              Text("Elegir Destino", style: GoogleFonts.poppins(fontSize: 16)),

              const SizedBox(height: 10),

              FiltrosBusqueda(
                destinoSeleccionado: destinoSeleccionado,
                tipoSeleccionado: null,
                estiloSeleccionado: null,
                precioSeleccionado: null,
                onDestinoChanged: (v) {
                  setState(() => destinoSeleccionado = v);
                },
                onTipoChanged: (_) {},
                onEstiloChanged: (_) {},
                onPrecioChanged: (_) {},
                mostrarDestino: true,
                mostrarTipo: false,
                mostrarEstilo: false,
                mostrarPrecio: false,
              ),
              const SizedBox(height: 20),

              Text("Tipo de viaje", style: GoogleFonts.poppins(fontSize: 16)),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                dropdownColor: const Color.fromARGB(255, 255, 255, 255),
                value: tipoViajeSeleccionado,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFDF6EC),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF6A230)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF0066D2),
                      width: 2,
                    ),
                  ),
                ),
                hint: const Text("Selecciona un tipo"),
                items: tiposViaje.map((tipo) {
                  return DropdownMenuItem(value: tipo, child: Text(tipo));
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    tipoViajeSeleccionado = valor;
                  });
                },
              ),

              const SizedBox(height: 20),

              Text("Elegir fecha", style: GoogleFonts.poppins(fontSize: 16)),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: seleccionarFecha,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF6EC),
                    border: Border.all(color: const Color(0xFFF6A230)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    rangofechas == null
                        ? "dd / mm / aaaa"
                        : "${rangofechas!.start.day}/${rangofechas!.start.month}/${rangofechas!.start.year} - ${rangofechas!.end.day}/${rangofechas!.end.month}/${rangofechas!.end.year}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Descripción (opcional)",
                style: GoogleFonts.poppins(fontSize: 16),
              ),

              TextField(
                controller: descripcionController,
                cursorColor: const Color(0xFF0066D2),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFDF6EC),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF6A230)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF0066D2),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Text(
                "Actividades",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: actividadesDisponibles.map((actividad) {
                  final seleccionada = actividadesSeleccionadas.contains(
                    actividad,
                  );

                  return FilterChip(
                    label: Text(actividad),
                    selected: seleccionada,

                    onSelected: (valor) {
                      setState(() {
                        if (valor) {
                          actividadesSeleccionadas.add(actividad);
                        } else {
                          actividadesSeleccionadas.remove(actividad);
                        }
                      });
                    },
                    backgroundColor: const Color(0xFFFDF6EC),
                    selectedColor: const Color(0xFFF6A230),
                    side: BorderSide(
                      color: seleccionada
                          ? const Color(0xFFF6A230)
                          : Colors.orange.shade200,
                    ),

                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              Center(
                child: SizedBox(
                  width: 180,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF6A230),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    onPressed: cargando ? null : crearViaje,
                    child: cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Crear viaje",
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
