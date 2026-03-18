import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/modulos/viajes/crear_viaje_pantalla.dart';

class ExploracionPantalla extends StatelessWidget {
  const ExploracionPantalla({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(
                title: Text(
                  "Pack&Go",
                  style: GoogleFonts.poppins(fontSize: 36),
                ),
                centerTitle: true,
                backgroundColor: Colors.white,
                elevation: 0,
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "¡Tu app favorita de viajes!",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Text(
                  "Recomendaciones",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CrearViajePantalla(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    "Crear Viaje",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6A230),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
