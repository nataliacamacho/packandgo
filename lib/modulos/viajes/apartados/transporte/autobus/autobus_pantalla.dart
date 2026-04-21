import 'package:flutter/material.dart';
import 'package:proyecto/nucleo/servicios/servicio_autobus.dart';
import 'package:proyecto/nucleo/servicios/ubicacion_servicio.dart';
import 'package:proyecto/nucleo/utilidades/seed_autobus.dart';
import 'modelo_ruta_autobus.dart';

class PantallaAutobus extends StatefulWidget {
  final String destino;

  const PantallaAutobus({super.key, required this.destino, required double destinoLat, required double destinoLng, required String origen});

  @override
  State<PantallaAutobus> createState() => _PantallaAutobusState();
}

class _PantallaAutobusState extends State<PantallaAutobus> {
  final ServicioAutobus servicio = ServicioAutobus();

  List<RutaAutobus> rutas = [];
  bool loading = true;
  bool loadingSeed = false;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    setState(() {
      loading = true;
    });

    final ubicacionServicio = UbicacionServicio();

    final ciudadOrigenRaw = await ubicacionServicio.obtenerCiudadActual();

    print("🏙️ ORIGEN RAW: $ciudadOrigenRaw");

    if (ciudadOrigenRaw == null || ciudadOrigenRaw.trim().isEmpty) {
      setState(() {
        rutas = [];
        loading = false;
      });
      return;
    }

    final ciudadOrigen = servicio.normalizarTexto(ciudadOrigenRaw);

    print("🏙️ ORIGEN NORMALIZADO: $ciudadOrigen");

    final destinoNormalizado = servicio.normalizarTexto(widget.destino);

    final data = await servicio.obtenerRutaExacta(
      origen: ciudadOrigen,
      destino: destinoNormalizado,
    );

    final result = data.isNotEmpty
        ? data
        : await servicio.obtenerFallback(
            origen: ciudadOrigen,
            destino: destinoNormalizado,
          );

    setState(() {
      rutas = result;
      loading = false;
    });
  }

  // 🔥 SEED
  Future<void> ejecutarSeed() async {
    setState(() {
      loadingSeed = true;
    });

    try {
      final seed = SeedAutobus74();
      await seed.generar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Rutas generadas en Firebase")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }

    setState(() {
      loadingSeed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      "Rutas disponibles",
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

      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : rutas.isEmpty
                    ? const Center(child: Text("No hay rutas disponibles"))
                    : ListView.builder(
                        itemCount: rutas.length,
                        itemBuilder: (context, index) {
                          final r = rutas[index];

                          return Card(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            elevation: 4,
                            margin: const EdgeInsets.all(10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${r.origen} → ${r.destino}",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text("⏱ Duración: ${r.duracion}"),
                                  Text("💰 Precio: \$${r.precio}"),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Horarios:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ...r.horarios.map((h) => Text("• $h")),
                                  const SizedBox(height: 10),
                                  const Align(
                                    alignment: Alignment.centerRight,
                                    child: Icon(
                                      Icons.directions_bus,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
/*
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: loadingSeed ? null : ejecutarSeed,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: loadingSeed ? Colors.grey : Colors.red,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: const [
                    BoxShadow(blurRadius: 6, color: Colors.black26),
                  ],
                ),
                child: loadingSeed
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      )
                    : const Icon(
                        Icons.bolt,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
              ),
            ),
          ),
          */
        ],
      ),
    );
  }
}
