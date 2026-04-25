class ItemMaleta {
  String? id;
  String nombre;
  String categoria;
  bool completado;
  bool esPersonalizado;

  ItemMaleta({
    this.id,
    required this.nombre,
    this.categoria = "general", // ✅ NO required
    this.completado = false,
    this.esPersonalizado = false,
  });

  Map<String, dynamic> toMap() {
    return {
      "nombre": nombre,
      "categoria": categoria,
      "completado": completado,
      "esPersonalizado": esPersonalizado,
    };
  }

  factory ItemMaleta.fromMap(Map<String, dynamic> map, String id) {
    return ItemMaleta(
      id: id,
      nombre: map["nombre"] ?? "",
      categoria: map["categoria"] ?? "general",
      completado: map["completado"] ?? false,
      esPersonalizado: map["esPersonalizado"] ?? false,
    );
  }
}