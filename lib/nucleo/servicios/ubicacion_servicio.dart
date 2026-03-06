import 'package:geolocator/geolocator.dart';

class UbicacionServicio {
  Future<bool> solicitarPermiso() async {

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> obtenerUbicacionActual() async {

    bool permiso = await solicitarPermiso();

    if (!permiso) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

}