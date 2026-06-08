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
  String avisoRuta = "";

  List<SegmentoRuta> segmentos = [];
  static const double _esperaAeropuerto = 2.0;
  static const double _esperaTerminal = 0.5;
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
    CiudadNodo(nombre: "Tapachula", lat: 14.9006, lng: -92.2634),
    CiudadNodo(nombre: "Mexicali", lat: 32.6245, lng: -115.4523),
    CiudadNodo(nombre: "Tampico", lat: 22.2553, lng: -97.8686),
    CiudadNodo(nombre: "Huatulco", lat: 15.7753, lng: -96.2626),
    CiudadNodo(nombre: "Puerto Escondido", lat: 15.8625, lng: -97.0769),
    CiudadNodo(nombre: "Los Mochis", lat: 25.7905, lng: -108.9859),
    CiudadNodo(nombre: "Loreto", lat: 26.0118, lng: -111.3474),
    CiudadNodo(nombre: "Ciudad Obregón", lat: 27.4828, lng: -109.9304),
    CiudadNodo(nombre: "Reynosa", lat: 26.0922, lng: -98.2770),
    CiudadNodo(nombre: "Matamoros", lat: 25.8690, lng: -97.5027),
    CiudadNodo(nombre: "Uruapan", lat: 19.4064, lng: -102.0430),
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
    "Mérida",
    "Tijuana",
    "León",
    "Querétaro",
    "Toluca",
    "Puerto Vallarta",
    "Los Cabos",
    "Mazatlán",
    "Veracruz",
    "Oaxaca",
    "Tuxtla Gutiérrez",
    "Villahermosa",
    "Chetumal",
    "Cozumel",
    "Chihuahua",
    "Ciudad Juárez",
    "Durango",
    "Hermosillo",
    "La Paz",
    "San Luis Potosí",
    "Tapachula",
    "Mexicali",
    "Tampico",
    "Huatulco",
    "Puerto Escondido",
    "Los Mochis",
    "Loreto",
    "Ciudad Obregón",
    "Reynosa",
    "Matamoros",
    "Uruapan",
  ];

  final List<String> aeropuertosPrincipales = [
    "Ciudad de México",
    "Guadalajara",
    "Monterrey",
    "Cancún",
    "Tijuana",
    "Mérida",
    "Puerto Vallarta",
    "Los Cabos",
    "Hermosillo",
    "La Paz",
    "Oaxaca",
    "Veracruz",
    "Tuxtla Gutiérrez",
    "Villahermosa",
    "Chihuahua",
    "Ciudad Juárez",
    "Mexicali",
    "Tapachula",
  ];

  final Map<String, String> aeropuertoPorDestino = {
    // ================= MORELOS =================
    "cuernavaca": "Ciudad de México",

    // ================= GUERRERO =================
    "taxco": "Ciudad de México",

    // ================= EDOMEX =================
    "metepec": "Toluca",
    "valle de bravo": "Toluca",

    // ================= HIDALGO =================
    "pachuca": "Ciudad de México",
    "tula de allende": "Ciudad de México",

    // ================= GUANAJUATO =================
    "san miguel de allende": "Querétaro",
    "guanajuato": "León",

    // ================= JALISCO =================
    "tequila": "Guadalajara",
    "chapala": "Guadalajara",
    "ajijic": "Guadalajara",

    // ================= NAYARIT =================
    "nuevo vallarta": "Puerto Vallarta",

    // ================= COLIMA =================
    "manzanillo": "Colima",

    // ================= CHIAPAS =================
    "san cristobal de las casas": "Tuxtla Gutiérrez",

    // ================= SONORA =================
    "caborca": "Hermosillo",

    // ================= BAJA CALIFORNIA =================
    "ensenada": "Tijuana",

    // ================= SAN LUIS POTOSI =================
    "real de catorce": "San Luis Potosí",

    // ================= VERACRUZ =================
    "coatepec": "Veracruz",
    "orizaba": "Veracruz",
    "tlaxcala": "Puebla",
    "saltillo": "Monterrey",
    // ================= YUCATAN =================
    "izamal": "Mérida",
    "valladolid": "Mérida",

    // ================= QUINTANA ROO =================
    "playa del carmen": "Cancún",
    "tulum": "Cancún",
    "isla holbox": "Cancún",
    "bacalar": "Chetumal",

    // ================= OAXACA =================
    "puerto escondido": "Puerto Escondido",
    "huatulco": "Huatulco",

    // ================= CHIAPAS =================
    "tapachula": "Tapachula",
    "palenque": "Villahermosa",

    // ================= MICHOACAN =================
    "patzcuaro": "Morelia",
    "uruapan": "Uruapan",

    // ================= BAJA CALIFORNIA SUR =================
    "loreto": "Loreto",

    // ================= SONORA =================
    "san carlos": "Hermosillo",

    // ================= SINALOA =================
    "topolobampo": "Los Mochis",

    // ================= TAMAULIPAS =================
    "nuevo laredo": "Monterrey",
    "reynosa": "Reynosa",
    "matamoros": "Matamoros",
  };

  @override
  void initState() {
    super.initState();
    calcularRuta();
  }

  CiudadNodo obtenerAeropuertoMasCercano(
    double lat,
    double lng, {
    bool soloPrincipales = false,
  }) {
    final aeropuertosValidos = ciudadesNodoBase.where((n) {
      if (!aeropuertos.contains(n.nombre)) return false;

      if (soloPrincipales) {
        return aeropuertosPrincipales.contains(n.nombre);
      }

      return true;
    });

    CiudadNodo mejor = aeropuertosValidos.first;
    double menor = double.infinity;

    for (var nodo in aeropuertosValidos) {
      final distancia = ubicacionServicio.calcularDistanciaEnKm(
        origenLat: lat,
        origenLng: lng,
        destinoLat: nodo.lat,
        destinoLng: nodo.lng,
      );

      if (distancia < menor) {
        menor = distancia;
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
        return "$dias d $horasRestantes h";
      }
      return "$dias d $horasRestantes h $minutos min";
    }

    if (horasRestantes > 0) {
      if (minutos == 0) {
        return "$horasRestantes h";
      }
      return "$horasRestantes h $minutos min";
    }

    return "$minutos min";
  }

  String tipoTransporteTerrestre(double distancia) {
    if (distancia < 220) {
      return "carro";
    }

    return "autobus";
  }

  double obtenerVelocidad(String tipo) {
    switch (tipo) {
      case "autobus":
        return 75;

      case "carro":
      default:
        return 85;
    }
  }

  double obtenerCostoPorKm(String tipo) {
    switch (tipo) {
      case "autobus":
        return 1.1;

      case "carro":
      default:
        return 2.0;
    }
  }

  CiudadNodo obtenerAeropuertoDestinoInteligente() {
    final destinoNormalizado = normalizar(widget.destinoNombre);

    debugPrint("DESTINO NORMALIZADO: $destinoNormalizado");

    // ================= REGLAS MANUALES =================
    if (aeropuertoPorDestino.containsKey(destinoNormalizado)) {
      final nombreAeropuerto = aeropuertoPorDestino[destinoNormalizado];

      final encontrado = ciudadesNodoBase.where((n) {
        return normalizar(n.nombre) == normalizar(nombreAeropuerto!);
      });

      if (encontrado.isNotEmpty) {
        debugPrint("AEROPUERTO POR REGLA: ${encontrado.first.nombre}");
        return encontrado.first;
      }
    }

    // ================= SI EL DESTINO YA ES AEROPUERTO =================
    final aeropuertoDirecto = ciudadesNodoBase.where((n) {
      return normalizar(n.nombre) == destinoNormalizado;
    });

    if (aeropuertoDirecto.isNotEmpty) {
      debugPrint(
        "DESTINO YA TIENE AEROPUERTO: ${aeropuertoDirecto.first.nombre}",
      );
      return aeropuertoDirecto.first;
    }

    // ================= FALLBACK =================
    final fallback = obtenerAeropuertoMasCercano(
      widget.destinoLat,
      widget.destinoLng,
      soloPrincipales: true,
    );

    debugPrint("FALLBACK AEROPUERTO: ${fallback.nombre}");

    return fallback;
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

    debugPrint("================================");
    debugPrint("DESTINO: ${widget.destinoNombre}");
    debugPrint("LAT DESTINO: ${widget.destinoLat}");
    debugPrint("LNG DESTINO: ${widget.destinoLng}");
    debugPrint("================================");

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
      soloPrincipales: true,
    );

    final distanciaTotal = ubicacionServicio.calcularDistanciaEnKm(
      origenLat: origen['lat']!,
      origenLng: origen['lng']!,
      destinoLat: widget.destinoLat,
      destinoLng: widget.destinoLng,
    );

    final aeropuertoDestino = obtenerAeropuertoDestinoInteligente();

    final destinoTieneAeropuerto = aeropuertos.any(
      (a) => normalizar(a) == normalizar(widget.destinoNombre),
    );

    final mismoAeropuerto =
        normalizar(aeropuertoOrigen.nombre) ==
        normalizar(aeropuertoDestino.nombre);

    final destinoCercaAeropuerto =
        ubicacionServicio.calcularDistanciaEnKm(
          origenLat: aeropuertoDestino.lat,
          origenLng: aeropuertoDestino.lng,
          destinoLat: widget.destinoLat,
          destinoLng: widget.destinoLng,
        ) <
        80;

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

    final vueloMuyLargo = distVuelo > 3500;

    final bool usarAvion =
        !mismoAeropuerto &&
        distanciaTotal > 500 &&
        distVuelo > 300 &&
        distCarro1 < 180 &&
        distCarro2 < 320 &&
        !vueloMuyLargo;

    debugPrint("DISTANCIA TOTAL: $distanciaTotal km");
    debugPrint("MISMO AEROPUERTO: $mismoAeropuerto");
    debugPrint("DESTINO CERCA AEROPUERTO: $destinoCercaAeropuerto");
    debugPrint("USAR AVION: $usarAvion");
    debugPrint("DESTINO TIENE AEROPUERTO: $destinoTieneAeropuerto");

    final diferenciaAeropuertos = ubicacionServicio.calcularDistanciaEnKm(
      origenLat: aeropuertoOrigen.lat,
      origenLng: aeropuertoOrigen.lng,
      destinoLat: aeropuertoDestino.lat,
      destinoLng: aeropuertoDestino.lng,
    );

    if (diferenciaAeropuertos < 250) {
      debugPrint("Aeropuertos demasiado cercanos. No usar avión.");
    }

    // ================= MENSAJES INTELIGENTES =================

    if (usarAvion) {
      avisoRuta =
          "Se encontró una combinación eficiente entre transporte terrestre y vuelo.";
    } else if (distanciaTotal < 250) {
      avisoRuta =
          "El destino está relativamente cerca, por lo que viajar por carretera resulta más práctico.";
    } else if (mismoAeropuerto) {
      avisoRuta =
          "El aeropuerto de origen y destino son muy cercanos, por lo que no se recomienda avión.";
    } else if (distCarro2 > 180) {
      avisoRuta =
          "El aeropuerto más cercano al destino queda lejos, así que se priorizó la ruta terrestre.";
    } else {
      avisoRuta =
          "No se encontró una ruta aérea conveniente para este trayecto.";
    }

    // ================= ARMADO DE RUTA =================
    if (usarAvion && distVuelo > 200 && diferenciaAeropuertos > 250) {
      final tipoPrimerTramo = tipoTransporteTerrestre(distCarro1);
      // ================= PRIMER TRAMO =================
      segmentos.add(
        SegmentoRuta(
          tipo: tipoPrimerTramo,
          origen: nombreOrigen ?? "Tu ubicación",
          destino: aeropuertoOrigen.nombre,
          origenLat: origen['lat']!,
          origenLng: origen['lng']!,
          destinoLat: aeropuertoOrigen.lat,
          destinoLng: aeropuertoOrigen.lng,
          distancia: distCarro1,
          tiempo: distCarro1 / obtenerVelocidad(tipoPrimerTramo),
          costo: distCarro1 * obtenerCostoPorKm(tipoPrimerTramo),
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
        final tipoUltimoTramo = tipoTransporteTerrestre(distCarro2);
        segmentos.add(
          SegmentoRuta(
            tipo: tipoUltimoTramo,
            origen: aeropuertoDestino.nombre,
            destino: widget.destinoNombre,
            origenLat: aeropuertoDestino.lat,
            origenLng: aeropuertoDestino.lng,
            destinoLat: widget.destinoLat,
            destinoLng: widget.destinoLng,
            distancia: distCarro2,
            tiempo: distCarro2 / obtenerVelocidad(tipoUltimoTramo),
            costo: distCarro2 * obtenerCostoPorKm(tipoUltimoTramo),
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
          tipo: tipoTransporteTerrestre(distTotal),
          origen: nombreOrigen ?? "Tu ubicación",
          destino: widget.destinoNombre,
          origenLat: origen['lat']!,
          origenLng: origen['lng']!,
          destinoLat: widget.destinoLat,
          destinoLng: widget.destinoLng,
          distancia: distTotal,
          tiempo: distanciaTotal > 350 ? distTotal / 70 : distTotal / 80,
          costo: distanciaTotal > 350 ? distTotal * 1.2 : distTotal * 2,
        ),
      );
    }
    //  — sumar tiempos de espera entre transportes
    double tiempoEspera = 0;
    for (int i = 0; i < segmentos.length - 1; i++) {
      final actual = segmentos[i].tipo;
      final siguiente = segmentos[i + 1].tipo;
      if (actual == 'avion' || siguiente == 'avion') {
        tiempoEspera += _esperaAeropuerto;
      } else if (actual != siguiente) {
        tiempoEspera += _esperaTerminal;
      }
    }

    costoTotal = segmentos.fold(0.0, (sum, s) => sum + s.costo);
    tiempoTotal =
        segmentos.fold(0.0, (sum, s) => sum + s.tiempo) + tiempoEspera;

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
                Text(
                  "Origen: ${nombreOrigenActual ?? widget.origen}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "Destino: ${widget.destinoNombre}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFF6A230)),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          avisoRuta,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                ...segmentos
                    .where((s) => s.tipo != "espera")
                    .map(_cardSegmento),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Tiempo total estimado",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            formatearTiempo(tiempoTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Costo total estimado",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            "\$${costoTotal.toStringAsFixed(0)} MXN",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        "* Incluye tiempos de espera en aeropuerto",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
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
