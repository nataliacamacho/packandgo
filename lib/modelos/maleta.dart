class ItemMaleta {
  String? id;
  String nombre;
  bool completado;
  bool esPersonalizado;

  ItemMaleta({
    this.id,
    required this.nombre,
    this.completado = false,
    this.esPersonalizado = false,
  });

  Map<String, dynamic> toMap() {
    return {
      "nombre": nombre,
      "completado": completado,
      "esPersonalizado": esPersonalizado,
    };
  }

  factory ItemMaleta.fromMap(Map<String, dynamic> map, String id) {
    return ItemMaleta(
      id: id,
      nombre: map["nombre"],
      completado: map["completado"] ?? false,
      esPersonalizado: map["esPersonalizado"] ?? false,
    );
  }
}
