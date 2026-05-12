class DestinosCorregidos {
  static final Map<String, Map<String, dynamic>> destinos = {
    "lapaz": {
      "nombre": "La Paz",
      "lat": 24.1426,
      "lng": -110.3128,
    },

    "ciudaddemexico": {
      "nombre": "Ciudad de México",
      "lat": 19.4326,
      "lng": -99.1332,
    },

    "puertoescondido": {
      "nombre": "Puerto Escondido",
      "lat": 15.8625,
      "lng": -97.0769,
    },

    "sancristobaldelascasas": {
      "nombre": "San Cristóbal de las Casas",
      "lat": 16.7370,
      "lng": -92.6376,
    },
  };

  static Map<String, dynamic>? obtener(String nombre) {
    final clave = nombre
        .toLowerCase()
        .replaceAll(" ", "")
        .replaceAll("á", "a")
        .replaceAll("é", "e")
        .replaceAll("í", "i")
        .replaceAll("ó", "o")
        .replaceAll("ú", "u");

    return destinos[clave];
  }
}