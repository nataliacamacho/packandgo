import 'package:flutter/material.dart';
import 'modulos/autenticacion/pantalla_inicial.dart';
import 'modulos/autenticacion/login_pantalla.dart';
import 'modulos/exploracion/inicio_pantalla.dart';

class PackandGo extends StatelessWidget {
  const PackandGo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const PantallaInicial(),
        '/login': (context) => const LoginPantalla(),
        '/inicio': (context) => const InicioPantalla(),
      },
    );
  }
}
