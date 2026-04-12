import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'package:proyecto/compartidos/widgets/barra_busqueda.dart';
import 'package:proyecto/compartidos/widgets/filtros_busqueda.dart';
import 'package:proyecto/compartidos/widgets/tarjeta_lugar.dart';
import 'package:proyecto/modulos/busqueda/lugar_detalle_pantalla.dart';

import 'package:proyecto/nucleo/servicios/foursquare_servicio.dart';
import 'package:proyecto/nucleo/servicios/opentripmap_servicio.dart';
import 'package:proyecto/nucleo/servicios/ubicacion_servicio.dart';

import 'package:proyecto/nucleo/utilidades/calculos_util.dart';
import 'package:proyecto/nucleo/utilidades/mapeo_categorias.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusquedaPantalla extends StatefulWidget {
  const BusquedaPantalla({super.key});

  @override
  State<BusquedaPantalla> createState() => _BusquedaPantallaState();
}

class _BusquedaPantallaState extends State<BusquedaPantalla> {
  String query = "";
  String? destinoSeleccionado;
  String? tipoSeleccionado;
  String? estiloSeleccionado;
  String? precioSeleccionado;

  bool cargando = false;
  String? error;

  String idUsuarioActual = FirebaseAuth.instance.currentUser?.uid ?? "";
  Map<String, dynamic> interesesUsuario = {};
  List<Map<String, dynamic>> lugares = [];

  @override
  void initState() {
    super.initState();
    obtenerPreferenciaReal();
    //buscarLugaresAPI();
  }
Future<void> obtenerPreferenciaReal() async {
    if (idUsuarioActual.isEmpty) {
      buscarLugaresAPI();
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(idUsuarioActual)
          .get();

      if (doc.exists) {
        setState(() {
          interesesUsuario = doc.data()?['vector_intereses'] ?? {};
        });
      }
      buscarLugaresAPI();
    } catch (e) {
      print("Error al obtener intereses: $e");
      buscarLugaresAPI();
    }
  }

  // 🧠 ALGORITMO FASE 3: ETIQUETADO AUTOMÁTICO (PESOS Y UMBRAL)
  // Basado en: PuntajeEtiqueta = ∑(pesopalabrai) [cite: 315]
  List<Map<String, dynamic>> aplicarPesos(List<Map<String, dynamic>> lista) {
    return lista.map((lugar) {
      double R = (lugar["rating"] ?? 5.0).toDouble(); // Calificación (0-10) [cite: 396]
      double P = (lugar["popularity"] ?? 5.0).toDouble(); // Popularidad [cite: 397]
      
      // D = Distancia inversa (mientras más cerca, más alto el valor) [cite: 398]
      double D = 10 / ((lugar["distancia"] ?? 1.0) + 1); 
      if (D > 10) D = 10;

      // C = Coincidencia con etiquetas (Vector de intereses) [cite: 399]
      double C = 0;
      String catLugar = lugar["categoriaPrincipal"].toString().toLowerCase();
      if (interesesUsuario.containsKey(catLugar)) {
        // Umbral mínimo de 8 puntos para considerarlo relevante 
        int puntosInteres = interesesUsuario[catLugar] ?? 0;
        C = puntosInteres >= 8 ? 10.0 : (puntosInteres * 1.25); 
      }

      // 🔥 FÓRMULA EXACTA: (R * 0.4) + (P * 0.2) + (D * 0.2) + (C * 0.2) [cite: 395]
      lugar["relevancia"] = (R * 0.4) + (P * 0.2) + (D * 0.2) + (C * 0.2);
      
      return lugar;
    }).toList();
  }

  // 🧠 ALGORITMO FASE 3: QUICKSORT O(n log n) [cite: 400]
  List<Map<String, dynamic>> ordenarPorQuickSort(List<Map<String, dynamic>> lista) {
    if (lista.length <= 1) return lista;
    var pivote = lista[lista.length ~/ 2];
    double pivoteRelevancia = (pivote['relevancia'] ?? 0).toDouble();

    var mayores = lista.where((x) => (x['relevancia'] ?? 0) > pivoteRelevancia).toList();
    var iguales = lista.where((x) => (x['relevancia'] ?? 0) == pivoteRelevancia).toList();
    var menores = lista.where((x) => (x['relevancia'] ?? 0) < pivoteRelevancia).toList();

    return [...ordenarPorQuickSort(mayores), ...iguales, ...ordenarPorQuickSort(menores)];
  }

  
// no tocar este método, es el que hace la selección final de los 5 lugares variados, no solo los más relevantes
  // 🔥 TOP 5 VARIADOS
  List<Map<String, dynamic>> seleccionarTop5Variados(
    List<Map<String, dynamic>> lista,
  ) {
    final Map<String, Map<String, dynamic>> porCategoria = {};
    final List<Map<String, dynamic>> resultado = [];

    for (var lugar in lista) {
      final categoria = lugar["categoriaPrincipal"] ?? "otro";
      if (!porCategoria.containsKey(categoria)) {
        porCategoria[categoria] = lugar;
      }
    }

    resultado.addAll(porCategoria.values);

    for (var lugar in lista) {
      if (resultado.length >= 5) break;
      if (!resultado.contains(lugar)) {
        resultado.add(lugar);
      }
    }

    return resultado.take(5).toList();
  }

  // 🔥 VALIDACIÓN GEOGRÁFICA FUERTE
  bool esValidoGeograficamente(
    Map<String, dynamic> lugar,
    double latBase,
    double lngBase,
  ) {
    final latLugar = lugar["lat"];
    final lngLugar = lugar["lng"];

    if (latLugar == null || lngLugar == null) return false;

    if ((latLugar - latBase).abs() > 0.1) return false;
    if ((lngLugar - lngBase).abs() > 0.1) return false;

    return true;
  }

  Future<void> buscarLugaresAPI() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      double lat;
      double lng;

      // 🔥 1. COORDENADAS
      if (destinoSeleccionado != null && destinoSeleccionado!.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(destinoSeleccionado)
            .get();

        if (!doc.exists) {
          throw Exception("Ciudad no encontrada");
        }

        final data = doc.data()!;
        lat = (data["lat"] as num).toDouble();
        lng = (data["lng"] as num).toDouble();
      } else {
        final posicion = await UbicacionServicio().obtenerUbicacionActual();

        if (posicion != null) {
          lat = posicion.latitude;
          lng = posicion.longitude;
        } else {
          lat = 20.6597;
          lng = -103.3496;
        }
      }

      print("📍 Coordenadas usadas: $lat, $lng");

      // 🔥 2. APIs
      final resultadosFoursquare =
          await FoursquareServicio.buscarLugaresCercanos(lat, lng);

      final resultadosOpenTrip =
          await OpenTripMapServicio.buscarLugaresCulturales(lat, lng);

      // 🔥 3. NORMALIZAR
      final combinados = [
        ...resultadosFoursquare.map((lugar) {
          final geo = lugar["geocodes"]?["main"];

          return {
            "name": lugar["name"] ?? "Lugar",
            "location":
                lugar["location"] ?? {"formatted_address": "Sin dirección"},
            "lat": geo?["latitude"] ?? lat,
            "lng": geo?["longitude"] ?? lng,
            "categories": lugar["categories"] ?? [],
            "categoriaPrincipal": MapeoCategorias.obtenerCategoriaPrincipal(
              lugar["categories"],
            ),
            "precio": lugar["price"] ?? "\$\$",
          };
        }),
        ...resultadosOpenTrip.map((lugar) {
          final coords = lugar["geometry"]?["coordinates"];

          return {
            "name": lugar["properties"]?["name"] ?? "Lugar",
            "location": {
              "formatted_address": lugar["properties"]?["kinds"] ?? "Turístico",
            },
            "lat": (coords != null && coords.length > 1) ? coords[1] : lat,
            "lng": (coords != null && coords.length > 1) ? coords[0] : lng,
            "categories": [
              {"name": "Turístico"},
            ],
            "categoriaPrincipal": MapeoCategorias.obtenerCategoriaPrincipal(
              lugar["properties"]?["kinds"],
            ),
            "precio": "\$\$",
          };
        }),
      ];

      // 🔥 4. DISTANCIA
      for (var lugar in combinados) {
        lugar["distancia"] = CalculosUtil.calcularDistancia(
          lat,
          lng,
          lugar["lat"],
          lugar["lng"],
        );
      }

      // 🔥 5. FILTRO CALIDAD
      final filtradosCalidad = combinados.where((lugar) {
        final nombre = (lugar["name"] ?? "").toString().toLowerCase();

        if (nombre.isEmpty || nombre == "lugar") return false;
        if (nombre.length < 3) return false;

        if (nombre.contains("unknown") ||
            nombre.contains("sin nombre") ||
            nombre.contains("no name")) {
          return false;
        }

        return true;
      }).toList();

      // 🔥 6. FILTRO DISTANCIA (AHORA 5 KM)
      final filtradosDistancia = filtradosCalidad.where((lugar) {
        final distancia = lugar["distancia"];

        if (distancia == null) return false;
        if (distancia > 5) return false; // 🔥 clave
        if (distancia.isNaN || distancia.isInfinite) return false;

        return true;
      }).toList();

      // 🔥 7. FILTRO FINAL (GEOGRÁFICO + BASURA)
      final filtradosFinal = filtradosDistancia.where((lugar) {
        final nombre = lugar["name"].toString().toLowerCase();

        // ❌ blacklist
        if (nombre.contains("carajillo")) return false;
        if (nombre.contains("parián")) return false;
        if (nombre.contains("teatro experimental")) return false;

        // 🔥 validación fuerte
        if (!esValidoGeograficamente(lugar, lat, lng)) return false;

        return true;
      }).toList();

      // 🔥 8. ORDENAR
    //  filtradosFinal.sort((a, b) => a["distancia"].compareTo(b["distancia"]));
     
      final lugaresConPesos = aplicarPesos(filtradosFinal); // Aplica la fórmula (R*0.4 + P*0.2 + D*0.2 + C*0.2)
      final lugaresOrdenados = ordenarPorQuickSort(lugaresConPesos); // Ordena de mayor a menor relevancia [cite: 400]
    
      print("--- RANKING DE RELEVANCIA PACK&GO ---");

      for (var lugar in lugaresOrdenados) {
        print("${lugar['name']} - Relevancia: ${lugar['relevancia']}");
      }
      print("---------------------------------------");

      // 🔥 9. TOP 5 FINAL
      final top5 = seleccionarTop5Variados(lugaresOrdenados);

      setState(() {
        lugares = top5;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = "Error al buscar lugares";
        cargando = false;
      });

      print("❌ ERROR: $e");
    }
  }

  Future<void> buscarPorTexto(String texto) async {
    if (!mounted) return;

    setState(() {
      cargando = true;
    });

    try {
      double lat;
      double lng;

      // 🔥 MISMA LÓGICA DE UBICACIÓN
      if (destinoSeleccionado != null && destinoSeleccionado!.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(destinoSeleccionado)
            .get();

        final data = doc.data()!;
        lat = (data["lat"] as num).toDouble();
        lng = (data["lng"] as num).toDouble();
      } else {
        final posicion = await UbicacionServicio().obtenerUbicacionActual();

        lat = posicion?.latitude ?? 20.6597;
        lng = posicion?.longitude ?? -103.3496;
      }

      // 🔥 BUSCAR EN FOURSQUARE POR TEXTO
      final url = Uri.parse(
        'https://places-api.foursquare.com/places/search'
        'query=${Uri.encodeComponent(texto)}'
        '&ll=$lat,$lng'
        '&radius=5000'
        '&limit=20'
        '&fields=name,location,geocodes,categories',
      );

      final apiKey = dotenv.env['FOURSQUARE_API_KEY']!;

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final resultados = (data['results'] as List).map((lugar) {
          final geo = lugar["geocodes"]?["main"];

          return {
            "name": lugar["name"] ?? "Lugar",
            "location":
                lugar["location"] ?? {"formatted_address": "Sin dirección"},
            "lat": geo?["latitude"] ?? lat,
            "lng": geo?["longitude"] ?? lng,
            "categories": lugar["categories"] ?? [],
            "categoriaPrincipal": MapeoCategorias.obtenerCategoriaPrincipal(
              lugar["categories"],
            ),
            "precio": "\$\$",
          };
        }).toList();

        setState(() {
          lugares = resultados; // 🔥 YA NO TOP 5
          cargando = false;
        });
      } else {
        setState(() {
          lugares = [];
          cargando = false;
        });
      }
    } catch (e) {
      print("❌ Error búsqueda texto: $e");

      setState(() {
        cargando = false;
      });
    }
  }

  // 🔥 FILTROS UI
  List<Map<String, dynamic>> get lugaresFiltrados {
    if (query.length >= 3) {
      return lugares; // 🔥 mostrar todo lo encontrado
    }

    return lugares.where((lugar) {
      final nombre = lugar["name"].toLowerCase();

      final coincideBusqueda = nombre.contains(query.toLowerCase());

      final coincideTipo =
          tipoSeleccionado == null ||
          lugar["categoriaPrincipal"] == tipoSeleccionado;

      final coincidePrecio =
          precioSeleccionado == null || lugar["precio"] == precioSeleccionado;

      return coincideBusqueda && coincideTipo && coincidePrecio;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("Pack&Go", style: GoogleFonts.poppins(fontSize: 36)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            BarraBusqueda(
              onChanged: (valor) {
                setState(() => query = valor);

                if (valor.length >= 3) {
                  buscarPorTexto(valor); // 🔥 NUEVO
                } else {
                  buscarLugaresAPI(); // vuelve a normal
                }
              },
            ),

            const SizedBox(height: 12),

            FiltrosBusqueda(
              destinoSeleccionado: destinoSeleccionado,
              tipoSeleccionado: tipoSeleccionado,
              estiloSeleccionado: estiloSeleccionado,
              precioSeleccionado: precioSeleccionado,
              onDestinoChanged: (v) {
                setState(() => destinoSeleccionado = v);
                buscarLugaresAPI();
              },
              onTipoChanged: (v) => setState(() => tipoSeleccionado = v),
              onEstiloChanged: (v) => setState(() => estiloSeleccionado = v),
              onPrecioChanged: (v) => setState(() => precioSeleccionado = v),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: cargando
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? Center(child: Text(error!))
                  : lugaresFiltrados.isEmpty
                  ? const Center(
                      child: Text("No hay lugares con estas características"),
                    )
                  : ListView(
                      children: lugaresFiltrados.map((lugar) {
                        return TarjetaLugar(
                          nombre: lugar["name"],
                          ubicacion: lugar["location"]["formatted_address"],
                          lat: lugar["lat"],
                          lng: lugar["lng"],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    LugarDetallePantalla(lugar: lugar),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
