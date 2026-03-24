import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/compartidos/widgets/filtros_busqueda.dart';
import 'package:proyecto/modulos/viajes/detalle_viaje_pantalla.dart';
import 'package:proyecto/nucleo/servicios/viaje_servicio.dart';

class CrearViajePantalla extends StatefulWidget {
  const CrearViajePantalla({super.key});

  @override
  State<CrearViajePantalla> createState() => _CrearViajePantallaState();
}

class _CrearViajePantallaState extends State<CrearViajePantalla> {
  String? destinoSeleccionado;
  final descripcionController = TextEditingController();
  DateTimeRange? rangofechas;
  DateTime? fechaInicio;
  DateTime? fechaFin;

  final viajeServicio = ViajeServicio();

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

    final idViaje = await viajeServicio.crearViaje(
      destino: destinoSeleccionado!,
      fechaInicio: fechaInicio!,
      fechaFin: fechaFin!,
      descripcion: descripcionController.text,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleViajePantalla(
          idViaje: idViaje,
          nombre: destinoSeleccionado!,
          fechaInicio: fechaInicio!,
          fechaFin: fechaFin!,
          descripcion: descripcionController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("Pack&Go", style: GoogleFonts.poppins(fontSize: 36)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
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

              Text("Elegir fecha", style: GoogleFonts.poppins(fontSize: 16)),

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
                  width: 150,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF6A230),
                    ),
                    onPressed: crearViaje,
                    child: const Text(
                      "Crear viaje",
                      style: TextStyle(color: Colors.white),
                    ),
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
