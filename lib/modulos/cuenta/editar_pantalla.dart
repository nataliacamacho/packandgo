// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/nucleo/servicios/usuario_servicio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditarPerfil extends StatefulWidget {
  const EditarPerfil({super.key});

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  final usuarioServicio = UsuarioServicio();
  final user = FirebaseAuth.instance.currentUser;

  late TextEditingController usuarioController;
  late TextEditingController passwordController;
  late TextEditingController correoController;

  bool cargando = false;

  @override
  void initState() {
    super.initState();
    usuarioController = TextEditingController();
    passwordController = TextEditingController();
    correoController = TextEditingController();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    if (user == null) return;
    final snapshot = await usuarioServicio.obtenerDatosUsuario();
    if (snapshot.exists) {
      final datos = snapshot.data()!;
      usuarioController.text = datos['nombreUsuario'] ?? '';
      passwordController.text = datos['password'] ?? '';
      correoController.text = datos['correo'] ?? '';
    }
  }

  Future<void> _guardarCambios() async {
    if (user == null) return;
    setState(() {
      cargando = true;
    });
    try {
      await usuarioServicio.actualizarUsuario(
        nombreUsuario: usuarioController.text.trim(),
        nuevaPassword: passwordController.text.trim(),
        correo: correoController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos actualizados correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar datos: $e')));
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  @override
  void dispose() {
    usuarioController.dispose();
    passwordController.dispose();
    correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "Editar Información",
                            style: GoogleFonts.poppins(fontSize: 24),
                          ),
                          const SizedBox(height: 30),
                          FutureBuilder(
                            future: usuarioServicio.obtenerDatosUsuario(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }
                              if (snapshot.hasError) {
                                return const Text("Error al cargar datos");
                              }
                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return const Text(
                                  "No se encontraron datos del usuario",
                                );
                              }
                              return Column(
                                children: [
                                  TextField(
                                    controller: correoController,
                                    enabled: false,
                                    decoration: const InputDecoration(
                                      labelText: 'Correo',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: passwordController,
                                    decoration: const InputDecoration(
                                      labelText: 'Contraseña',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: usuarioController,
                                    decoration: const InputDecoration(
                                      labelText: 'Usuario',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF6A230),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    onPressed: cargando
                                        ? null
                                        : _guardarCambios,
                                    child: cargando
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : const Text('Guardar cambios', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
