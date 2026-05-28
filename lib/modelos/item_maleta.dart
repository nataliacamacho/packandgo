class ItemMaleta {
  final String? id;
  final String nombre;
  final bool completado;
  final bool esPersonalizado;
  final String categoria;
  final int cantidad;
  final int vecesUsado;
  String? destino;

  ItemMaleta({
    this.id,
    required this.nombre,
    this.completado = false,
    this.esPersonalizado = false,
    this.categoria = 'general',
    this.cantidad = 1,
    this.vecesUsado = 0,
    this.destino,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'completado': completado,
      'esPersonalizado': esPersonalizado,
      'categoria': categoria,
      'cantidad': cantidad,
      'vecesUsado': vecesUsado,
      'destino': destino,
    };
  }

  factory ItemMaleta.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return ItemMaleta(
      id: id,
      nombre: map['nombre'] ?? '',
      completado: map['completado'] ?? false,
      esPersonalizado:
          map['esPersonalizado'] ?? false,
      categoria: map['categoria'] ?? 'general',
      cantidad: map['cantidad'] ?? 1,
      vecesUsado: map['vecesUsado'] ?? 0,
      destino: map['destino'],
    );
  }
}