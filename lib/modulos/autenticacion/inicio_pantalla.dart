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
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final UbicacionServicio ubicacionServicio = UbicacionServicio();

  String? errorCorreo;
  String? errorPassword;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    correoController.dispose();
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
      errorCorreo = null;
      errorPassword = null;
    });

    if (correoController.text.isEmpty) {
      setState(() => errorCorreo = "El correo es obligatorio");
      return;
    }

    if (passwordController.text.isEmpty) {
      setState(() => errorPassword = "La contraseña es obligatoria");
      return;
    }

    try {
      // 👇 Si hay sesión anónima activa, cerrarla primero
      final usuarioActual = FirebaseAuth.instance.currentUser;
      if (usuarioActual != null && usuarioActual.isAnonymous) {
        await FirebaseAuth.instance.signOut();
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correoController.text.trim(),
        password: passwordController.text.trim(),
      );

      await obtenerUbicacion();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setState(() => errorCorreo = "No existe una cuenta con este correo");
      } else if (e.code == 'invalid-email') {
        setState(() => errorCorreo = "El formato del correo es incorrecto");
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        setState(() => errorPassword = "La contraseña es incorrecta");
      } else {
        setState(() => errorCorreo = "Error: ${e.code}");
      }
    } catch (e) {
      setState(() => errorCorreo = "Error inesperado: $e");
      debugPrint("❌ ERROR LOGIN: $e");
    }
  }

  Future<void> entrarComoInvitado() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      await obtenerUbicacion();

      // ❌ ELIMINAR navegación
      // Navigator.pushReplacementNamed(context, '/exploracion');
    } on FirebaseAuthException {
      setState(() {
        errorCorreo = "Error al ingresar como invitado";
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
                              controller: correoController,
                              onChanged: (_) {
                                setState(() {
                                  errorCorreo = null;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: "Correo electrónico",
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),

                            if (errorCorreo != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  left: 10,
                                ),
                                child: Text(
                                  errorCorreo!,
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
                                    Navigator.pushNamed(
                                      context,
                                      '/registro',
                                    );
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
