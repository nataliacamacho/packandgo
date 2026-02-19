import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/modulos/busqueda/busqueda_pantalla.dart';
import 'package:proyecto/modulos/cuenta/cuenta_pantalla.dart';
import 'package:proyecto/modulos/viajes/viajes_pantalla.dart';

class ExploracionPantalla extends StatefulWidget {
  const ExploracionPantalla({super.key});

  @override
  State<ExploracionPantalla> createState() => _ExploracionPantallaState();
}

class _ExploracionPantallaState extends State<ExploracionPantalla> {
  int _paginaActual = 0;

  late final List<Widget> _paginas;

  @override
  void initState() {
    super.initState();

    _paginas = [
      const _ExploracionContenido(),
      const BusquedaPantalla(),
      const ViajesPantalla(),
      const CuentaPantalla(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _paginas[_paginaActual],

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0066D2),
        currentIndex: _paginaActual,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        iconSize: 35,
        onTap: (index) {
          setState(() {
            _paginaActual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Explorar",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Búsqueda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet_travel),
            label: "Viajes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Cuenta",
          ),
        ],
      ),
    );
  }
}

class _ExploracionContenido extends StatelessWidget {
  const _ExploracionContenido({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBar(
              title: Text(
                "Pack&Go",
                style: GoogleFonts.poppins(
                  fontSize: 36,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
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
                style: GoogleFonts.poppins(
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 40),

            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  "Crear Viaje",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF6A230),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 15),
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
    );
  }
}
