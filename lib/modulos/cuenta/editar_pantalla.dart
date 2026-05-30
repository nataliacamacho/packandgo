import 'package:cloud_firestore/cloud_firestore.dart';
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
  late TextEditingController correoController;

  late TextEditingController passwordActualController;
  late TextEditingController nuevaPasswordController;

  bool cargando = false;

  @override
  void initState() {
    super.initState();
    usuarioController = TextEditingController();
    correoController = TextEditingController();

    passwordActualController = TextEditingController();
    nuevaPasswordController = TextEditingController();

    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    if (user == null) return;
    final snapshot = await usuarioServicio.obtenerDatosUsuario();
    if (snapshot.exists) {
      final datos = snapshot.data()!;
      usuarioController.text = datos['nombreUsuario'] ?? '';
      correoController.text = datos['correo'] ?? '';
    }
  }

  Future<void> _guardarCambios() async {
    if (user == null) return;

    setState(() {
      cargando = true;
    });

    try {
      final nuevoCorreo = correoController.text.trim();
      final nuevoUsuario = usuarioController.text.trim().toLowerCase();

      final nuevaPassword = nuevaPasswordController.text.trim();

      final passwordActual = passwordActualController.text.trim();

      final quiereCambiarCorreo = nuevoCorreo != user!.email;

      final quiereCambiarPassword = nuevaPassword.isNotEmpty;

      // VALIDAR PASSWORD ACTUAL
      if ((quiereCambiarCorreo || quiereCambiarPassword) &&
          passwordActual.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa tu contraseña actual')),
        );

        setState(() {
          cargando = false;
        });

        return;
      }

      // REAUTENTICAR
      if (quiereCambiarCorreo || quiereCambiarPassword) {
        final cred = EmailAuthProvider.credential(
          email: user!.email!,
          password: passwordActual,
        );

        await user!.reauthenticateWithCredential(cred);
      }

      // VALIDAR CORREO REPETIDO
      final metodos = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
        nuevoCorreo,
      );

      if (metodos.isNotEmpty && nuevoCorreo != user!.email) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ese correo ya está registrado')),
        );

        setState(() {
          cargando = false;
        });

        return;
      }
      if (quiereCambiarCorreo) {
        await user!.verifyBeforeUpdateEmail(nuevoCorreo);

        // 👇 Guarda el correo nuevo como pendiente en Firestore
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user!.uid)
            .update({'correoPendiente': nuevoCorreo});

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Se envió verificación a $nuevoCorreo. '
              'Verifica tu correo y vuelve a iniciar sesión.',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          cargando = false;
        });
        return;
      }

      // CAMBIAR CORREO
      // CAMBIAR CORREO
      if (quiereCambiarCorreo) {
        await user!.verifyBeforeUpdateEmail(nuevoCorreo);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Se envió verificación a $nuevoCorreo. '
              'Verifica tu correo y vuelve a iniciar sesión para aplicar el cambio.',
            ),
            duration: Duration(seconds: 5),
          ),
        );

        // NO cerrar sesión aquí — el usuario sigue activo con el correo anterior
        // El cambio se aplica cuando verifique el enlace e inicie sesión de nuevo
        setState(() {
          cargando = false;
        });
        return;
      }

      // CAMBIAR PASSWORD
      if (quiereCambiarPassword) {
        await user!.updatePassword(nuevaPassword);
      }

      // ACTUALIZAR USUARIO EN FIRESTORE
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .update({'nombreUsuario': nuevoUsuario});

      await user!.updateDisplayName(nuevoUsuario);

      if (!quiereCambiarCorreo) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos actualizados correctamente')),
        );
      }

      passwordActualController.clear();
      nuevaPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${e.code} - ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  @override
  void dispose() {
    usuarioController.dispose();
    correoController.dispose();
    passwordActualController.dispose();
    nuevaPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text("Pack&Go", style: GoogleFonts.poppins(fontSize: 36)),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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

                          Column(
                            children: [
                              TextField(
                                controller: correoController,
                                enabled: true,
                                decoration: const InputDecoration(
                                  labelText: 'Correo',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),

                              TextField(
                                controller: passwordActualController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Contraseña actual',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),

                              TextField(
                                controller: nuevaPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Nueva contraseña',
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
                                onPressed: cargando ? null : _guardarCambios,
                                child: cargando
                                    ? const CircularProgressIndicator(
                                        color: Color.fromARGB(
                                          255,
                                          255,
                                          255,
                                          255,
                                        ),
                                      )
                                    : const Text(
                                        'Guardar cambios',
                                        style: TextStyle(
                                          color: Color.fromARGB(
                                            255,
                                            255,
                                            255,
                                            255,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
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
