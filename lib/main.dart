import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Este es el archivo que se generó solito

void main() async {
  // 1. Aseguramos que el motor de Flutter esté listo
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Inicializamos Firebase con la configuración automática
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pack&Go México',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Por ahora mostramos una pantalla simple para ver que funciona
      home: const Scaffold(
        body: Center(
          child: Text(
            '¡Pack&Go Conectado a Firebase!', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}