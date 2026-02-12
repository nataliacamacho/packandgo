import 'package:flutter/material.dart';

class PantallaInicial extends StatefulWidget {
  const PantallaInicial({super.key});

  @override
  State<PantallaInicial> createState() => _PantallaInicialState();
}

class _PantallaInicialState extends State<PantallaInicial> {

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Por ahora siempre enviamos al login.
    // Aquí después irá FirebaseAuth.instance.currentUser
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "PackandGo",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
