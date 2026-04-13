import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/compartidos/widgets/filtros_busqueda.dart';
import 'package:proyecto/modulos/viajes/detalle_viaje_pantalla.dart';
import 'package:proyecto/nucleo/servicios/viaje_servicio.dart';
import 'package:proyecto/nucleo/servicios/geocoding_servicio.dart';

class CrearViajePantalla extends StatefulWidget {
  const CrearViajePantalla({super.key});

  @override
  State<CrearViajePantalla> createState() => _CrearViajePantallaState();
}

class _CrearViajePantallaState extends State<CrearViajePantalla> {
  String? destinoSeleccionado;
  final descripcionController = TextEditingController();
  final geocoding = GeocodingServicio();

  DateTimeRange? rangofechas;
  DateTime? fechaInicio;
  DateTime? fechaFin;

  final viajeServicio = ViajeServicio();

  bool cargando = false; // 🔥 NUEVO

  @override
  void dispose() {
    descripcionController.dispose();
    super.dispose();
  }

  Future<void> seleccionarFecha() async {
    DateTimeRange? seleccion = await showDateRangePicker(
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

  Future<void> crearViaje() async {
    if (destinoSeleccionado == null ||
        fechaInicio == null ||
        fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona destino y fechas")),
      );
      return;
    }

    setState(() => cargando = true);

    try {
      // 🔥 GEOCODING
      final coords =
          await geocoding.obtenerCoordenadas(destinoSeleccionado!);

      if (!mounted) return;

      if (coords == null ||
          coords['lat'] == null ||
          coords['lng'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo obtener ubicación")),
        );
        setState(() => cargando = false);
        return;
      }

      final destinoLat = coords['lat']!;
      final destinoLng = coords['lng']!;

      // 🔥 FIRESTORE
      final idViaje = await viajeServicio.crearViaje(
        destino: destinoSeleccionado!,
        fechaInicio: fechaInicio!,
        fechaFin: fechaFin!,
        descripcion: descripcionController.text,
        lat: destinoLat,
        lng: destinoLng,
      );

      if (!mounted) return;

      // 🔥 NAVEGACIÓN
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleViajePantalla(
            nombre: destinoSeleccionado!,
            fechaInicio: fechaInicio!,
            fechaFin: fechaFin!,
            descripcion: descripcionController.text,
            idViaje: idViaje,
            destino: destinoSeleccionado!,
            destinoLat: destinoLat,
            destinoLng: destinoLng,
          ),
        ),
      );
    } catch (e) {
      print("ERROR CREAR VIAJE: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al crear el viaje")),
      );
    }

    if (mounted) {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("Pack&Go", style: GoogleFonts.poppins(fontSize: 32)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // 🔥 SCROLL (IMPORTANTE)
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),

                FiltrosBusqueda(
                  destinoSeleccionado: destinoSeleccionado,
                  tipoSeleccionado: null,
                  estiloSeleccionado: null,
                  precioSeleccionado: null,
                  onDestinoChanged: (v) {
                    setState(() {
                      destinoSeleccionado = v;
                    });
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

                Text("Elegir fecha",
                    style: GoogleFonts.poppins(fontSize: 16)),

                const SizedBox(height: 10),

                GestureDetector(
                  onTap: seleccionarFecha,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5D09E),
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

                const SizedBox(height: 10),

                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: "Descripción (opcional)",
                  ),
                ),

                const SizedBox(height: 40),

                Center(
                  child: SizedBox(
                    width: 180,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF6A230),
                      ),
                      onPressed: cargando ? null : crearViaje,

                      // 🔥 LOADING
                      child: cargando
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text(
                              "Crear viaje",
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}