class Hospedaje {
  final String nombre;
  final String imagen;
  final double precio;
  final String ubicacion;
  final bool disponible;
  final String link;
  final double lat;
  final double lng;
  final double rating;
  final String placeId;

  Hospedaje({
    required this.nombre,
    required this.imagen,
    required this.precio,
    required this.ubicacion,
    required this.disponible,
    required this.link,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.placeId,
  });

  factory Hospedaje.fromGoogle(Map<String, dynamic> json, String apiKey) {
    final lat = (json['geometry']['location']['lat'] ?? 0.0).toDouble();
    final lng = (json['geometry']['location']['lng'] ?? 0.0).toDouble();
    final placeId = json['place_id'] ?? '';

    final photos = json['photos'] as List?;
    String imageUrl = '';

    if (photos != null && photos.isNotEmpty) {
      final photoRef = photos[0]['photo_reference'];
      imageUrl =
          "https://maps.googleapis.com/maps/api/place/photo"
          "?maxwidth=400"
          "&photo_reference=$photoRef"
          "&key=$apiKey";
    }

    return Hospedaje(
      nombre: json['name'] ?? 'Sin nombre',
      imagen: imageUrl,
      precio: ((json['rating'] ?? 3.0) * 500).toDouble(),
      ubicacion: json['vicinity'] ?? 'México',
      disponible: true,
      link: "",
      lat: lat,
      lng: lng,
      rating: (json['rating'] ?? 0).toDouble(),
      placeId: placeId,
    );
  }
}
