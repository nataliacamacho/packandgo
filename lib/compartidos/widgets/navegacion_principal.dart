import 'package:flutter/material.dart';
import 'package:proyecto/modulos/cuenta/lista_viajes_pantalla.dart';
import 'package:proyecto/modulos/exploracion/exploracion_pantalla.dart';
import 'package:proyecto/modulos/busqueda/busqueda_pantalla.dart';
import 'package:proyecto/modulos/viajes/crear_viaje_pantalla.dart';
import 'package:proyecto/modulos/viajes/viajes_pantalla.dart';
import 'package:proyecto/modulos/cuenta/cuenta_pantalla.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto/modulos/viajes/detalle_viaje_pantalla.dart';
import 'package:proyecto/nucleo/utilidades/viaje_estado.dart';

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
    CrearViajePantalla(),
    ViajesPantalla(),
    CuentaPantalla(),
  ];

  Future<void> _abrirViajeInteligente(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("viajes")
        .where("usuarioId", isEqualTo: user.uid)
        .get();
    final viajes = snapshot.docs.where((doc) {
      final data = doc.data();
      return data['cancelado'] != true;
    }).toList();
    final hoy = DateTime.now();

    // 🔥 VIAJE ACTUAL
    final actuales = viajes.where((viaje) {
      final inicio = (viaje["fechaInicio"] as Timestamp).toDate();
      final fin = (viaje["fechaFin"] as Timestamp).toDate();

      return hoy.isAfter(inicio.subtract(const Duration(days: 1))) &&
          hoy.isBefore(fin.add(const Duration(days: 1)));
    }).toList();

    if (actuales.length == 1) {
      final viaje = actuales.first;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleViajePantalla(
            nombre: viaje["destino"],
            fechaInicio: (viaje["fechaInicio"] as Timestamp).toDate(),
            fechaFin: (viaje["fechaFin"] as Timestamp).toDate(),
            descripcion: viaje["descripcion"] ?? "",
            idViaje: viaje.id,
            destino: viaje["destino"] ?? "",
            origen: viaje["origen"] ?? "",

            // 🔥 AQUÍ ESTABA EL ERROR
            destinoLat: viaje["lat"],
            destinoLng: viaje["lng"],
          ),
        ),
      );
      return;
    }

    if (actuales.length > 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ListaViajesPantalla(tipo: EstadoViaje.actual),
        ),
      );
      return;
    }

    // 🔥 VIAJE MÁS CERCANO
    final futuros = viajes.where((viaje) {
      final inicio = (viaje["fechaInicio"] as Timestamp).toDate();
      return inicio.isAfter(hoy);
    }).toList();

    futuros.sort((a, b) {
      final aFecha = (a["fechaInicio"] as Timestamp).toDate();
      final bFecha = (b["fechaInicio"] as Timestamp).toDate();
      return aFecha.compareTo(bFecha);
    });

    if (futuros.isNotEmpty) {
      final viaje = futuros.first;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleViajePantalla(
            nombre: viaje["destino"],
            fechaInicio: (viaje["fechaInicio"] as Timestamp).toDate(),
            fechaFin: (viaje["fechaFin"] as Timestamp).toDate(),
            descripcion: viaje["descripcion"] ?? "",
            idViaje: viaje.id,
            destino: viaje["destino"] ?? "",
            origen: viaje["origen"] ?? "",

            // 🔥 AQUÍ ESTABA EL ERROR
            destinoLat: viaje["lat"],
            destinoLng: viaje["lng"],
          ),
        ),
      );
      return;
    }

    // ❌ SI NO HAY NADA
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No tienes viajes disponibles")),
    );

    print("🔥 TOTAL VIAJES: ${viajes.length}");
    print("🔥 HOY: $hoy");
    print("🔥 ACTUALES: ${actuales.length}");
    print("🔥 FUTUROS: ${futuros.length}");
  }

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
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0066D2),
        selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        unselectedItemColor: const Color.fromARGB(179, 255, 255, 255),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _paginaActual,

        onTap: (index) async {
          if (index == 3) {
            await _abrirViajeInteligente(context);
          } else {
            setState(() {
              _paginaActual = index;
            });
          }
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 32), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 32),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box, size: 32),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.luggage, size: 32),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 32),
            label: '',
          ),
        ],
      ),
    );
  }
}
