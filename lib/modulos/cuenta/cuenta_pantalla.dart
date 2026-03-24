import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/modulos/cuenta/editar_pantalla.dart';
import 'package:proyecto/nucleo/servicios/usuario_servicio.dart';

class CuentaPantalla extends StatelessWidget {
  const CuentaPantalla({super.key});


  @override
  Widget build(BuildContext context) {
    final usuarioServicio = UsuarioServicio();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Pack&Go", style: GoogleFonts.poppins(fontSize: 36)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text("No hay sesión iniciada"))
            : user.isAnonymous
            ? _vistaInvitado(context)
            : FutureBuilder(
                future: usuarioServicio.obtenerDatosUsuario(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text("Error al cargar datos"));
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                      child: Text("No se encontraron datos del usuario"),
                    );
                  }

                  final datos = snapshot.data!.data()!;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Mi Cuenta",
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                datos['nombreUsuario'] ?? "",
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),

                              const SizedBox(height: 5),
                              Text(
                                datos['correo'] ?? "",
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),

                              const SizedBox(height: 5),
                              Text(datos['contraseña'] ?? "*******"),

                              const SizedBox(height: 30),

                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditarPerfil(),));
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF6A230),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                child: Text("Editar perfil", style: GoogleFonts.poppins(
                                      color: const Color.fromARGB(255, 255, 255, 255)),
                              ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _vistaInvitado(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Estás navegando como invitado",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              "Crea una cuenta para guardar viajes, reseñas y personalizar tu experiencia.",
              style: GoogleFonts.poppins(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/registro');
              },
              child: const Text("Crear cuenta"),
            ),
          ],
        ),
      ),
    );
  }
}
