import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class RegistroPantalla extends StatefulWidget {
  const RegistroPantalla({super.key});

  @override
  State<RegistroPantalla> createState() => _RegistroPantallaState();
}

class _RegistroPantallaState extends State<RegistroPantalla> {

  final TextEditingController correoController = TextEditingController();
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? errorCorreo;
  String? errorUsuario;
  String? errorPassword;

  @override
  void dispose() {
    correoController.dispose();
    usuarioController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0066D2),


      appBar: AppBar(
        title: Text(
          "Pack&Go",
          style: GoogleFonts.poppins(fontSize: 36, color: const Color.fromARGB(255, 255, 255, 255)),
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
                "Crear Cuenta",
                style: GoogleFonts.poppins(
                  fontSize: 25,
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
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
                          color: Color.fromARGB(255, 255, 255, 255),
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
                                padding: const EdgeInsets.only(top: 5, left: 10),
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
                              controller: usuarioController,
                              onChanged: (_) {
                                setState(() {
                                  errorUsuario = null;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: "Usuario",
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
                                padding: const EdgeInsets.only(top: 5, left: 10),
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
                                padding: const EdgeInsets.only(top: 5, left: 10),
                                child: Text(
                                  errorPassword!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 30),

                            Center(
                              child: SizedBox(
                                width: 150,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () async {

                                    setState(() {
                                      errorCorreo = null;
                                      errorUsuario = null;
                                      errorPassword = null;
                                    });

                                    if (correoController.text.isEmpty) {
                                      setState(() {
                                        errorCorreo = "El correo es obligatorio";
                                      });
                                      return;
                                    }

                                    if (usuarioController.text.isEmpty) {
                                      setState(() {
                                        errorUsuario = "El usuario es obligatorio";
                                      });
                                      return;
                                    }

                                    if (passwordController.text.length < 6) {
                                      setState(() {
                                        errorPassword =
                                            "Debe tener mínimo 6 caracteres";
                                      });
                                      return;
                                    }

                                    try {

                                      UserCredential credencial =
                                          await FirebaseAuth.instance
                                              .createUserWithEmailAndPassword(
                                        email: correoController.text.trim(),
                                        password:
                                            passwordController.text.trim(),
                                      );

                                      await FirebaseFirestore.instance
                                          .collection("usuarios")
                                          .doc(credencial.user!.uid)
                                          .set({
                                        "uid": credencial.user!.uid,
                                        "correo":
                                            correoController.text.trim(),
                                        "nombreUsuario":
                                            usuarioController.text.trim(),
                                        "fechaRegistro": DateTime.now(),
                                      });

                                      if (!context.mounted) return;

                                      Navigator.pushReplacementNamed(
                                          context, '/inicio');

                                    } on FirebaseAuthException catch (e) {

                                      if (e.code == 'email-already-in-use') {
                                        setState(() {
                                          errorCorreo =
                                              "Este correo ya está registrado";
                                        });
                                      } else if (e.code == 'invalid-email') {
                                        setState(() {
                                          errorCorreo = "Correo inválido";
                                        });
                                      } else if (e.code == 'weak-password') {
                                        setState(() {
                                          errorPassword =
                                              "La contraseña es muy débil";
                                        });
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF6A230),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: Text(
                                    "Crear cuenta",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "¿Ya tienes cuenta?",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                        context, '/inicio');
                                  },
                                  child: Text(
                                    "Iniciar sesión",
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