import '../../../nucleo/servicios/ubicacion_servicio.dart';

class TransporteLogica {
  final UbicacionServicio _ubicacionServicio = UbicacionServicio();

  Future<bool> puedeUsarCarro({
    required double destinoLat,
    required double destinoLng,
  }) async {
    final coords = await _ubicacionServicio.obtenerCoordenadas();

    if (coords == null) return false;

    final distancia = _ubicacionServicio.calcularDistanciaEnKm(
      origenLat: coords['lat']!,
      origenLng: coords['lng']!,
      destinoLat: destinoLat,
      destinoLng: destinoLng,
    );

    return _ubicacionServicio.esRutaValidaEnCarro(distancia);
  }
}