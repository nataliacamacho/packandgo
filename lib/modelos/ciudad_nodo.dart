class CiudadNodo {
  final String nombre;
  final double lat;
  final double lng;

  const CiudadNodo({
    required this.nombre,
    required this.lat,
    required this.lng,
  });

  // Convertir desde Map (útil para Firebase/API)
  factory CiudadNodo.fromMap(Map<String, dynamic> map) {
    return CiudadNodo(
      nombre: map['nombre'] ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
    );
  }

  // Convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'lat': lat,
      'lng': lng,
    };
  }
}