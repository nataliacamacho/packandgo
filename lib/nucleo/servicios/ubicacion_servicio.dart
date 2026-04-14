import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class UbicacionServicio {
  /// ===============================
  /// 📍 OBTENER UBICACIÓN ACTUAL
  /// ===============================
  Future<Position?> obtenerUbicacionActual() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    print("🛰️ Servicio activo: $servicioActivo");

    if (!servicioActivo) {
      print("❌ GPS desactivado");
      return null;
    }

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

  /// ===============================
  /// 📦 COORDENADAS SIMPLES
  /// ===============================
  Future<Map<String, double>?> obtenerCoordenadas() async {
    final posicion = await obtenerUbicacionActual();

    if (posicion == null) return null;

    return {'lat': posicion.latitude, 'lng': posicion.longitude};
  }

  /// ===============================
  /// 🏙️ OBTENER CIUDAD ACTUAL
  /// ===============================
  Future<String?> obtenerCiudadActual() async {
    final posicion = await obtenerUbicacionActual();

    if (posicion == null) return null;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        posicion.latitude,
        posicion.longitude,
      );

      final ciudad = placemarks.first.locality;

      print("🏙️ Ciudad detectada: $ciudad");

      return ciudad;
    } catch (e) {
      print("❌ Error obteniendo ciudad: $e");
      return null;
    }
  }

  /// ===============================
  /// 📏 DISTANCIA EN KM
  /// ===============================
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

  /// ===============================
  /// 🚗 VALIDAR RUTA EN CARRO
  /// ===============================
  bool esRutaValidaEnCarro(double distanciaKm) {
    final esValida = distanciaKm <= 500;

    print("🚗 ¿Ruta válida en carro?: $esValida");

    return esValida;
  }
}
