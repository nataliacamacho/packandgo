import 'package:flutter/material.dart';
import 'modulos/autenticacion/inicio_pantalla.dart';
import 'modulos/exploracion/exploracion_pantalla.dart';
import 'modulos/autenticacion/registro_pantalla.dart';
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
        ),
      initialRoute: '/inicio',
      routes: {
        '/inicio': (context) => const LoginPantalla(),
        '/registro': (context) => const RegistroPantalla(),
        '/exploracion': (context) => ExploracionPantalla(),
      },
    );
  }
}
