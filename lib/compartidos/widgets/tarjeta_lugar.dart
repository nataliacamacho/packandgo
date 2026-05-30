import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    // ✅ PRIORIDAD 1: usar la imagen ya construida (¡Protegida contra nulos!)
    if (imagenUrl != null && 
        imagenUrl!.isNotEmpty && 
        imagenUrl!.startsWith('http') && 
        !imagenUrl!.contains('unsplash')) {
      return imagenUrl!;
    }
    
    // ✅ PRIORIDAD 2: reconstruir desde photos (¡Protegida contra nulos!)
    if (lugar != null && lugar!['photos'] != null) {
      final fotos = lugar!['photos'];

      if (fotos is List && fotos.isNotEmpty) {
        final primera = fotos.first;

        // 🔥 COMPATIBLE CON AMBOS FORMATOS
        final ref = primera['photo_reference'] ?? primera['photoReference'];

        if (ref != null) {
          return "https://maps.googleapis.com/maps/api/place/photo"
                 "?maxwidth=400"
                 "&photo_reference=$ref"
                 "&key=${dotenv.env['GOOGLE_API_KEY']}";
        }
      }
    }

    // 🔥 EL TRUCO MAESTRO: Si llegamos hasta aquí, significa que Google no tiene foto.
    // Devolvemos un texto vacío ('') para engañar al Image.network.
    // Al recibir un texto vacío, Flutter dirá "¡Error!" y activará automáticamente
    // el errorBuilder que diseñamos hace rato, pintando tu foto HD de Wikipedia.
    return ''; 
  }

 // -------------------------------------------------------------------------
  // RESPALDO VISUAL ESTILO GOOGLE MAPS (100% Sin Internet)
  // -------------------------------------------------------------------------
  Widget obtenerRespaldoVisual(String categoria) {
    Color colorFondo;
    IconData icono;

    switch (categoria.toLowerCase()) {
      case 'zona_arqueologica':
        colorFondo = Colors.brown[400]!;
        icono = Icons.account_balance; 
        break;
      case 'cafeteria':
        colorFondo = Colors.orange[400]!;
        icono = Icons.local_cafe;
        break;
      case 'restaurante':
        colorFondo = Colors.red[400]!;
        icono = Icons.restaurant;
        break;
      case 'playa':
        colorFondo = Colors.lightBlue[400]!;
        icono = Icons.beach_access;
        break;
      case 'museo':
        colorFondo = Colors.indigo[400]!;
        icono = Icons.museum;
        break;
      case 'bar':
        colorFondo = Colors.deepPurple[400]!;
        icono = Icons.local_bar;
        break;
      case 'parque':
        colorFondo = Colors.green[400]!;
        icono = Icons.park;
        break;
      case 'mirador':
        colorFondo = Colors.teal[400]!;
        icono = Icons.filter_hdr;
        break;
      case 'centro_comercial':
        colorFondo = Colors.blueGrey[400]!;
        icono = Icons.local_mall;
        break;
      case 'actividades_extremas':
        colorFondo = Colors.deepOrange[400]!;
        icono = Icons.paragliding; // O Icons.directions_bike
        break;
      case 'monumento':
        colorFondo = Colors.blue[400]!;
        icono = Icons.account_balance;
        break;
      default:
        colorFondo = Colors.grey[400]!;
        icono = Icons.place;
    }

    return Container(
      height: 90,
      width: 90,
      color: colorFondo,
      child: Center(
        child: Icon(icono, color: Colors.white, size: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
        // Aquí mandas llamar tu función ya reparada
    final fotoDefinitiva = _obtenerFotoFinal(); 
    // Y proteges tu categoría por si acaso
    final categoria = this.categoria ?? 'otro';

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
              // 1. LA IMAGEN
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
                      height: 90,
                      width: 90,
                      color: Colors.grey[100],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0066D2),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return obtenerRespaldoVisual(categoria ?? 'otro');
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // 2. LOS TEXTOS Y EL SEMÁFORO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
                    
                    // 🔥 AQUÍ ESTÁ LA FILA QUE EMPUJA LA CATEGORÍA Y EL SEMÁFORO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (categoria ?? 'otro').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
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
