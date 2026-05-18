import 'package:flutter/material.dart';

class TarjetaLugar extends StatelessWidget {
  final String nombre;
  final String ubicacion;
  final double lat;
  final double lng;
  final VoidCallback? onTap;
  final String categoria;
  final String imagenUrl;
  final Map<String, dynamic>? lugar;

  const TarjetaLugar({
    super.key,
    required this.nombre,
    required this.ubicacion,
    required this.lat,
    required this.lng,
    this.onTap,
    required this.categoria,
    required this.imagenUrl,
    this.lugar,
  });

  // ====================================================================
  // 🔥 EL EXTRACTOR INFALIBLE CON "CACHE BUSTER"
  // ====================================================================
  String _obtenerFotoFinal() {
    const impostor = "https://images.unsplash.com/photo-1488646953014-85cb44e25828?q=80&w=400&auto=format&fit=crop";
    String urlFinal = impostor;

    // 1. Extraemos directamente de los datos crudos (El método más seguro)
    if (lugar != null && lugar!['photos'] != null) {
      final list = lugar!['photos'] as List<dynamic>;
      if (list.isNotEmpty) {
        final ref = list[0]['photo_reference'].toString().trim();
        const apiKey = "AIzaSyARaWdvsXGpJZD4uMUNoeAEXDoMcl3GGuQ"; 
        
        // 🔥 EL HACK: Bajamos la resolución a 100 para que el emulador no colapse
        urlFinal = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=100&photoreference=$ref&key=$apiKey";
      }
    }
    // 2. Si no, usamos la que nos mandó la búsqueda
    else if (imagenUrl.isNotEmpty && imagenUrl.startsWith('http') && !imagenUrl.contains('TU_API')) {
      urlFinal = imagenUrl;
    }

    // 🔥 LA MAGIA: EL ROMPE-CACHÉ
    // Si la foto es de Google, le pegamos los milisegundos actuales para que Flutter 
    // NO use la memoria RAM y descargue la imagen a la fuerza.
    if (urlFinal.contains("googleapis")) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      urlFinal = "$urlFinal&hack=$timestamp";
    }

    return urlFinal;
  }

  @override
  Widget build(BuildContext context) {
    final fotoDefinitiva = _obtenerFotoFinal();

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10), 
                child: Image.network(
                  fotoDefinitiva, 
                  height: 90, 
                  width: 90,  
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 90, width: 90, color: Colors.grey[100], 
                      child: const Center(child: CircularProgressIndicator(color: Color(0xFF0066D2), strokeWidth: 2))
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Si llegas a ver esto, es que el lugar genuinamente no tiene foto en Google
                    return Container(
                      height: 90, width: 90, color: const Color(0xFF0066D2).withOpacity(0.1),
                      child: const Icon(Icons.landscape_rounded, size: 40, color: Color(0xFF0066D2)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ubicacion, 
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        categoria.toUpperCase(),
                        style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}