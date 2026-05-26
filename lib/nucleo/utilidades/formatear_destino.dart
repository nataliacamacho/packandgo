class FormateadorDestino {
  static const Map<String, String> _nombres = {
    "cancun": "Cancún",
    "ciudad_victoria": "Ciudad Victoria",
    "cdmx": "Ciudad de México",
    "san_luis_potosi": "San Luis Potosí",
    "queretaro": "Querétaro",
    "merida": "Mérida",
    "playa_del_carmen": "Playa del Carmen",
    "puerto_vallarta": "Puerto Vallarta",
  };

  static String formatear(String destino) {
    final limpio = destino.toLowerCase().trim();

    // 🔥 Si existe en el mapa
    if (_nombres.containsKey(limpio)) {
      return _nombres[limpio]!;
    }

    // 🔥 Fallback automático
    return limpio
        .replaceAll("_", " ")
        .split(" ")
        .map((palabra) {
          if (palabra.isEmpty) return palabra;

          return palabra[0].toUpperCase() + palabra.substring(1);
        })
        .join(" ");
  }
}

String limpiarTexto(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // quita acentos raros / símbolos
        .replaceAll(RegExp(r'\s+'), ' '); // espacios dobles
  }
