import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';

Future<void> main() async {
  

  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env"); 
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  

  MapboxOptions.setAccessToken('');
  if (!kIsWeb) {
    MapboxOptions.setAccessToken(dotenv.env['MAPBOX_ACCESS_TOKEN']?.trim() ?? '');
  }

  runApp(const PackandGo());
}
