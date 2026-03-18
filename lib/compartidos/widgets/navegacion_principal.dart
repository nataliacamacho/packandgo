import 'package:flutter/material.dart';
import 'package:proyecto/modulos/exploracion/exploracion_pantalla.dart';
import 'package:proyecto/modulos/busqueda/busqueda_pantalla.dart';
import 'package:proyecto/modulos/viajes/viajes_pantalla.dart';
import 'package:proyecto/modulos/cuenta/cuenta_pantalla.dart';

class NavegacionPrincipal extends StatefulWidget {
  final int paginaInicial;

  const NavegacionPrincipal({super.key, this.paginaInicial = 0});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {

  late int _paginaActual;

  final List<Widget> _paginas = const [
    ExploracionPantalla(),
    BusquedaPantalla(),
    ViajesPantalla(),
    CuentaPantalla(),
  ];

  @override
  void initState() {
    super.initState();
    _paginaActual = widget.paginaInicial;
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
        unselectedItemColor: Colors.white60,
        iconSize: 30,
        onTap: (index) {
          setState(() {
            _paginaActual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Explorar"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Búsqueda"),
          BottomNavigationBarItem(icon: Icon(Icons.wallet_travel), label: "Viajes"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Cuenta"),
        ],
      ),
    );
  }
}