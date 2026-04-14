class RutaAutobus {
  final String id;
  final String origen;
  final String destino;
  final List<String> horarios;
  final double precio;
  final String duracion;
  final DateTime ultimaActualizacion;

  RutaAutobus({
    required this.id,
    required this.origen,
    required this.destino,
    required this.horarios,
    required this.precio,
    required this.duracion,
    required this.ultimaActualizacion,
  });

  factory RutaAutobus.fromMap(Map<String, dynamic> map, String id) {
    return RutaAutobus(
      id: id,
      origen: map['origen'],
      destino: map['destino'],
      horarios: List<String>.from(map['horarios']),
      precio: (map['precio'] as num).toDouble(),
      duracion: map['duracion'],
      ultimaActualizacion: DateTime.parse(map['ultimaActualizacion']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'origen': origen,
      'destino': destino,
      'horarios': horarios,
      'precio': precio,
      'duracion': duracion,
      'ultimaActualizacion': ultimaActualizacion.toIso8601String(),
    };
  }
}