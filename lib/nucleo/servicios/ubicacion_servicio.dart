import 'package:geolocator/geolocator.dart';

class UbicacionServicio {

  Future<Position?> obtenerUbicacionActual() async {

    bool servicioActivo = await Geolocator.isLocationServiceEnabled();

    if (!servicioActivo) {
      print("GPS desactivado");
      return null;
    }

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();

      if (permiso == LocationPermission.denied) {
        print("Permiso denegado");
        return null;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      print("Permiso denegado permanentemente");
      return null;
    }

    Position posicion = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return posicion;
  }
}