import 'package:flutter/material.dart';
// 🔥 Asegúrate de que estas dos rutas apunten correctamente a tus archivos:
import 'package:proyecto/nucleo/servicios/itinerario_servicio.dart'; 
import 'package:proyecto/modulos/viajes/apartados/diario_personal/diario_pantalla.dart';
class ListaDiarioPantalla extends StatefulWidget {
  final String idViaje;
  final DateTime fechaInicio;
  final DateTime fechaFin;

  const ListaDiarioPantalla({
    super.key,
    required this.idViaje,
    required this.fechaInicio,
    required this.fechaFin,
  });

  @override
  State<ListaDiarioPantalla> createState() => _ListaDiarioPantallaState();
}

class _ListaDiarioPantallaState extends State<ListaDiarioPantalla> {
  late List<DateTime> diasDelViaje;

  @override
  void initState() {
    super.initState();
    // ¡Reciclamos tu excelente función del itinerario!
    diasDelViaje = ItinerarioServicio.generarListaDias(
        widget.fechaInicio, widget.fechaFin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Diario del Viaje"),
        backgroundColor: const Color(0xFF0066D2),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: diasDelViaje.length,
        itemBuilder: (context, index) {
          DateTime dia = diasDelViaje[index];
          String fechaStr = "${dia.day}/${dia.month}/${dia.year}";

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE6F0FA), // Un azul clarito de fondo
                child: Icon(Icons.book, color: Color(0xFF0066D2)),
              ),
              title: Text(
                "Día ${index + 1}: $fechaStr",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Text("Toca para escribir o ver tus recuerdos"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                // Aquí es donde abrimos tu editor del diario y le pasamos el día exacto
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DiarioPantalla(
                      idViaje: widget.idViaje,
                      dia: dia, 
                      fechaInicio: widget.fechaInicio,
                      fechaFin: widget.fechaFin,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}