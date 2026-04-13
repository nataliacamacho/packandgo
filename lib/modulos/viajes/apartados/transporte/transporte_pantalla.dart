import 'package:flutter/material.dart';
import 'package:proyecto/modulos/viajes/apartados/transporte/widgets/selector_transporte.dart';

class TransportePantalla extends StatelessWidget {
  final String destino;
  final double destinoLat;
  final double destinoLng;

  const TransportePantalla({
    super.key,
    required this.destino,
    required this.destinoLat,
    required this.destinoLng,
  });

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
              decoration: const BoxDecoration(
                color: Color(0xFFF6A230),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [

                  const SizedBox(height: 20),

                  Center(
                      child: Text(
                        "Opciones de \nTransporte",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ),

                  const SizedBox(height: 10),

                  // 🔥 DESTINO ABAJO IZQUIERDA
                  Text(
                    destino,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
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
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: SelectorTransporte(
          destinoLat: destinoLat,
          destinoLng: destinoLng,
          destinoNombre: destino,
        ),
      ),
    );
  }
}