import 'package:flutter/material.dart';
import 'package:proyecto/nucleo/servicios/ubicacion_servicio.dart';

class RutaMixtaPantalla extends StatefulWidget {
  final double destinoLat;
  final double destinoLng;

  const RutaMixtaPantalla({
    super.key,
    required this.destinoLat,
    required this.destinoLng, required String origen, required String destinoNombre,
  });

  @override
  State<RutaMixtaPantalla> createState() => _RutaMixtaPantallaState();
}

class _RutaMixtaPantallaState extends State<RutaMixtaPantalla> {
  final ubicacionServicio = UbicacionServicio();

  bool cargando = true;
  String mensaje = "";
  List<String> pasos = [];

  @override
  void initState() {
    super.initState();
    calcularRuta();
  }

  Future<void> calcularRuta() async {
    final origen = await ubicacionServicio.obtenerCoordenadas();

    if (origen == null) {
      setState(() {
        mensaje = "No se pudo obtener tu ubicación";
        cargando = false;
      });
      return;
    }

    final distanciaKm = ubicacionServicio.calcularDistanciaEnKm(
      origenLat: origen['lat']!,
      origenLng: origen['lng']!,
      destinoLat: widget.destinoLat,
      destinoLng: widget.destinoLng,
    );

    // 🔥 LÓGICA DE RUTA MIXTA
    if (distanciaKm <= 500) {
      pasos = ["🚗 Viaje directo en carro"];
    } else if (distanciaKm <= 1200) {
      pasos = [
        "🚌 Tomar autobús a ciudad cercana",
        "🚗 Traslado local en carro al destino",
      ];
    } else {
      pasos = ["✈️ Vuelo a ciudad principal", "🚗 Transporte local al destino"];
    }

    setState(() {
      mensaje = "Distancia: ${distanciaKm.toStringAsFixed(1)} km";
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ruta Mixta"),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mensaje, style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 20),

                  const Text(
                    "Recomendación de ruta:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  ...pasos.map((paso) => _itemPaso(paso)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _itemPaso(String texto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
        ],
      ),
      child: Text(texto, style: const TextStyle(fontSize: 16)),
    );
  }
}
