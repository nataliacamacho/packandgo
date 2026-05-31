import 'package:flutter/material.dart';
import 'package:proyecto/nucleo/utilidades/auth_wrapper.dart';
import 'modulos/autenticacion/login_pantalla.dart';
import 'modulos/exploracion/exploracion_pantalla.dart';
import 'modulos/autenticacion/registro_pantalla.dart';
import 'modulos/cuenta/editar_pantalla.dart';
import 'package:google_fonts/google_fonts.dart';

class PackandGo extends StatelessWidget {
  const PackandGo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),

      home: const AuthWrapper(),

      routes: {
        '/inicio': (context) => const LoginPantalla(),
        '/registro': (context) => const RegistroPantalla(),
        '/exploracion': (context) => ExploracionPantalla(),
        '/EditarPerfil': (context) => const EditarPerfil(),
      },
    );
  }
}
