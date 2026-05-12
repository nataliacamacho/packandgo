import 'package:flutter/material.dart';
import 'package:proyecto/nucleo/servicios/ubicacion_servicio.dart';
import 'package:proyecto/modelos/ciudad_nodo.dart';
import 'package:proyecto/modelos/segmento_ruta.dart';

class RutaMixtaPantalla extends StatefulWidget {
  final double destinoLat;
  final double destinoLng;
  final String destinoNombre;
  final String origen;

  const RutaMixtaPantalla({
    super.key,
    required this.destinoLat,
    required this.destinoLng,
    required this.destinoNombre,
    required this.origen,
  });

  @override
  State<RutaMixtaPantalla> createState() => _RutaMixtaPantallaState();
}

class Arista {
  final CiudadNodo origen;
  final CiudadNodo destino;
  final String tipo;
  final double distancia;
  final double tiempo;
  final double costo;

  Arista({
    required this.origen,
    required this.destino,
    required this.tipo,
    required this.distancia,
    required this.tiempo,
    required this.costo,
  });
}

class _RutaMixtaPantallaState extends State<RutaMixtaPantalla> {
  final ubicacionServicio = UbicacionServicio();

  bool cargando = true;
  String mensaje = "";
  String? nombreOrigenActual;

  List<SegmentoRuta> segmentos = [];
  double costoTotal = 0;
  double tiempoTotal = 0;

  final List<CiudadNodo> ciudadesNodoBase = [
    CiudadNodo(nombre: "Ciudad de México", lat: 19.4326, lng: -99.1332),
    CiudadNodo(nombre: "Guadalajara", lat: 20.6597, lng: -103.3496),
    CiudadNodo(nombre: "Monterrey", lat: 25.6866, lng: -100.3161),
    CiudadNodo(nombre: "Cancún", lat: 21.1619, lng: -86.8515),
    CiudadNodo(nombre: "Puebla", lat: 19.0414, lng: -98.2063),
    CiudadNodo(nombre: "Mérida", lat: 20.9674, lng: -89.5926),
    CiudadNodo(nombre: "Tijuana", lat: 32.5149, lng: -117.0382),
    CiudadNodo(nombre: "León", lat: 21.1220, lng: -101.6823),
    CiudadNodo(nombre: "Querétaro", lat: 20.5888, lng: -100.3899),
    CiudadNodo(nombre: "Toluca", lat: 19.2826, lng: -99.6557),
    CiudadNodo(nombre: "Acapulco", lat: 16.8531, lng: -99.8237),
    CiudadNodo(nombre: "Puerto Vallarta", lat: 20.6534, lng: -105.2253),
    CiudadNodo(nombre: "Los Cabos", lat: 22.8905, lng: -109.9167),
    CiudadNodo(nombre: "Mazatlán", lat: 23.2494, lng: -106.4111),
    CiudadNodo(nombre: "Veracruz", lat: 19.1738, lng: -96.1342),
    CiudadNodo(nombre: "Oaxaca", lat: 17.0732, lng: -96.7266),
    CiudadNodo(nombre: "Morelia", lat: 19.7050, lng: -101.1949),
    CiudadNodo(nombre: "Zacatecas", lat: 22.7709, lng: -102.5832),
    CiudadNodo(nombre: "Tuxtla Gutiérrez", lat: 16.7528, lng: -93.1167),
    CiudadNodo(nombre: "Villahermosa", lat: 17.9895, lng: -92.9475),
    CiudadNodo(nombre: "Campeche", lat: 19.8301, lng: -90.5349),
    CiudadNodo(nombre: "Chetumal", lat: 18.5043, lng: -88.3053),
    CiudadNodo(nombre: "Cozumel", lat: 20.4229, lng: -86.9223),
    CiudadNodo(nombre: "Aguascalientes", lat: 21.8853, lng: -102.2916),
    CiudadNodo(nombre: "Torreón", lat: 25.5428, lng: -103.4068),
    CiudadNodo(nombre: "Chihuahua", lat: 28.6329, lng: -106.0691),
    CiudadNodo(nombre: "Ciudad Juárez", lat: 31.6904, lng: -106.4245),
    CiudadNodo(nombre: "Durango", lat: 24.0277, lng: -104.6532),
    CiudadNodo(nombre: "Hermosillo", lat: 29.0729, lng: -110.9559),
    CiudadNodo(nombre: "La Paz", lat: 24.1426, lng: -110.3128),
    CiudadNodo(nombre: "Colima", lat: 19.2433, lng: -103.7241),
    CiudadNodo(nombre: "Tepic", lat: 21.5085, lng: -104.8956),
    CiudadNodo(nombre: "San Luis Potosí", lat: 22.1565, lng: -100.9855),
    CiudadNodo(nombre: "Xalapa", lat: 19.5438, lng: -96.9102),
  ];

  List<CiudadNodo> get ciudadesNodo {
    return ciudadesNodoBase.where((nodo) {
      return normalizar(nodo.nombre) != normalizar(widget.destinoNombre);
    }).toList();
  }

  final List<String> aeropuertos = [
    "Ciudad de México",
    "Guadalajara",
    "Monterrey",
    "Cancún",
    "Puebla",
    "Mérida",
    "Tijuana",
    "León",
    "Querétaro",
    "Toluca",
    "Acapulco",
    "Puerto Vallarta",
    "Los Cabos",
    "Mazatlán",
    "Veracruz",
    "Oaxaca",
    "Morelia",
    "Zacatecas",
    "Tuxtla Gutiérrez",
    "Villahermosa",
    "Campeche",
    "Chetumal",
    "Cozumel",
    "Aguascalientes",
    "Torreón",
    "Chihuahua",
    "Ciudad Juárez",
    "Durango",
    "Hermosillo",
    "La Paz",
    "Colima",
    "Tepic",
    "San Luis Potosí",
  ];

  final Map<String, String> aeropuertoPorDestino = {
    // Morelos
    "cuernavaca": "Ciudad de México",
    "tepoztlan": "Ciudad de México",
    "taxco": "Ciudad de México",

    // Estado de México
    "metepec": "Toluca",
    "valle de bravo": "Toluca",

    // Guanajuato
    "san miguel de allende": "Querétaro",
    "guanajuato": "León",

    // Quintana Roo
    "playa del carmen": "Cancún",
    "tulum": "Cancún",
    "isla holbox": "Cancún",
    "bacalar": "Chetumal",

    // Yucatán
    "izamal": "Mérida",
    "valladolid": "Mérida",

    // Veracruz
    "coatepec": "Xalapa",
    "orizaba": "Veracruz",

    // Hidalgo
    "pachuca": "Ciudad de México",
    "tula de allende": "Ciudad de México",

    // Jalisco
    "tequila": "Guadalajara",
    "chapala": "Guadalajara",
    "ajijic": "Guadalajara",
    "nuevo vallarta": "Puerto Vallarta",

    // Chiapas
    "san cristobal de las casas": "Tuxtla Gutiérrez",

    // Sonora
    "caborca": "Hermosillo",

    // Baja California
    "ensenada": "Tijuana",

    // San Luis Potosí
    "real de catorce": "San Luis Potosí",
  };

  @override
  void initState() {
    super.initState();
    calcularRuta();
  }

  CiudadNodo obtenerAeropuertoMasCercano(double lat, double lng) {
    CiudadNodo mejor = ciudadesNodoBase.first;
    double menor = double.infinity;

    for (var nodo in ciudadesNodoBase) {
      if (!aeropuertos.contains(nodo.nombre)) continue;

      final d = ubicacionServicio.calcularDistanciaEnKm(
        origenLat: lat,
        origenLng: lng,
        destinoLat: nodo.lat,
        destinoLng: nodo.lng,
      );

      if (d < menor) {
        menor = d;
        mejor = nodo;
      }
    }

    return mejor;
  }

  String formatearTiempo(double horas) {
    final totalMinutos = (horas * 60).round();

    final dias = totalMinutos ~/ 1440;
    final horasRestantes = (totalMinutos % 1440) ~/ 60;
    final minutos = totalMinutos % 60;

    if (dias > 0) {
      if (minutos == 0) {
        return "$dias d ${horasRestantes} h";
      }
      return "$dias d ${horasRestantes} h ${minutos} min";
    }

    if (horasRestantes > 0) {
      if (minutos == 0) {
        return "${horasRestantes} h";
      }
      return "${horasRestantes} h ${minutos} min";
    }

    return "$minutos min";
  }

  CiudadNodo obtenerAeropuertoDestinoInteligente() {
    final destinoNormalizado = normalizar(widget.destinoNombre);

    // Revisar reglas manuales
    if (aeropuertoPorDestino.containsKey(destinoNormalizado)) {
      final nombreAeropuerto = aeropuertoPorDestino[destinoNormalizado];

      return ciudadesNodoBase.firstWhere(
        (n) => normalizar(n.nombre) == normalizar(nombreAeropuerto!),
        orElse: () =>
            obtenerAeropuertoMasCercano(widget.destinoLat, widget.destinoLng),
      );
    }

    // Si el destino ya tiene aeropuerto
    final ciudadDirecta = ciudadesNodoBase.where((n) {
      return normalizar(n.nombre) == destinoNormalizado &&
          aeropuertos.contains(n.nombre);
    });

    if (ciudadDirecta.isNotEmpty) {
      return ciudadDirecta.first;
    }

    // fallback
    return obtenerAeropuertoMasCercano(widget.destinoLat, widget.destinoLng);
  }

  CiudadNodo obtenerNodoMasCercano(double lat, double lng) {
    CiudadNodo mejor = ciudadesNodo.first;
    double menor = double.infinity;

    for (var nodo in ciudadesNodo) {
      final d = ubicacionServicio.calcularDistanciaEnKm(
        origenLat: lat,
        origenLng: lng,
        destinoLat: nodo.lat,
        destinoLng: nodo.lng,
      );

      if (d < menor) {
        menor = d;
        mejor = nodo;
      }
    }
    return mejor;
  }

  CiudadNodo obtenerNodoCercanoAlDestino(
    double latDestino,
    double lngDestino,
    CiudadNodo excluir,
  ) {
    CiudadNodo mejor = ciudadesNodo.first;
    double menor = double.infinity;

    for (var nodo in ciudadesNodo) {
      if (nodo.nombre == excluir.nombre) continue;

      final d = ubicacionServicio.calcularDistanciaEnKm(
        origenLat: nodo.lat,
        origenLng: nodo.lng,
        destinoLat: latDestino,
        destinoLng: lngDestino,
      );

      if (d < menor) {
        menor = d;
        mejor = nodo;
      }
    }
    return mejor;
  }

  String normalizar(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  String obtenerDescripcionSegmento(SegmentoRuta s) {
    if (s.tipo == "avion") {
      return "Vuelo de ${s.origen} a ${s.destino}";
    }

    // Ir al aeropuerto
    if (aeropuertos.contains(s.destino) && !aeropuertos.contains(s.origen)) {
      return "Traslado al aeropuerto más cercano: ${s.origen} → ${s.destino}";
    }

    // Del aeropuerto al destino
    if (aeropuertos.contains(s.origen) && !aeropuertos.contains(s.destino)) {
      return "Traslado desde aeropuerto al destino: ${s.origen} → ${s.destino}";
    }

    return "${s.origen} → ${s.destino}";
  }

  Future<void> calcularRuta() async {
    segmentos.clear();
    costoTotal = 0;
    tiempoTotal = 0;

    final nombreOrigen = await ubicacionServicio.obtenerCiudadActual();
    nombreOrigenActual = nombreOrigen;

    final origen = await ubicacionServicio.obtenerCoordenadas();

    if (origen == null) {
      setState(() {
        mensaje = "No se pudo obtener tu ubicación";
        cargando = false;
      });
      return;
    }

    final nodoOrigen = obtenerNodoMasCercano(origen['lat']!, origen['lng']!);
    final nodoDestino = obtenerNodoMasCercano(
      widget.destinoLat,
      widget.destinoLng,
    );

    final aeropuertoOrigen = obtenerAeropuertoMasCercano(
      origen['lat']!,
      origen['lng']!,
    );

    final aeropuertoDestino = obtenerAeropuertoDestinoInteligente();

    debugPrint("DESTINO: ${widget.destinoNombre}");
    debugPrint("LAT DESTINO: ${widget.destinoLat}");
    debugPrint("LNG DESTINO: ${widget.destinoLng}");

    debugPrint("AEROPUERTO: ${aeropuertoDestino.nombre}");
    debugPrint("LAT AEROPUERTO: ${aeropuertoDestino.lat}");
    debugPrint("LNG AEROPUERTO: ${aeropuertoDestino.lng}");

    // ================= CARRO INICIAL =================
    final distCarro1 = ubicacionServicio.calcularDistanciaEnKm(
      origenLat: origen['lat']!,
      origenLng: origen['lng']!,
      destinoLat: aeropuertoOrigen.lat,
      destinoLng: aeropuertoOrigen.lng,
    );

    // ================= AVIÓN =================
    final distVuelo = ubicacionServicio.calcularDistanciaEnKm(
      origenLat: aeropuertoOrigen.lat,
      origenLng: aeropuertoOrigen.lng,
      destinoLat: aeropuertoDestino.lat,
      destinoLng: aeropuertoDestino.lng,
    );

    // ================= CARRO FINAL =================
    final distCarro2 = ubicacionServicio.calcularDistanciaEnKm(
      origenLat: aeropuertoDestino.lat,
      origenLng: aeropuertoDestino.lng,
      destinoLat: widget.destinoLat,
      destinoLng: widget.destinoLng,
    );

    // ================= DECISIÓN REAL =================
    final bool usarAvion = aeropuertos.contains(aeropuertoDestino.nombre);

    // ================= ARMADO DE RUTA =================
    if (usarAvion && distVuelo > 200) {
      // ================= PRIMER TRAMO =================
      segmentos.add(
        SegmentoRuta(
          tipo: "carro",
          origen: nombreOrigen ?? "Tu ubicación",
          destino: aeropuertoOrigen.nombre,
          origenLat: origen['lat']!,
          origenLng: origen['lng']!,
          destinoLat: aeropuertoOrigen.lat,
          destinoLng: aeropuertoOrigen.lng,
          distancia: distCarro1,
          tiempo: distCarro1 / 80,
          costo: distCarro1 * 2,
        ),
      );

      // ================= VUELO =================
      segmentos.add(
        SegmentoRuta(
          tipo: "avion",
          origen: aeropuertoOrigen.nombre,
          destino: aeropuertoDestino.nombre,
          origenLat: aeropuertoOrigen.lat,
          origenLng: aeropuertoOrigen.lng,
          destinoLat: aeropuertoDestino.lat,
          destinoLng: aeropuertoDestino.lng,
          distancia: distVuelo,
          tiempo: (distVuelo / 800) + 2,
          costo: (distVuelo * 2.5).clamp(900, 10000),
        ),
      );

      // ================= ÚLTIMO TRAMO SOLO SI ES NECESARIO =================
      final mismoDestino =
          normalizar(aeropuertoDestino.nombre) ==
          normalizar(widget.destinoNombre);

      if (!mismoDestino && distCarro2 > 5) {
        segmentos.add(
          SegmentoRuta(
            tipo: "carro",
            origen: aeropuertoDestino.nombre,
            destino: widget.destinoNombre,
            origenLat: aeropuertoDestino.lat,
            origenLng: aeropuertoDestino.lng,
            destinoLat: widget.destinoLat,
            destinoLng: widget.destinoLng,
            distancia: distCarro2,
            tiempo: distCarro2 / 60,
            costo: distCarro2 * 2,
          ),
        );
      }
    } else {
      // fallback: todo en carretera inteligente
      final distTotal = ubicacionServicio.calcularDistanciaEnKm(
        origenLat: origen['lat']!,
        origenLng: origen['lng']!,
        destinoLat: widget.destinoLat,
        destinoLng: widget.destinoLng,
      );

      segmentos.add(
        SegmentoRuta(
          tipo: "carro",
          origen: nombreOrigen ?? "Tu ubicación",
          destino: widget.destinoNombre,
          origenLat: origen['lat']!,
          origenLng: origen['lng']!,
          destinoLat: widget.destinoLat,
          destinoLng: widget.destinoLng,
          distancia: distTotal,
          tiempo: distTotal / 80,
          costo: distTotal * 2,
        ),
      );
    }

    for (var s in segmentos) {
      costoTotal += s.costo;
      tiempoTotal += s.tiempo;
    }

    setState(() {
      cargando = false;
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                      "Ruta Mixta",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  Center(
                    child: Text(
                      "Información estimada",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🔙 BACK BUTTON FIJO ARRIBA IZQUIERDA
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                bottom: false,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text("Origen: ${nombreOrigenActual ?? widget.origen}"),
                Text("Destino: ${widget.destinoNombre}"),
                const SizedBox(height: 20),

                ...segmentos.map(_cardSegmento),
              ],
            ),
    );
  }

  Widget _cardSegmento(SegmentoRuta s) {
    IconData icono;
    Color color;
    String titulo;

    switch (s.tipo) {
      case "carro":
        icono = Icons.directions_car;
        color = Colors.blue;
        titulo = "Trayecto en carro";
        break;
      case "autobus":
        icono = Icons.directions_bus;
        color = Colors.green;
        titulo = "Viaje en autobús";
        break;
      case "avion":
        icono = Icons.flight;
        color = Colors.purple;
        titulo = "Vuelo";
        break;
      default:
        icono = Icons.route;
        color = Colors.grey;
        titulo = "Trayecto";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  obtenerDescripcionSegmento(s),
                  style: const TextStyle(fontSize: 14),
                ),

                const SizedBox(height: 8),

                Text(
                  "Tiempo: ${formatearTiempo(s.tiempo)}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),

                Text(
                  "Costo aprox: \$${s.costo.toStringAsFixed(0)} MXN",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
