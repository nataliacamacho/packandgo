enum CategoriaLugar {
  restaurante,
  cafeteria,
  bar,
  parque,
  museo,
  playa,
  monumento,
  zonaArqueologica,
  centroComercial,
  mirador,
  actividadesExtremas,
  otro,
}

class CategoriasMapper {
  static CategoriaLugar fromRaw(dynamic input) {
    if (input == null) return CategoriaLugar.otro;

    final texto = input.toString().toLowerCase();

    if (_containsAny(texto, [
      'cafe',
      'coffee',
      'coffee_shop',
      'bakery',
      'espresso',
      'tea',
    ])) {
      return CategoriaLugar.cafeteria;
    }

    if (_containsAny(texto, [
      'restaurant',
      'food',
      'foods',
      'diner',
      'meal',
      'eatery',
    ])) {
      return CategoriaLugar.restaurante;
    }

    if (_containsAny(texto, [
      'bar',
      'pub',
      'night_club',
      'nightclub',
    ])) {
      return CategoriaLugar.bar;
    }

    if (_containsAny(texto, [
      'beach',
      'coast',
      'sea',
      'water',
      'shore',
      'natural_feature',
    ])) {
      return CategoriaLugar.playa;
    }

    if (_containsAny(texto, [
      'park',
      'garden',
      'nature',
    ])) {
      return CategoriaLugar.parque;
    }

    if (_containsAny(texto, [
      'museum',
      'art_gallery',
      'gallery',
    ])) {
      return CategoriaLugar.museo;
    }

    if (_containsAny(texto, [
      'monument',
      'historic',
      'memorial',
      'tourist_attraction',
    ])) {
      return CategoriaLugar.monumento;
    }

    if (texto.contains('archaeology')) {
      return CategoriaLugar.zonaArqueologica;
    }

    if (_containsAny(texto, [
      'shopping',
      'mall',
      'store',
      'department_store',
    ])) {
      return CategoriaLugar.centroComercial;
    }

    if (_containsAny(texto, [
      'view',
      'viewpoint',
      'observation',
    ])) {
      return CategoriaLugar.mirador;
    }

    if (_containsAny(texto, [
      'amusement',
      'stadium',
      'sport',
    ])) {
      return CategoriaLugar.actividadesExtremas;
    }

    return CategoriaLugar.otro;
  }

  static bool _containsAny(String text, List<String> keys) {
    for (final k in keys) {
      if (text.contains(k)) return true;
    }
    return false;
  }
}

extension CategoriaLugarX on CategoriaLugar {
  String get key => toString().split('.').last;

  String get label {
    switch (this) {
      case CategoriaLugar.restaurante:
        return 'Restaurante';
      case CategoriaLugar.cafeteria:
        return 'Cafetería';
      case CategoriaLugar.bar:
        return 'Bar';
      case CategoriaLugar.parque:
        return 'Parque';
      case CategoriaLugar.museo:
        return 'Museo';
      case CategoriaLugar.playa:
        return 'Playa';
      case CategoriaLugar.monumento:
        return 'Monumento';
      case CategoriaLugar.zonaArqueologica:
        return 'Zona arqueológica';
      case CategoriaLugar.centroComercial:
        return 'Centro comercial';
      case CategoriaLugar.mirador:
        return 'Mirador';
      case CategoriaLugar.actividadesExtremas:
        return 'Actividades';
      case CategoriaLugar.otro:
        return 'Lugar';
    }
  }
}