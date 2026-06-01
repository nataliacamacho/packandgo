import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class UbicacionServicio {
  static Position? _cachedPosition;
  static String? _cachedCiudad;

  /// ===============================
  /// OBTENER UBICACIÓN ACTUAL
  /// ===============================
  Future<Position?> obtenerUbicacionActual() async {
    // USAR CACHE
    if (_cachedPosition != null) {
      print(" Usando ubicación cacheada");
      return _cachedPosition;
    }

    bool servicioActivo = await Geolocator.isLocationServiceEnabled();

    if (!servicioActivo) {
      print(" GPS desactivado");
      return null;
    }

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();

      if (permiso == LocationPermission.denied) {
        print(" Permiso denegado");
        return null;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      print("Permiso denegado permanentemente");
      return null;
    }

    try {
      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      //  GUARDAR CACHE
      _cachedPosition = posicion;

      print("📍 Nueva ubicación obtenida");
      print("Lat: ${posicion.latitude}");
      print("Lng: ${posicion.longitude}");

      return posicion;
    } catch (e) {
      print("Error ubicación: $e");
      return null;
    }
  }

  /// ===============================
  ///  COORDENADAS
  /// ===============================
  Future<Map<String, double>?> obtenerCoordenadas() async {
    final posicion = await obtenerUbicacionActual();

    if (posicion == null) return null;

    return {'lat': posicion.latitude, 'lng': posicion.longitude};
  }

  /// ===============================
  ///  CIUDAD ACTUAL
  /// ===============================
  Future<String?> obtenerCiudadActual() async {
    // CACHE CIUDAD
    if (_cachedCiudad != null) {
      print(" Usando ciudad cacheada");
      return _cachedCiudad;
    }

    final posicion = await obtenerUbicacionActual();

    if (posicion == null) return null;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        posicion.latitude,
        posicion.longitude,
      );

      final ciudad = placemarks.first.locality;

      _cachedCiudad = ciudad;

      print(" Ciudad detectada: $ciudad");

      return ciudad;
    } catch (e) {
      print(" Error ciudad: $e");
      return null;
    }
  }

  /// ===============================
  /// DISTANCIA
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

    return distanciaMetros / 1000;
  }

  /// ===============================
  /// VALIDAR CARRO
  /// ===============================
  bool esRutaValidaEnCarro(double distanciaKm) {
    return distanciaKm <= 500;
  }

  /// ===============================
  /// LIMPIAR CACHE
  /// ===============================
  static void limpiarCache() {
    _cachedPosition = null;
    _cachedCiudad = null;
  }
}
