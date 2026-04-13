import 'package:geolocator/geolocator.dart';

class UbicacionServicio {
  /// Devuelve la ubicación actual del usuario
  /// Puede retornar null si el GPS está desactivado o permisos denegados
  Future<Position?> obtenerUbicacionActual() async {
    // 1️⃣ Verifica que el servicio de ubicación esté activado
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    print("🛰️ Servicio activo: $servicioActivo");

    if (!servicioActivo) {
      print("❌ GPS desactivado");
      return null;
    }

    // 2️⃣ Verifica permisos
    LocationPermission permiso = await Geolocator.checkPermission();
    print("🔐 Permiso inicial: $permiso");

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      print("📩 Permiso solicitado: $permiso");

      if (permiso == LocationPermission.denied) {
        print("❌ Permiso de ubicación denegado");
        return null;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      print("🚫 Permiso denegado permanentemente");
      return null;
    }

    // 3️⃣ Obtiene la posición actual
    try {
      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("📍 Ubicación obtenida:");
      print("Lat: ${posicion.latitude}, Lng: ${posicion.longitude}");

      return posicion;
    } catch (e) {
      print("❌ Error al obtener la ubicación: $e");
      return null;
    }
  }

  // ===============================
  // 🔥 Obtener solo coordenadas
  // ===============================
  Future<Map<String, double>?> obtenerCoordenadas() async {
    final posicion = await obtenerUbicacionActual();

    if (posicion == null) return null;

    return {
      'lat': posicion.latitude,
      'lng': posicion.longitude,
    };
  }

  // ===============================
  // 🔥 Calcular distancia en KM
  // ===============================
  double calcularDistanciaEnKm({
    required double origenLat,
    required double origenLng,
    required double destinoLat,
    required double destinoLng,
  }) {
    final distanciaMetros = Geolocator.distanceBetween(
      origenLat,
      origenLng,
      destinoLat,
      destinoLng,
    );

    final distanciaKm = distanciaMetros / 1000;

    print("📏 Distancia calculada: ${distanciaKm.toStringAsFixed(2)} km");

    return distanciaKm;
  }

  // ===============================
  // 🔥 Validar si es viable en carro
  // ===============================
  bool esRutaValidaEnCarro(double distanciaKm) {
    final esValida = distanciaKm <= 500;

    print("🚗 ¿Ruta válida en carro?: $esValida");

    return esValida;
  }
}