import 'package:flutter/material.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/autobus/modelo_ruta_autobus.dart';
import 'package:proyecto/nucleo/servicios/servicio_autobus.dart';
import 'package:proyecto/nucleo/servicios/ubicacion_servicio.dart';

class PantallaAutobus extends StatefulWidget {
  final String destino;
  final double destinoLat;
  final double destinoLng;
  final String origen;

  const PantallaAutobus({
    super.key,
    required this.destino,
    required this.destinoLat,
    required this.destinoLng,
    required this.origen,
  });

  @override
  State<PantallaAutobus> createState() => _PantallaAutobusState();
}

class _PantallaAutobusState extends State<PantallaAutobus> {
  final servicio = ServicioAutobus();
  List<RutaAutobus> rutas = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    try {
      String? ciudadOrigen = widget.origen;
      if (ciudadOrigen.isEmpty) {
        ciudadOrigen = await UbicacionServicio().obtenerCiudadActual();
      }

      if (ciudadOrigen == null || ciudadOrigen.isEmpty) {
        if (!mounted) return;
        setState(() {
          error = "No se pudo obtener la ubicación.";
          loading = false;
        });
        return;
      }

      final rutasCalculadas = await servicio.obtenerRutas(
        origen: ciudadOrigen,
        destino: widget.destino,
      );

      if (!mounted) return;
      setState(() {
        rutas = rutasCalculadas;
        error = rutasCalculadas.isEmpty
            ? "No se encontraron rutas disponibles."
            : null;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "Ocurrió un error al obtener las rutas.";
        loading = false;
      });
    }
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
                      "Ruta en Autobús",
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
                    "⚠️ Los precios y horarios son estimados y pueden variar.",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: rutas.length,
                    itemBuilder: (_, index) {
                      final r = rutas[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Encabezado con clase
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${r.origen} → ${r.destino}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF6A230),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        r.clase,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Tabla
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _col(
                                        Icons.access_time,
                                        "Duración",
                                        r.duracion,
                                      ),
                                      _col(
                                        Icons.attach_money,
                                        "Precio",
                                        "\$${r.precio} MXN",
                                      ),
                                      _col(
                                        Icons.schedule,
                                        "Horario",
                                        r.horarios.first,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Estimación basada en distancia real",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
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

  Widget _col(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFF6A230)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
