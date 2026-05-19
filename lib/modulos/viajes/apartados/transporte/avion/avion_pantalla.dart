import 'package:flutter/material.dart';
import 'package:proyecto/nucleo/servicios/servicio_avion.dart';
import 'package:proyecto/nucleo/servicios/ubicacion_servicio.dart';
import 'modelo_ruta_avion.dart';

class PantallaAvion extends StatefulWidget {
  final String destino;
  final String origen;

  const PantallaAvion({super.key, required this.destino, required this.origen});

  @override
  State<PantallaAvion> createState() => _PantallaAvionState();
}

class _PantallaAvionState extends State<PantallaAvion> {
  final servicio = ServicioAvion();

  List<RutaAvion> rutas = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    setState(() {
      loading = true;
      error = null;
    });

    String origen = widget.origen;

    if (origen.isEmpty) {
      final ubicacion = UbicacionServicio();
      origen = await ubicacion.obtenerCiudadActual() ?? '';
    }

    if (origen.isEmpty) {
      setState(() {
        error = "No se pudo obtener ubicación";
        loading = false;
      });
      return;
    }

    final result = await servicio.obtenerRutas(
      origen: origen,
      destino: widget.destino,
    );

    if (result.isEmpty) {
      setState(() {
        error = "No hay vuelos disponibles";
        loading = false;
      });
      return;
    }

    setState(() {
      rutas = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 50,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: const BoxDecoration(color: Color(0xFFF6A230)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Center(
                    child: Text(
                      "Ruta en Avión",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Información estimada",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.destino,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: Colors.orange.shade100,
                  child: const Text(
                    "⚠️ Información estimada basada en aeropuertos cercanos",
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: rutas.length,
                    itemBuilder: (_, index) {
                      final r = rutas[index];

                      return Padding(
                        padding: const EdgeInsets.all(10),
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
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${r.origen} → ${r.destino}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(r.aeropuertoOrigen),
                                Text(r.aeropuertoDestino),

                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16),
                                    const SizedBox(width: 5),
                                    Text(r.duracion),
                                  ],
                                ),

                                Text("\$${r.precio}"),

                                const SizedBox(height: 8),

                                const Text("Aerolíneas:"),
                                ...r.aerolineas.map((a) => Text("• $a")),

                                const SizedBox(height: 8),

                                const Text("Horarios:"),
                                ...r.horarios.map((h) => Text("• $h")),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
