import 'package:geolocator/geolocator.dart';

class UbicacionServicio {
  /// Devuelve la ubicación actual del usuario
  /// Puede retornar null si el GPS está desactivado o permisos denegados
  Future<Position?> obtenerUbicacionActual() async {
    // 1️⃣ Verifica que el servicio de ubicación esté activado
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      print("GPS desactivado");
      return null;
    }

    // 2️⃣ Verifica permisos
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        print("Permiso de ubicación denegado");
        return null;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      print("Permiso de ubicación denegado permanentemente");
      return null;
    }

    // 3️⃣ Obtiene la posición actual
    try {
      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return posicion;
    } catch (e) {
      print("Error al obtener la ubicación: $e");
      return null;
    }
  }
}