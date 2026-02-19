import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPantalla extends StatelessWidget {
  const LoginPantalla({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0066D2),
     
      appBar: AppBar(
        title: Text("Pack&Go", style: GoogleFonts.poppins(fontSize: 36, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0066D2),
        elevation: 0,
      ),

      body: Column (
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          SizedBox(height: 40),

           Padding(
            padding: const EdgeInsets.only(left: 22, bottom: 15),
            child: Text(
              "Inicio de Sesión",
              style: GoogleFonts.poppins(
                fontSize: 25,
                color: Colors.white,
                ),
            ),
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),

              child: Column(
                children: [

                  //Usuario
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Usuario",
                      filled: true,
                      fillColor: Colors.grey[200],
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  //Contraseña
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Contraseña",
                      filled: true,
                      fillColor: Colors.grey[200],
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: 150,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        //LOGICA
                        Navigator.pushReplacementNamed(context, '/exploracion');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF6A230),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text("Ingresar",
                        style: GoogleFonts.poppins(color: Colors.white),
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

                      //Crear cuenta
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/registro');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.only(left: 8),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
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
        ]
      )
    );
  }
}
