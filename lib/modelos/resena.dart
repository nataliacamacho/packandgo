class Resena {
  final String id;
  final String idUsuario;
  final String idLugar;
  final String nombreLugar;
  final DateTime fecha;
  final int estrellas;
  final String texto;
  final int likes;
  final int meEncanta;
  final bool esFavorita;

  Resena({
    required this.id,
    required this.idUsuario,
    required this.idLugar,
    required this.nombreLugar,
    required this.fecha,
    required this.estrellas,
    required this.texto,
    required this.likes,
    required this.meEncanta,
    required this.esFavorita,
  });

  factory Resena.fromMap(String id, Map<String, dynamic> data) {
    return Resena(
      id: id,
      idUsuario: data['id_usuario'],
      idLugar: data['id_lugar'],
      nombreLugar: data['nombre_lugar'],
      fecha: DateTime.parse(data['fecha']),
      estrellas: data['estrellas'],
      texto: data['texto'],
      likes: data['likes'],
      meEncanta: data['me_encanta'],
      esFavorita: data['es_favorita'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'id_lugar': idLugar,
      'nombre_lugar': nombreLugar,
      'fecha': fecha.toIso8601String(),
      'estrellas': estrellas,
      'texto': texto,
      'likes': likes,
      'me_encanta': meEncanta,
      'es_favorita': esFavorita,
    };
  }
}