import 'package:flutter/material.dart';
import 'package:proyecto/modulos/busqueda/busqueda_pantalla.dart';
import 'package:proyecto/nucleo/servicios/itinerario_servicio.dart';

class ItinerarioPantalla extends StatefulWidget {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String idViaje;

  const ItinerarioPantalla({
    super.key,
    required this.fechaInicio,
    required this.fechaFin,
    required this.idViaje,
  });

  @override
  State<ItinerarioPantalla> createState() => _ItinerarioPantallaState();
}

class _ItinerarioPantallaState extends State<ItinerarioPantalla> {
  late List<DateTime> diasDelViaje;
  // Mapa para guardar los lugares de cada día: { '2026-04-17': [lugar1, lugar2] }
  Map<String, List<Map<String, dynamic>>> itinerarioPorDia = {};

  @override
  void initState() {
    super.initState();
    diasDelViaje = ItinerarioServicio.generarListaDias(
        widget.fechaInicio, widget.fechaFin);
  }

  void agregarLugarADia(DateTime dia, Map<String, dynamic> lugar) {
    String fechaKey = dia.toString().split(' ')[0];
    itinerarioPorDia.putIfAbsent(fechaKey, () => []);

    // Regla del DER: Máximo 5 lugares
    if (itinerarioPorDia[fechaKey]!.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Máximo 5 lugares por día")),
      );
      return;
    }

    // Validación de horario
    bool estaAbierto = ItinerarioServicio.verificarApertura(dia, lugar['hours']);

    if (estaAbierto) {
      setState(() {
        itinerarioPorDia[fechaKey]!.add(lugar);
      });
    } else {
      ItinerarioServicio.mostrarAlertaCerrado(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Itinerario")),
      
      body: ListView.builder(
        itemCount: diasDelViaje.length,
        itemBuilder: (context, index) {
          DateTime dia = diasDelViaje[index];
          String fechaStr = "${dia.day}/${dia.month}/${dia.year}";
          String fechaKey = dia.toString().split(' ')[0]; // Clave para buscar en el mapa

          return ExpansionTile(
            title: Text("Día ${index + 1}: $fechaStr"),
            children: [
              // 1. Mostrar los lugares que YA agregaste a este día
              ...?itinerarioPorDia[fechaKey]?.map((lugar) {
                return ListTile(
                  leading: const Icon(Icons.place, color: Colors.blue),
                  title: Text(lugar['name'] ?? 'Lugar'),
                  subtitle: Text(lugar['categoriaPrincipal'] ?? ''),
                );
              }),

              // 2. El botón para ir a buscar un nuevo lugar
              ListTile(
                leading: const Icon(Icons.add_location_alt),
                title: const Text("Agregar lugar"),
                onTap: () async {
                  final lugarSeleccionado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BusquedaPantalla(esSeleccion: true),
                    ),
                  );

                  // Si el usuario eligió un lugar (no dio atrás), lo validamos y agregamos
                  if (lugarSeleccionado != null) {
                    agregarLugarADia(dia, lugarSeleccionado);
                  }
            },
          ), // Cierra ListTile
        ], // Cierra children del ExpansionTile
      ); // Cierra ExpansionTile
    }, // Cierra itemBuilder
  ), 
      
      // El botón flotante va a la misma altura que el body (dentro del Scaffold)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Llamamos al servicio para guardar
          await ItinerarioServicio.guardarItinerarioEnFirebase(
            widget.idViaje, 
            itinerarioPorDia
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("¡Itinerario guardado en la nube!")),
            );
          }
        },
        icon: const Icon(Icons.cloud_upload),
        label: const Text("Guardar Itinerario"),
      ),
    ); 
  }
}