import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/compartidos/widgets/barra_busqueda.dart';
import 'package:proyecto/compartidos/widgets/filtros_busqueda.dart';
import 'package:proyecto/compartidos/widgets/tarjeta_lugar.dart';
import 'package:proyecto/modulos/busqueda/lugar_detalle_pantalla.dart'; // Nuestra nueva pantalla unificada

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

  // Simulación de lista de lugares (puede venir de Foursquare o Firestore)
  final List<Map<String, dynamic>> lugares = [
    {
      "name": "Teotihuacán",
      "location": {"formatted_address": "Estado de México"},
      "lat": 19.6925,
      "lng": -98.8430,
      "categories": [
        {"name": "Zona arqueológica"},
      ],
    },
    {
      "name": "Chichén Itzá",
      "location": {"formatted_address": "Yucatán"},
      "lat": 20.6843,
      "lng": -88.5678,
      "categories": [
        {"name": "Zona arqueológica"},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("Pack&Go", style: GoogleFonts.poppins(fontSize: 36)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Barra de búsqueda
            BarraBusqueda(
              onChanged: (valor) {
                setState(() {
                  query = valor;
                });
              },
            ),

            const SizedBox(height: 12),

            // Filtros
            FiltrosBusqueda(
              destinoSeleccionado: destinoSeleccionado,
              tipoSeleccionado: tipoSeleccionado,
              estiloSeleccionado: estiloSeleccionado,
              precioSeleccionado: precioSeleccionado,
              onDestinoChanged: (v) => setState(() => destinoSeleccionado = v),
              onTipoChanged: (v) => setState(() => tipoSeleccionado = v),
              onEstiloChanged: (v) => setState(() => estiloSeleccionado = v),
              onPrecioChanged: (v) => setState(() => precioSeleccionado = v),
            ),

            const SizedBox(height: 16),

            // Lista de resultados
            Expanded(
              child: ListView(
                children: lugares
                    .where((lugar) {
                      // Filtro básico por barra de búsqueda
                      final nombre =
                          lugar["name"]?.toString().toLowerCase() ?? "";
                      return nombre.contains(query.toLowerCase());
                    })
                    .map(
                      (lugar) => TarjetaLugar(
                        nombre: lugar["name"],
                        ubicacion: lugar["location"]["formatted_address"],
                        lat: lugar["lat"],
                        lng: lugar["lng"],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LugarDetallePantalla(
                                lugar: lugar, // Pasamos el Map completo
                                // Si quieres, también se puede desestructurar:
                                // nombre: lugar["name"],
                                // ubicacion: lugar["location"]["formatted_address"],
                                // lat: lugar["lat"],
                                // lng: lugar["lng"],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
