import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proyecto/modulos/viajes/apartados/hospedaje/modelo_hospedaje.dart';
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
  String _ordenActual = 'popularidad';

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
      final data = await servicio.obtenerHospedajes(
        destino: widget.destino,
        fechaInicio: widget.fechaInicio,
        fechaFin: widget.fechaFin,
      );

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

  List<Hospedaje> _ordenarHospedajes() {
    final lista = List<Hospedaje>.from(hospedajes);
    switch (_ordenActual) {
      case 'proximidad':
        lista.sort((a, b) {
          final dA = _distancia(a.lat, a.lng);
          final dB = _distancia(b.lat, b.lng);
          return dA.compareTo(dB);
        });
        break;
      case 'popularidad':
      default:
        lista.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return lista;
  }

  double _distancia(double lat, double lng) {
    final dlat = lat - widget.lat;
    final dlng = lng - widget.lng;
    return dlat * dlat + dlng * dlng; // distancia euclidiana simple
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Text(
                  'Ordenar por: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  dropdownColor: const Color.fromARGB(255, 255, 255, 255),
                  value: _ordenActual,
                  items: const [
                    DropdownMenuItem(
                      value: 'popularidad',
                      child: Text('Popularidad'),
                    ),
                    DropdownMenuItem(
                      value: 'proximidad',
                      child: Text('Proximidad'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _ordenActual = val);
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(child: Text(error!))
                : hospedajes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.hotel, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay hospedajes disponibles\npara este destino o fechas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Sugerencias:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.calendar_month),
                            label: const Text('Modificar las fechas del viaje'),
                          ),
                          TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.explore),
                            label: const Text('Explorar destinos cercanos'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: (() {
                      return _ordenarHospedajes().length;
                    })(),
                    itemBuilder: (context, i) {
                      final h = _ordenarHospedajes()[i];

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

                                    Row(
                                      children: [
                                        ...List.generate(
                                          h.precio.toInt().clamp(1, 4),
                                          (_) => const Icon(
                                            Icons.attach_money,
                                            size: 14,
                                            color: Color(0xFFF6A230),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Verificar precio en Booking',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          h.disponible
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 14,
                                          color: h.disponible
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          h.disponible
                                              ? 'Disponible'
                                              : 'No disponible',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: h.disponible
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
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
