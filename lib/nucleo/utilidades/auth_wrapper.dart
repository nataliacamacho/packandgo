import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto/compartidos/widgets/navegacion_principal.dart';
import 'package:proyecto/modulos/autenticacion/inicio_pantalla.dart';
import 'package:proyecto/nucleo/servicios/usuario_servicio.dart';

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

        // ❌ NO logueado
        if (!snapshot.hasData) {
          return const LoginPantalla();
        }

        final user = snapshot.data!;

        // 🔥 AQUÍ HACEMOS LA MAGIA AUTOMÁTICA
        return FutureBuilder(
          future: UsuarioServicio().crearUsuarioSiNoExiste(
            uid: user.uid,
            correo: user.email ?? '',
            nombreUsuario: user.displayName ?? 'Usuario',
          ),
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // ✅ YA EXISTE / YA SE CREÓ
            return const NavegacionPrincipal();
          },
        );
      },
    );
  }
}