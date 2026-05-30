class RutaAutobus {
  String origen;
  String destino;
  String duracion;
  String precio;
  List<String> horarios;
  String clase;

  RutaAutobus({
    required this.origen,
    required this.destino,
    required this.duracion,
    required this.precio,
    required this.horarios,
    required this.clase,
  });

  factory RutaAutobus.fromMap(Map<String, dynamic> map) {
    return RutaAutobus(
      origen: map['origen'] ?? '',
      destino: map['destino'] ?? '',
      duracion: map['duracion'] ?? '',
      precio: map['precio'] ?? '',
      horarios: List<String>.from(map['horarios'] ?? []),
      clase: map['clase'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'origen': origen,
      'destino': destino,
      'duracion': duracion,
      'precio': precio,
      'horarios': horarios,
      'clase': clase,
    };
  }
}