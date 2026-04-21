import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto/compartidos/widgets/navegacion_principal.dart';
import 'package:proyecto/modulos/autenticacion/inicio_pantalla.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🔄 Cargando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ NO logueado → login
        if (!snapshot.hasData) {
          return const LoginPantalla();
        }

        // ✅ LOGUEADO → SIEMPRE entra aquí
        return const NavegacionPrincipal();
      },
    );
  }
}