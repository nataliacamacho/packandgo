import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto/nucleo/servicios/ubicacion_servicio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPantalla extends StatefulWidget {
  const LoginPantalla({super.key});

  @override
  State<LoginPantalla> createState() => _LoginPantallaState();
}

class _LoginPantallaState extends State<LoginPantalla> {
  final TextEditingController UsuarioController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final UbicacionServicio ubicacionServicio = UbicacionServicio();

  String? errorUsuario;
  String? errorPassword;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    UsuarioController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  //ya no es necesario, pero lo dejo por si acaso
  void inyectarListaNegra() async {
    List<String> listaMala = [
      'pendejo',
      'pendeja',
      'pendejos',
      'pendejas',
      'cabron',
      'cabrón',
      'cabrona',
      'cabrones',
      'puto',
      'puta',
      'putos',
      'putas',
      'mierda',
      'mierdas',
      'pinche',
      'pinches',
      'idiota',
      'idiotas',
      'estupido',
      'estúpido',
      'estupida',
      'estúpida',
      'imbecil',
      'imbécil',
      'imbeciles',
      'verga',
      'v3rga',
      'pito',
      'culo',
      'culero',
      'culera',
      'mamada',
      'mamadas',
      'chingar',
      'chinga',
      'chingas',
      'chingada',
      'chingado',
      'chingaquedito',
    ];

    try {
      await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('filtros_comunidad')
          .set(
            {'palabras_prohibidas': listaMala},
            SetOptions(merge: true),
          ); // merge evita que borres otros campos si ya los tenías

      print("✅ ¡Lista negra inyectada en Firebase de un solo golpe!");
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  Future<void> obtenerUbicacion() async {
    final posicion = await ubicacionServicio.obtenerUbicacionActual();

    if (posicion != null) {
      debugPrint("Latitud: ${posicion.latitude}");
      debugPrint("Longitud: ${posicion.longitude}");
    } else {
      debugPrint("Usuario no permitió ubicación");
    }
  }

  Future<void> iniciarSesion() async {
    setState(() {
      errorUsuario = null;
      errorPassword = null;
    });

    if (UsuarioController.text.isEmpty) {
      setState(() => errorUsuario = "El nombre de usuario es obligatorio");
      return;
    }

    if (passwordController.text.isEmpty) {
      setState(() => errorPassword = "La contraseña es obligatoria");
      return;
    }

    try {
      final username = UsuarioController.text.trim().toLowerCase();
      final password = passwordController.text.trim();

      // Buscar usuario en Firestore
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('nombreUsuario', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() => errorUsuario = "No existe ese nombre de usuario");
        return;
      }

      final data = query.docs.first.data();
      final uid = query.docs.first.id;
      final emailActual = data['correo'] as String;
      final emailPendiente =
          data['correoPendiente'] as String?; // 👈 puede ser null

      // Cerrar sesión anónima si existe
      final usuarioActual = FirebaseAuth.instance.currentUser;
      if (usuarioActual != null && usuarioActual.isAnonymous) {
        await FirebaseAuth.instance.signOut();
      }

      UserCredential? credencial;

      // Intentar con correo actual primero
      try {
        credencial = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailActual,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        // Si falla Y hay un correo pendiente verificado, intentar con ese
        if ((e.code == 'invalid-credential' || e.code == 'wrong-password') &&
            emailPendiente != null) {
          try {
            credencial = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: emailPendiente,
              password: password,
            );
          } on FirebaseAuthException {
            setState(() => errorPassword = "La contraseña es incorrecta");
            return;
          }
        } else if (e.code == 'invalid-credential' ||
            e.code == 'wrong-password') {
          setState(() => errorPassword = "La contraseña es incorrecta");
          return;
        } else {
          setState(() => errorUsuario = "Error: ${e.code}");
          return;
        }
      }

      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      // Sincronizar Firestore con el correo real de Auth
      if (user != null && user.email != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .update({
              'correo': user.email,
              'correoPendiente': FieldValue.delete(), // 👈 limpia el pendiente
            });
      }

      await obtenerUbicacion();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        setState(() => errorPassword = "La contraseña es incorrecta");
      } else {
        setState(() => errorUsuario = "Error: ${e.code}");
      }
    } catch (e) {
      setState(() => errorUsuario = "Error inesperado");
      debugPrint("ERROR LOGIN: $e");
    }
  }

  Future<String?> obtenerEmailPorUsername(String username) async {
    final query = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('nombreUsuario', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return query.docs.first['correo'];
  }

  Future<void> entrarComoInvitado() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      await obtenerUbicacion();

      // ❌ ELIMINAR navegación
      // Navigator.pushReplacementNamed(context, '/exploracion');
    } on FirebaseAuthException {
      setState(() {
        errorUsuario = "Error al ingresar como invitado";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0066D2),

      appBar: AppBar(
        title: Text(
          "Pack&Go",
          style: GoogleFonts.poppins(fontSize: 36, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0066D2),
        elevation: 0,
      ),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.only(left: 22, bottom: 15),
              child: Text(
                "Inicio de Sesión",
                style: GoogleFonts.poppins(fontSize: 25, color: Colors.white),
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 40,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(35),
                            topRight: Radius.circular(35),
                          ),
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: UsuarioController,
                              onChanged: (_) {
                                setState(() {
                                  errorUsuario = null;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: "Nombre de Usuario",
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),

                            if (errorUsuario != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  left: 10,
                                ),
                                child: Text(
                                  errorUsuario!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 20),

                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              onChanged: (_) {
                                setState(() {
                                  errorPassword = null;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: "Contraseña",
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),

                            if (errorPassword != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  left: 10,
                                ),
                                child: Text(
                                  errorPassword!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 30),
                            //boton ingresar
                            Center(
                              child: SizedBox(
                                width: 150,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: iniciarSesion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF6A230),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: Text(
                                    "Ingresar",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),
                            //boton invitado
                            Center(
                              child: TextButton(
                                onPressed: entrarComoInvitado,
                                child: Text(
                                  "Continuar como invitado",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF0066D2),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "¿No tienes cuenta?",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),

                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/registro');
                                  },
                                  child: Text(
                                    "Crear cuenta",
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF0066D2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
