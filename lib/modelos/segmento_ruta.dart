class SegmentoRuta {
  final String tipo; // carro, autobus, avion
  final String origen;
  final String destino;

  // Coordenadas (opcionales ahora)
  final double origenLat;
  final double origenLng;
  final double destinoLat;
  final double destinoLng;

  final double distancia;
  final double tiempo;
  final double costo;

  const SegmentoRuta({
    required this.tipo,
    required this.origen,
    required this.destino,

    this.origenLat = 0,
    this.origenLng = 0,
    this.destinoLat = 0,
    this.destinoLng = 0,

    required this.distancia,
    required this.tiempo,
    required this.costo,
  });

  factory SegmentoRuta.fromMap(Map<String, dynamic> map) {
    return SegmentoRuta(
      tipo: map['tipo'] ?? '',
      origen: map['origen'] ?? '',
      destino: map['destino'] ?? '',

      origenLat: (map['origenLat'] as num?)?.toDouble() ?? 0,
      origenLng: (map['origenLng'] as num?)?.toDouble() ?? 0,
      destinoLat: (map['destinoLat'] as num?)?.toDouble() ?? 0,
      destinoLng: (map['destinoLng'] as num?)?.toDouble() ?? 0,

      distancia: (map['distancia'] as num?)?.toDouble() ?? 0,
      tiempo: (map['tiempo'] as num?)?.toDouble() ?? 0,
      costo: (map['costo'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'origen': origen,
      'destino': destino,

      'origenLat': origenLat,
      'origenLng': origenLng,
      'destinoLat': destinoLat,
      'destinoLng': destinoLng,

      'distancia': distancia,
      'tiempo': tiempo,
      'costo': costo,
    };
  }
}