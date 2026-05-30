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

  factory RutaAvion.fromMap(Map<String, dynamic> map) {
    return RutaAvion(
      origen: map['origen'] ?? '',
      destino: map['destino'] ?? '',
      aeropuertoOrigen: map['aeropuertoOrigen'] ?? '',
      aeropuertoDestino: map['aeropuertoDestino'] ?? '',
      duracion: map['duracion'] ?? '',
      precio: map['precio'] ?? '',
      horarios: List<String>.from(map['horarios'] ?? []),
      aerolineas: List<String>.from(map['aerolineas'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'origen': origen,
      'destino': destino,
      'aeropuertoOrigen': aeropuertoOrigen,
      'aeropuertoDestino': aeropuertoDestino,
      'duracion': duracion,
      'precio': precio,
      'horarios': horarios,
      'aerolineas': aerolineas,
    };
  }
}