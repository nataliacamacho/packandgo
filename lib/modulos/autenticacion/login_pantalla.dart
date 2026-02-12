import 'package:flutter/material.dart';

class LoginPantalla extends StatelessWidget {
  const LoginPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Iniciar Sesión"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/inicio');
          },
          child: const Text("Entrar"),
        ),
      ),
    );
  }
}
