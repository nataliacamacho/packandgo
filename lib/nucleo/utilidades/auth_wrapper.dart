import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto/compartidos/widgets/navegacion_principal.dart';
import 'package:proyecto/modulos/autenticacion/inicio_pantalla.dart';
import 'package:proyecto/nucleo/servicios/usuario_servicio.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initialized = false;
  String? _lastUid; // 👈 agregar esto

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          _initialized = false;
          _lastUid = null;
          return const LoginPantalla();
        }

        final user = snapshot.data!;

        // 👇 Si cambió el usuario, resetea el flag
        if (_lastUid != user.uid) {
          _initialized = false;
          _lastUid = user.uid;
        }

        if (!_initialized) {
          _initialized = true;

          Future.microtask(() async {
            await UsuarioServicio().crearUsuarioSiNoExiste(
              uid: user.uid,
              correo: user.email ?? '',
              nombreUsuario: user.displayName ?? 'Usuario',
            );
          });
        }

        return const NavegacionPrincipal();
      },
    );
  }
}
