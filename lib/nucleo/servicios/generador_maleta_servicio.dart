import 'package:proyecto/modelos/maleta.dart';

class GeneradorMaletaServicio {

  Future<List<ItemMaleta>> generarMaleta({
    required String destino,
    required DateTime inicio,
    required DateTime fin,
    required List<String> actividades,
    required int dias, // ✔ viene desde MaletaPantalla
  }) async {

    final List<ItemMaleta> items = [];

    // 🌡️ CLIMA (simulado por ahora)
    final clima = _obtenerClima(destino);

    // 📦 ROPA BASE SEGÚN CLIMA + DIAS
    items.addAll(_generarRopa(clima, dias));

    // 🎯 ACTIVIDADES
    for (final act in actividades) {
      items.addAll(_itemsActividad(act));
    }

    // 🧠 AGREGAR BÁSICOS SIEMPRE
    items.addAll(_itemsBasicos());

    // ♻️ ELIMINAR DUPLICADOS
    final Map<String, ItemMaleta> unico = {};

    for (final item in items) {
      unico[item.nombre] = item;
    }

    return unico.values.toList();
  }

  // -------------------------
  String _obtenerClima(String destino) {
    final d = destino.toLowerCase();

    if (d.contains("vallarta") || d.contains("cancun") || d.contains("mazatlan")) {
      return "calor";
    }

    if (d.contains("cdmx") || d.contains("puebla") || d.contains("queretaro")) {
      return "templado";
    }

    return "frio";
  }

  // -------------------------
  List<ItemMaleta> _generarRopa(String clima, int dias) {
    switch (clima) {

      case "calor":
        return [
          ItemMaleta(nombre: "$dias camisetas ligeras"),
          ItemMaleta(nombre: "$dias shorts"),
          ItemMaleta(nombre: "1 traje de baño"),
          ItemMaleta(nombre: "protector solar"),
          ItemMaleta(nombre: "sandalias"),
        ];

      case "templado":
        return [
          ItemMaleta(nombre: "$dias camisetas"),
          ItemMaleta(nombre: "${(dias / 2).ceil()} pantalones"),
          ItemMaleta(nombre: "suéter ligero"),
        ];

      case "frio":
        return [
          ItemMaleta(nombre: "$dias camisetas térmicas"),
          ItemMaleta(nombre: "${(dias / 2).ceil()} pantalones"),
          ItemMaleta(nombre: "abrigo"),
          ItemMaleta(nombre: "bufanda"),
        ];

      default:
        return [
          ItemMaleta(nombre: "$dias camisetas"),
        ];
    }
  }

  // -------------------------
  List<ItemMaleta> _itemsActividad(String act) {
    switch (act) {

      case "senderismo":
        return [
          ItemMaleta(nombre: "botas de senderismo"),
          ItemMaleta(nombre: "mochila"),
          ItemMaleta(nombre: "linterna"),
          ItemMaleta(nombre: "botella de agua"),
        ];

      case "playa":
        return [
          ItemMaleta(nombre: "toalla"),
          ItemMaleta(nombre: "lentes de sol"),
          ItemMaleta(nombre: "ropa de baño extra"),
        ];

      case "trabajo":
        return [
          ItemMaleta(nombre: "ropa formal"),
          ItemMaleta(nombre: "laptop"),
        ];

      default:
        return [];
    }
  }

  // -------------------------
  List<ItemMaleta> _itemsBasicos() {
    return [
      ItemMaleta(nombre: "cepillo de dientes"),
      ItemMaleta(nombre: "cargador"),
      ItemMaleta(nombre: "ropa interior"),
    ];
  }
}