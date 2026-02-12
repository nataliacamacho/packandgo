import 'package:flutter/material.dart';

class InicioPantalla extends StatelessWidget {
  const InicioPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
      ),
      body: const Center(
        child: Text(
          "Bienvenida a PackandGo",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
