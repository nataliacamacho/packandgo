import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto/modelos/item_maleta.dart';
import 'package:proyecto/nucleo/servicios/mapbox_maleta_servicio.dart';

class GeneradorMaletaServicio {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final mapbox = MapboxMaletaServicio();

  Future<List<ItemMaleta>> generarMaleta({
    required String destino,
    required DateTime inicio,
    required DateTime fin,
    required List<String> actividades,
    String? climaManual,
  }) async {
    final List<ItemMaleta> lista = [];

    final dias = fin.difference(inicio).inDays + 1;

    // =========================
    // DESTINO
    // =========================

    final ciudadDoc = await _db
        .collection('ciudades')
        .doc(destino.toLowerCase())
        .get();

    String tipo = 'ciudad';
    String clima = 'templado';

    if (ciudadDoc.exists) {
  final data = ciudadDoc.data()!;

  tipo = data['tipo'] ?? 'ciudad';

  final mes = inicio.month;

  if (mes == 12 || mes == 1 || mes == 2) {
    clima = data['climaInvierno'] ?? 'frio';
  } else if (mes >= 3 && mes <= 5) {
    clima = data['climaPrimavera'] ?? 'templado';
  } else if (mes >= 6 && mes <= 8) {
    clima = data['climaVerano'] ?? 'calor';
  } else {
    clima = data['climaOtono'] ?? 'templado';
  }
} else {
  tipo = await mapbox.detectarTipoDestino(
    destino,
  );

  if (tipo == 'playa') {
    clima = 'calor';
  } else if (tipo == 'montaña') {
    clima = 'frio';
  } else {
    clima = 'templado';
  }
}

    if (climaManual != null) {
      clima = climaManual;
    }

    // =========================
    // CLIMA MANUAL
    // =========================

    // =========================
    // BASE
    // =========================

    lista.add(ItemMaleta(nombre: 'Documentos', categoria: 'basicos'));

    lista.add(ItemMaleta(nombre: 'Cepillo dental', categoria: 'higiene'));

    lista.add(ItemMaleta(nombre: 'Cargador', categoria: 'electronica'));

    // =========================
    // TIPO DESTINO
    // =========================

    switch (tipo) {
      case 'playa':
        lista.add(ItemMaleta(nombre: 'Traje de baño', categoria: 'ropa'));

        lista.add(ItemMaleta(nombre: 'Sandalias', categoria: 'calzado'));

        lista.add(ItemMaleta(nombre: 'Bloqueador solar', categoria: 'cuidado'));
        break;

      case 'montaña':
        lista.add(ItemMaleta(nombre: 'Abrigo', categoria: 'ropa'));

        lista.add(ItemMaleta(nombre: 'Botas', categoria: 'calzado'));

        lista.add(ItemMaleta(nombre: 'Bufanda', categoria: 'ropa'));
        break;

      case 'bosque':
        lista.add(ItemMaleta(nombre: 'Repelente', categoria: 'cuidado'));

        lista.add(ItemMaleta(nombre: 'Linterna', categoria: 'herramientas'));
        break;

      case 'desierto':
        lista.add(ItemMaleta(nombre: 'Sombrero', categoria: 'ropa'));

        lista.add(ItemMaleta(nombre: 'Lentes de sol', categoria: 'accesorios'));
        break;

      case 'pueblo':
        lista.add(ItemMaleta(nombre: 'Ropa cómoda', categoria: 'ropa'));
        break;
    }

    // =========================
    // CLIMA
    // =========================

    if (clima == 'frio') {
      lista.add(ItemMaleta(nombre: 'Ropa térmica', categoria: 'ropa'));

      lista.add(ItemMaleta(nombre: 'Guantes', categoria: 'ropa'));

      lista.add(ItemMaleta(nombre: 'Sudaderas', categoria: 'ropa'));
    }

    if (clima == 'lluvia') {
      lista.add(ItemMaleta(nombre: 'Impermeable', categoria: 'ropa'));

      lista.add(ItemMaleta(nombre: 'Paraguas', categoria: 'accesorios'));
    }

    if (clima == 'calor') {
      lista.add(ItemMaleta(nombre: 'Ropa ligera', categoria: 'ropa'));
    }

    // =========================
    // MUDAS
    // =========================

    int mudas = dias;

    if (actividades.contains('natacion')) {
      mudas += 1;
    }

    if (dias > 20) {
      mudas = 14;

      lista.add(ItemMaleta(nombre: 'Lavar ropa', categoria: 'recomendacion'));
    }

    if (dias > 7) {
      lista.add(
        ItemMaleta(
          nombre: 'Recomendación de lavado',
          categoria: 'recomendacion',
        ),
      );
    }

    lista.add(
      ItemMaleta(nombre: 'Mudas de ropa', cantidad: mudas, categoria: 'ropa'),
    );

    // =========================
    // ACTIVIDADES
    // =========================

    for (final actividad in actividades) {
      final actividadDoc = await _db
          .collection('actividades')
          .doc(actividad)
          .get();

      if (actividadDoc.exists) {
        final data = actividadDoc.data()!;

        final items = List<String>.from(data['items'] ?? []);

        for (final item in items) {
          lista.add(ItemMaleta(nombre: item, categoria: 'actividad'));
        }
      }
    }

    // =========================
    // HISTORIAL
    // =========================

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final viajes = await _db
        .collection('usuarios')
        .doc(uid)
        .collection('viajes')
        .get();

    final totalViajes = viajes.docs.length;

    final Map<String, int> frecuencia = {};

    for (final viaje in viajes.docs.take(3)) {
      final maleta = await viaje.reference.collection('maleta').get();

      for (final item in maleta.docs) {
        final nombre = item['nombre'];

        frecuencia[nombre] = (frecuencia[nombre] ?? 0) + 1;
      }
    }

    frecuencia.forEach((item, usos) {
      final porcentaje = (usos / totalViajes) * 100;

      if (porcentaje >= 50) {
        lista.add(
          ItemMaleta(
            nombre: item,
            categoria: 'personalizado',
            esPersonalizado: true,
            vecesUsado: usos,
          ),
        );
      }
    });

    // =========================
    // ELIMINAR DUPLICADOS
    // =========================

    final nombres = <String>{};

    lista.removeWhere((item) {
      if (nombres.contains(item.nombre)) {
        return true;
      }

      nombres.add(item.nombre);

      return false;
    });

    return lista;
  }
}
