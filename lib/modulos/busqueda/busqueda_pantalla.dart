import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/compartidos/widgets/barra_busqueda.dart';
import 'package:proyecto/compartidos/widgets/filtros_busqueda.dart';
import 'package:proyecto/compartidos/widgets/tarjeta_lugar.dart';
import 'package:proyecto/modulos/busqueda/lugarelegido_pantalla.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),

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

            BarraBusqueda(
              onChanged: (valor) {
                setState(() {
                  query = valor;
                });
              },
            ),

            const SizedBox(height: 12),

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

            Expanded(
              child: ListView(
                children: [
                  TarjetaLugar(
                    nombre: "Teotihuacán",
                    ubicacion: "Estado de México",
                    lat: 19.6925,
                    lng: -98.8430,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LugarelegidoPantalla(
                            nombre: "Teotihuacán",
                            ubicacion: "Estado de México",
                            lat: 19.6925,
                            lng: -98.8430,
                          ),
                        ),
                      );
                    },
                  ),

                  TarjetaLugar(
                    nombre: "Chichén Itzá",
                    ubicacion: "Yucatán",
                    lat: 20.6843,
                    lng: -88.5678,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LugarelegidoPantalla(
                            nombre: "Chichén Itzá",
                            ubicacion: "Yucatán",
                            lat: 20.6843,
                            lng: -88.5678,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
