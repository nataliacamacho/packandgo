import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> cargarDatosSemilla() async {
  final db = FirebaseFirestore.instance;
  try {
    // 1. Reglas de la Maleta
    await db.collection('catalogo_maleta').doc('reglas_base').set({
      "por_clima": {
        "Caluroso": ["Traje de baño", "Bloqueador solar", "Gorra", "Ropa ligera"],
        "Frío": ["Chamarra gruesa", "Guantes", "Gorrito", "Bufanda"],
        "Lluvioso": ["Impermeable", "Paraguas", "Botas de lluvia"]
      },
      "por_actividad": {
        "Playa": ["Toalla", "Sandalias", "Lentes de sol"],
        "Urbano": ["Tenis cómodos", "Mochila pequeña", "Batería portátil"],
        "Senderismo": ["Botas de montaña", "Repelente de mosquitos", "Linterna"]
      }
    });

    // 2. Ciudades Principales
    await db.collection('ciudades').doc('gdl_jalisco').set({
      "nombre": "Guadalajara",
      "estado": "Jalisco",
      "tipo_destino": "Urbano",
      "coordenadas": const GeoPoint(20.659, -103.349),
      "clima_promedio": { "primavera": "Caluroso", "verano": "Lluvioso", "otono": "Templado", "invierno": "Fresco" }
    });

    await db.collection('ciudades').doc('pvr_jalisco').set({
      "nombre": "Puerto Vallarta",
      "estado": "Jalisco",
      "tipo_destino": "Playa",
      "coordenadas": const GeoPoint(20.653, -105.225),
      "clima_promedio": { "primavera": "Caluroso", "verano": "Lluvioso", "otono": "Caluroso", "invierno": "Templado" }
    });

    print("✅ ¡ÉXITO! Datos semilla inyectados.");
  } catch (e) {
    print("❌ Error: $e");
  }
}