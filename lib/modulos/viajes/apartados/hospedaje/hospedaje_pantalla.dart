import 'package:flutter/material.dart';
import 'package:proyecto/modulos/viajes/apartados/hospedaje/modelo_hospedaje.dart';
import 'package:proyecto/nucleo/utilidades/formatear_destino.dart';
import 'package:url_launcher/url_launcher.dart';
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
    print(
      '🏨 lat=${widget.lat}, lng=${widget.lng}, destino=${normalizarDestino(FormateadorDestino.formatear(widget.destino))}',
    );
    cargar();
  }

  static const Map<String, String> _aliases = {
    'gdl': 'Guadalajara',
    'mty': 'Monterrey',
    'cdmx': 'Ciudad de México',
    'mex': 'Ciudad de México',
    'cun': 'Cancún',
    'tij': 'Tijuana',
    'pue': 'Puebla',
    'qro': 'Querétaro',
    'oax': 'Oaxaca',
    'mid': 'Mérida',
  };

  String normalizarDestino(String destino) {
    final lower = destino.toLowerCase().trim();
    return _aliases[lower] ?? destino;
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      final data = await servicio.obtenerHospedajes(
        lat: widget.lat,
        lng: widget.lng,
      );
      setState(() {
        hospedajes = data;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudieron cargar los hospedajes';
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

  Future<void> _abrirLink(String urlBase) async {
    final destino = normalizarDestino(
      FormateadorDestino.formatear(widget.destino),
    );

    final checkin =
        "${widget.fechaInicio.year}-${widget.fechaInicio.month.toString().padLeft(2, '0')}-${widget.fechaInicio.day.toString().padLeft(2, '0')}";

    final checkout =
        "${widget.fechaFin.year}-${widget.fechaFin.month.toString().padLeft(2, '0')}-${widget.fechaFin.day.toString().padLeft(2, '0')}";

    final urlFinal =
        "$urlBase&ss=${Uri.encodeComponent(destino)}"
        "&checkin=$checkin"
        "&checkout=$checkout"
        "&group_adults=2"
        "&no_rooms=1"
        "&group_children=0";

    final uri = Uri.parse(urlFinal);

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
          _buildFechas(),
          Expanded(child: _buildContenido()),
        ],
      ),
    );
  }

  Widget _buildFechas() {
    return Container(
      color: const Color(0xFFFFF3E0),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Color(0xFFF6A230)),
          const SizedBox(width: 6),
          Text(
            '${_formatearFecha(widget.fechaInicio)}  →  ${_formatearFecha(widget.fechaFin)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (cargando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFF6A230)),
            SizedBox(height: 12),
            Text('Buscando hospedajes...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: cargar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF6A230),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (hospedajes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No hay hospedajes disponibles\nen esta zona',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0066D2),
      onRefresh: cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: hospedajes.length,
        itemBuilder: (context, index) => _buildCard(hospedajes[index]),
      ),
    );
  }

  Widget _buildCard(Hospedaje h) {
    return Card(
      color: Color.fromARGB(255, 255, 255, 255),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Imagen con ícono de hotel de respaldo
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                h.imagen,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.hotel),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    h.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Disponibilidad
                  _buildInfoRow(
                    Icons.check_circle_outline,
                    'Buscar este hospedaje en Booking (puede variar ligeramente)',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      // ✅ Link directo al hotel exacto usando placeId de Google
                      final uri = Uri.parse(
                        "https://www.google.com/maps/search/?api=1"
                        "&query=${Uri.encodeComponent(h.nombre)}"
                        "&query_place_id=${h.placeId}",
                      );

                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.open_in_new, size: 13, color: Colors.blue),
                        SizedBox(width: 3),
                        Text(
                          'Ver en Google Maps',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String texto, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 13, color: color ?? Colors.grey),
        ),

        const SizedBox(width: 5),

        Expanded(
          child: Text(
            texto,
            style: TextStyle(fontSize: 11.5, color: color ?? Colors.grey),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
