class Hospedaje {
  String nombre;
  String imagen;
  double precio;
  String ubicacion;
  bool disponible;
  String link;
  double lat;
  double lng;
  double rating;
  String placeId; // ✅ tipado correcto

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
    required this.placeId, // ✅
  });

  factory Hospedaje.fromGoogle(Map<String, dynamic> json, String apiKey) {
    final lat = (json['geometry']['location']['lat'] ?? 0.0).toDouble();
    final lng = (json['geometry']['location']['lng'] ?? 0.0).toDouble();
    final placeId = json['place_id'] ?? ''; // ✅ Google ya lo manda

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
      precio: 0,
      ubicacion: json['vicinity'] ?? 'Sin ubicación',
      disponible: true,
      link: "https://www.google.com/maps/search/?api=1"
            "&query=${Uri.encodeComponent(json['name'] ?? '')}"
            "&query_place_id=$placeId", // ✅ link directo y exacto
      lat: lat,
      lng: lng,
      rating: (json['rating'] ?? 0).toDouble(),
      placeId: placeId, // ✅
    );
  }
}