import 'package:flutter/material.dart';
import 'widgets/selector_transporte.dart';

class TransportePantalla extends StatelessWidget {
  final String destino;

  const TransportePantalla({
    super.key,
    required this.destino,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: const Color(0xFFF6A230),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),

          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 15),

                  const Center(
                    child: Text(
                      "Opciones de\nTransporte",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

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
          ),
        ),
      ),

      body: const SelectorTransporte(),
    );
  }
}