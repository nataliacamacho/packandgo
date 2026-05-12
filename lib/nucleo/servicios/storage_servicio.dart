import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageServicio {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> subirImagenViaje(File imagen, String idViaje) async {
    final ref = _storage.ref().child('viajes/$idViaje.jpg');

    await ref.putFile(imagen);

    return await ref.getDownloadURL();
  }
}