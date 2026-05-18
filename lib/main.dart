import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. CARGAR PRIMERO EL .ENV
  await dotenv.load(fileName: ".env");

  // 2. Inicializar Firebase y Mapbox después
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Asegúrate de pasar el token guardado en tu .env aquí también
  String mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? "";
  MapboxOptions.setAccessToken(mapboxToken);

  runApp(const PackandGo());
}