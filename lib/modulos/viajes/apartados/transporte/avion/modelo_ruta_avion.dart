class RutaAvion {
  final String origen;
  final String destino;
  final String aeropuertoOrigen;
  final String aeropuertoDestino;
  final String duracion;
  final String precio;
  final List<String> horarios;
  final List<String> aerolineas;

  RutaAvion({
    required this.origen,
    required this.destino,
    required this.aeropuertoOrigen,
    required this.aeropuertoDestino,
    required this.duracion,
    required this.precio,
    required this.horarios,
    required this.aerolineas,
  });
}