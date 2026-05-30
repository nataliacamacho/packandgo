import 'package:flutter/material.dart';
import 'package:proyecto/nucleo/servicios/servicio_avion.dart';
import 'package:proyecto/nucleo/servicios/ubicacion_servicio.dart';
import 'modelo_ruta_avion.dart';

class PantallaAvion extends StatefulWidget {
  final String destino;
  final String origen;

  const PantallaAvion(
      {super.key, required this.destino, required this.origen});

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
      origen = await UbicacionServicio().obtenerCiudadActual() ?? '';
    }

    if (origen.isEmpty) {
      setState(() {
        error = "No se pudo obtener ubicación";
        loading = false;
      });
      return;
    }

    final result =
        await servicio.obtenerRutas(origen: origen, destino: widget.destino);

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
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.only(
                  top: 50, left: 16, right: 16, bottom: 16),
              decoration: const BoxDecoration(color: Color(0xFFF6A230)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Center(
                    child: Text("Ruta en Avión",
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                  const Center(
                    child: Text("Información estimada",
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.destino,
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9))),
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
                        "⚠️ Los horarios, precios y aerolíneas mostrados son estimaciones basadas en distancia real. Para reservar, verifica disponibilidad y tarifas directamente en el sitio oficial de cada aerolínea.",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    // Encabezado de tabla (RQF76)
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6A230),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                              child: Text("Aerolínea",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))),
                          Expanded(
                              child: Text("Horario",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))),
                          Expanded(
                              child: Text("Duración",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))),
                          Expanded(
                              child: Text("Precio",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: rutas.length,
                        itemBuilder: (_, index) {
                          final r = rutas[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Fila de tabla
                                    Row(
                                      children: [
                                        Expanded(
                                            child: Text(
                                                r.aerolineas.first,
                                                style: const TextStyle(
                                                    fontSize: 12))),
                                        Expanded(
                                            child: Text(r.horarios.first,
                                                style: const TextStyle(
                                                    fontSize: 12))),
                                        Expanded(
                                            child: Text(r.duracion,
                                                style: const TextStyle(
                                                    fontSize: 12))),
                                        Expanded(
                                          child: Text(
                                            "\$${r.precio}",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: Color(0xFF0066D2)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "${r.aeropuertoOrigen} → ${r.aeropuertoDestino}",
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey),
                                    ),
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