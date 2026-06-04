import 'package:flutter/material.dart';
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
    diasDelViaje = ItinerarioServicio.generarListaDias(
      widget.fechaInicio,
      widget.fechaFin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(color: Color(0xFFF6A230)),
              child: const SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Diario Personal",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Guarda los momentos de tu viaje",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),

      ///LISTA DE DÍAS
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: diasDelViaje.length,
        itemBuilder: (context, index) {
          DateTime dia = diasDelViaje[index];
          String fechaStr = "${dia.day}/${dia.month}/${dia.year}";

          return Card(
            elevation: 1.5,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),

              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(182, 255, 255, 255),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book, color: Color(0xFF0066D2)),
              ),

              title: Text(
                "Día ${index + 1}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              subtitle: Text(
                fechaStr,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),

              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),

              onTap: () {
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
