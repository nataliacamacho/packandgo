import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proyecto/modulos/viajes/apartados/hospedaje/modelo_hospedaje.dart';
import 'package:proyecto/nucleo/utilidades/formatear_destino.dart';
import 'package:proyecto/nucleo/servicios/hospedaje_servicio.dart';

class HospedajePantalla extends StatefulWidget {
  final double lat;
  final double lng;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String destino;

  const HospedajePantalla({
    super.key,
    required this.lat,
    required this.lng,
    required this.fechaInicio,
    required this.fechaFin,
    required this.destino,
  });

  @override
  State<HospedajePantalla> createState() => _HospedajePantallaState();
}

class _HospedajePantallaState extends State<HospedajePantalla> {
  final servicio = HospedajeServicio();

  bool cargando = true;
  String? error;
  List<Hospedaje> hospedajes = [];

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final data = await servicio.obtenerHospedajes(destino: widget.destino);

      setState(() {
        hospedajes = data;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = "No se pudieron cargar los hospedajes";
        cargando = false;
      });
    }
  }

  String _formatearFecha(DateTime fecha) {
    const meses = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return '${fecha.day} ${meses[fecha.month]} ${fecha.year}';
  }

  Future<void> _abrirBooking(String hotel, String destino) async {
    final query = Uri.encodeComponent("$hotel $destino México");

    final url = "https://www.booking.com/searchresults.html?ss=$query";

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
                      "Hospedaje",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Opciones para tu estadía",
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

      body: Column(
        children: [
          Container(
            color: const Color(0xFFFFF3E0),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Text(
              '${_formatearFecha(widget.fechaInicio)} → ${_formatearFecha(widget.fechaFin)}',
            ),
          ),

          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(child: Text(error!))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: hospedajes.length,
                    itemBuilder: (context, i) {
                      final h = hospedajes[i];

                      return Card(
                        color: Colors.white,
                        elevation: 5,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  h.imagen,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.hotel),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(h.ubicacion),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () => _abrirBooking(
                                        h.nombre,
                                        widget.destino,
                                      ),
                                      child: const Text(
                                        "Reservar en Booking",
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
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
    );
  }
}
