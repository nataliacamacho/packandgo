import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/modulos/cuenta/editar_pantalla.dart';
import 'package:proyecto/modulos/cuenta/lista_viajes_pantalla.dart';
import 'package:proyecto/nucleo/servicios/usuario_servicio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CuentaPantalla extends StatelessWidget {
  const CuentaPantalla({super.key});

  // 🔥 Obtener viajes del usuario
  Stream<QuerySnapshot> obtenerViajesUsuario() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("Usuario no autenticado");
    }

    return FirebaseFirestore.instance
        .collection("viajes")
        .where("usuarioId", isEqualTo: user.uid)
        .snapshots();
  }

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
                      children: [
                        const SizedBox(height: 20),

                        // 👤 INFO USUARIO
                        Text(
                          "Mi Cuenta",
                          style: GoogleFonts.poppins(fontSize: 24),
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

                        // ✏️ EDITAR
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EditarPerfil()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF6A230),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            "Editar perfil",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),

                        const SizedBox(height: 30),

                        StreamBuilder<QuerySnapshot>(
                          stream: obtenerViajesUsuario(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }

                            final viajes = snapshot.data!.docs;
                            final hoy = DateTime.now();

                            // Filtrar y ordenar viajes futuros
                            final futuros =
                                viajes.where((viaje) {
                                  final inicio =
                                      (viaje["fechaInicio"] as Timestamp)
                                          .toDate();
                                  return inicio.isAfter(hoy) ||
                                      inicio.isAtSameMomentAs(hoy);
                                }).toList()..sort((a, b) {
                                  final fechaA = (a["fechaInicio"] as Timestamp)
                                      .toDate();
                                  final fechaB = (b["fechaInicio"] as Timestamp)
                                      .toDate();
                                  return fechaA.compareTo(
                                    fechaB,
                                  ); // del más cercano al más lejano
                                });

                            // Filtrar y ordenar viajes pasados
                            final pasados =
                                viajes.where((viaje) {
                                  final fin = (viaje["fechaFin"] as Timestamp)
                                      .toDate();
                                  return fin.isBefore(hoy) ||
                                      fin.isAtSameMomentAs(hoy);
                                }).toList()..sort((a, b) {
                                  final fechaA = (a["fechaFin"] as Timestamp)
                                      .toDate();
                                  final fechaB = (b["fechaFin"] as Timestamp)
                                      .toDate();
                                  return fechaB.compareTo(
                                    fechaA,
                                  ); // del más reciente al más lejano
                                });

                            return Column(
                              children: [
                                _botonSeccion(
                                  context,
                                  "Viajes futuros",
                                ),
                                const SizedBox(height: 15),
                                _botonSeccion(
                                  context,
                                  "Viajes pasados",
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 40),

                        // 🔴 CERRAR SESIÓN
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushReplacementNamed(context, '/inicio');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF6A230),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            "Cerrar sesión",
                            style: TextStyle(color: Colors.white),
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

  // 🔘 BOTONES DE SECCIÓN
  Widget _botonSeccion(BuildContext context, String titulo) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListaViajesPantalla(titulo: titulo),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(titulo, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  // 👤 INVITADO
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF6A230),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/registro');
              },
              child: const Text(
                "Crear cuenta",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
