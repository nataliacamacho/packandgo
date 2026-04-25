import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/modelos/maleta.dart';

class GeneradorMaletaServicio {
  Future<List<ItemMaleta>> generarMaleta({
    required String destino,
    required DateTime inicio,
    required DateTime fin,
    required List<String> actividades,
  }) async {
    print("\n============================");
    print("🚀 GENERANDO MALETA...");
    print("📍 Destino: $destino");
    print("📅 Inicio: $inicio");
    print("📅 Fin: $fin");

    final dias = fin.difference(inicio).inDays;

    print("🧮 Duración calculada: $dias días");

    final datosDestino = await _obtenerDatosDestino(destino);

    print("🌦️ Clima detectado: ${datosDestino["clima"]}");
    print("🏝️ Tipo de destino: ${datosDestino["tipo"]}");

    List<ItemMaleta> lista = [];

    // -------------------------
    final basicos = _itemsBasicos();
    print("🧼 Items básicos: ${basicos.length}");
    lista.addAll(basicos);

    final climaItems = _itemsPorClima(datosDestino["clima"]);
    print("🌦️ Items por clima: ${climaItems.length}");
    lista.addAll(climaItems);

    final tipoItems = _itemsPorTipo(datosDestino["tipo"]);
    print("🏝️ Items por tipo: ${tipoItems.length}");
    lista.addAll(tipoItems);

    final ropaItems = _calcularRopa(dias);
    print("👕 Items de ropa: ${ropaItems.length}");
    lista.addAll(ropaItems);

    for (var act in actividades) {
      lista.addAll(
        _itemsPorActividad(act, datosDestino["tipo"], datosDestino["clima"]),
      );
    }

    final listaFinal = _eliminarDuplicados(lista);

    print("\n🧳 LISTA FINAL (${listaFinal.length} items):");
    for (var item in listaFinal) {
      print(" - ${item.nombre} [${item.categoria}]");
    }

    print("============================\n");

    return listaFinal;
  }

  // -------------------------
  Future<Map<String, dynamic>> _obtenerDatosDestino(String nombre) async {
    print("🔎 Buscando destino en Firebase...");

    final query = await FirebaseFirestore.instance
        .collection("ciudades")
        .where("nombre", isEqualTo: nombre)
        .get();

    if (query.docs.isNotEmpty) {
      print("✅ Destino encontrado en BD");
      return query.docs.first.data();
    }

    print("⚠️ Destino NO encontrado → usando fallback");

    return {"tipo": "ciudad", "clima": "templado"};
  }

  // -------------------------
  List<ItemMaleta> _itemsBasicos() {
    return [
      ItemMaleta(nombre: "Cepillo de dientes"),
      ItemMaleta(nombre: "Ropa interior"),
    ];
  }

  // -------------------------
  List<ItemMaleta> _itemsPorClima(String clima) {
    print("🌦️ Generando por clima: $clima");

    switch (clima) {
      case "tropical":
        return [
          ItemMaleta(nombre: "Bloqueador solar", categoria: "clima"),
          ItemMaleta(nombre: "Ropa ligera", categoria: "ropa"),
        ];
      case "frio":
        return [
          ItemMaleta(nombre: "Abrigo", categoria: "ropa"),
          ItemMaleta(nombre: "Guantes", categoria: "ropa"),
        ];
      default:
        return [];
    }
  }

  // -------------------------
  List<ItemMaleta> _itemsPorTipo(String tipo) {
    print("🏝️ Generando por tipo: $tipo");

    if (tipo == "playa") {
      return [
        ItemMaleta(nombre: "Traje de baño", categoria: "playa"),
        ItemMaleta(nombre: "Sandalias", categoria: "playa"),
      ];
    }
    return [];
  }

  // 🔥 ALGORITMO ROPA
  List<ItemMaleta> _calcularRopa(int dias) {
    print("👕 Calculando ropa para $dias días");

    int camisetas;
    int pantalones;

    if (dias <= 7) {
      camisetas = dias;
      pantalones = (dias / 2).ceil();
      print("🟢 Viaje corto");
    } else {
      camisetas = 10;
      pantalones = 5;
      print("🔵 Viaje largo → optimización aplicada");
    }

    print("👕 Camisetas: $camisetas");
    print("👖 Pantalones: $pantalones");

    return [
      ItemMaleta(nombre: "$camisetas camisetas", categoria: "ropa"),
      ItemMaleta(nombre: "$pantalones pantalones", categoria: "ropa"),
    ];
  }

  // -------------------------
  List<ItemMaleta> _itemsPorActividad(
    String actividad,
    String tipoDestino,
    String clima,
  ) {
    print("🎯 Actividad: $actividad | Tipo: $tipoDestino | Clima: $clima");

    if (actividad == "senderismo") {
      // ❌ Evitar senderismo en playa
      if (tipoDestino == "playa") {
        print("⚠️ Senderismo ignorado en playa");
        return [ItemMaleta(nombre: "Mochila ligera", categoria: "actividad")];
      }

      // ✅ Caso correcto
      return [
        ItemMaleta(nombre: "Botas", categoria: "actividad"),
        ItemMaleta(nombre: "Mochila", categoria: "actividad"),
        ItemMaleta(nombre: "Botella de agua", categoria: "actividad"),
      ];
    }

    return [];
  }

  // -------------------------
  List<ItemMaleta> _eliminarDuplicados(List<ItemMaleta> lista) {
    print("♻️ Eliminando duplicados...");

    final nombres = <String>{};

    final resultado = lista.where((item) {
      if (nombres.contains(item.nombre)) return false;
      nombres.add(item.nombre);
      return true;
    }).toList();

    print("📊 Antes: ${lista.length} | Después: ${resultado.length}");

    return resultado;
  }
}
