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
    CiudadNodo(nombre: "Guadalajara", lat: 20.67, lng: -103.35),
    CiudadNodo(nombre: "CDMX", lat: 19.43, lng: -99.13),
    CiudadNodo(nombre: "Monterrey", lat: 25.68, lng: -100.31),
    CiudadNodo(nombre: "Cancún", lat: 21.16, lng: -86.85),
    CiudadNodo(nombre: "Mérida", lat: 20.97, lng: -89.62),
    CiudadNodo(nombre: "Puebla", lat: 19.04, lng: -98.20),
    CiudadNodo(nombre: "Oaxaca", lat: 17.07, lng: -96.72),
    CiudadNodo(nombre: "Querétaro", lat: 20.59, lng: -100.39),
    CiudadNodo(nombre: "Tijuana", lat: 32.51, lng: -117.04),
  ];

  List<CiudadNodo> get ciudadesNodo {
    return ciudadesNodoBase.where((nodo) {
      return normalizar(nodo.nombre) != normalizar(widget.destinoNombre);
    }).toList();
  }

  final List<String> aeropuertos = [
    "Guadalajara",
    "CDMX",
    "Monterrey",
    "Tijuana",
    "Cancún",
    "Mérida",
  ];

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

  // ================= LÓGICA =================

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

    final aeropuertoDestino = obtenerAeropuertoMasCercano(
      widget.destinoLat,
      widget.destinoLng,
    );

    // ================= CARRO INICIAL =================
    final distCarro1 = ubicacionServicio.calcularDistanciaEnKm(
      origenLat: origen['lat']!,
      origenLng: origen['lng']!,
      destinoLat: nodoOrigen.lat,
      destinoLng: nodoOrigen.lng,
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
      segmentos.addAll([
        SegmentoRuta(
          tipo: "carro",
          origen: nombreOrigen ?? "Tu ubicación",
          destino: nodoOrigen.nombre,
          origenLat: origen['lat']!,
          origenLng: origen['lng']!,
          destinoLat: nodoOrigen.lat,
          destinoLng: nodoOrigen.lng,
          distancia: distCarro1,
          tiempo: distCarro1 / 80,
          costo: distCarro1 * 2,
        ),

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
      ]);
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
                  "${s.origen} → ${s.destino}",
                  style: const TextStyle(fontSize: 14),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text("${s.tiempo.toStringAsFixed(1)} h"),

                    const SizedBox(width: 16),

                    const SizedBox(width: 4),
                    Text("\$${s.costo.toStringAsFixed(0)}"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
