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
    // NORMALIZAR DESTINO
    // =========================

    final destinoNormalizado = destino
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');

    // =========================
    // DETECTAR TIPO Y CLIMA
    // =========================

    final ciudadDoc = await _db
        .collection('ciudades')
        .doc(destinoNormalizado)
        .get();

    String tipo = 'ciudad';

    String clima = 'templado';

    if (ciudadDoc.exists) {
      final data = ciudadDoc.data()!;
      print("DESTINO ENCONTRADO EN FIRESTORE");
      print("Destino: $destino");
      print("Tipo BD: $tipo");

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
      // =========================
      // MAPBOX FALLBACK
      // =========================

      tipo = await mapbox.detectarTipoDestino(destino);

      print('MAPBOX ACTIVADO');
      print('Destino: $destino');
      print('Tipo detectado: $tipo');

      final mes = inicio.month;

      // =========================
      // PATRONES CLIMÁTICOS
      // =========================

      if (tipo == 'playa') {
        if (mes >= 6 && mes <= 9) {
          clima = 'lluvia';
        } else {
          clima = 'calor';
        }
      } else if (tipo == 'montaña') {
        if (mes == 12 || mes == 1 || mes == 2) {
          clima = 'frio';
        } else {
          clima = 'templado';
        }
      } else if (tipo == 'bosque') {
        if (mes >= 6 && mes <= 9) {
          clima = 'lluvia';
        } else {
          clima = 'templado';
        }
      } else if (tipo == 'desierto') {
        clima = 'calor';
      } else {
        if (mes == 12 || mes == 1 || mes == 2) {
          clima = 'frio';
        } else if (mes >= 6 && mes <= 9) {
          clima = 'lluvia';
        } else {
          clima = 'templado';
        }
      }
    }

    // =========================
    // CLIMA MANUAL
    // =========================

    if (climaManual != null) {
      clima = climaManual;
    }

    // =========================
    // FUNCIÓN PRENDAS
    // =========================

    void agregarPrendas({
      required List<ItemMaleta> lista,
      required int dias,
      required String clima,
      required String tipo,
      required List<String> actividades,
    }) {
      int camisetas = dias <= 5 ? dias : (dias * 0.7).ceil();
      int pantalones = dias <= 5 ? (dias / 2).ceil() : (dias / 3).ceil();
      int ropaInterior = dias;
      int calcetines = dias;
      bool actividadAcuatica =
          actividades.contains('natacion') ||
          actividades.contains('snorkel') ||
          actividades.contains('playa') ||
          actividades.contains('actividades acuaticas');

      // =========================
      // VIAJES LARGOS
      // =========================

      if (dias > 20) {
        camisetas = 12;
        pantalones = 5;
        ropaInterior = 7;
        calcetines = 7;
      }

      if (actividadAcuatica) {
        camisetas += 1;
        ropaInterior += 1;
      }

      // =========================
      // FRÍO
      // =========================

      if (clima == 'frio') {
        lista.add(
          ItemMaleta(
            nombre: 'Suéteres',
            cantidad: dias <= 5 ? 2 : 3,
            categoria: 'ropa',
          ),
        );

        lista.add(
          ItemMaleta(
            nombre: 'Chamarra térmica',
            cantidad: 1,
            categoria: 'ropa',
          ),
        );
      }

      // =========================
      // LLUVIA
      // =========================

      if (clima == 'lluvia') {
        lista.add(
          ItemMaleta(nombre: 'Impermeable', cantidad: 1, categoria: 'ropa'),
        );
      }

      // =========================
      // PLAYA
      // =========================

      if (tipo == 'playa') {
        lista.add(
          ItemMaleta(
            nombre: 'Traje de baño',
            cantidad: (dias / 3).ceil(),
            categoria: 'ropa',
          ),
        );

        lista.add(
          ItemMaleta(
            nombre: 'Shorts',
            cantidad: (dias / 2).ceil(),
            categoria: 'ropa',
          ),
        );
      }

      // =========================
      // ACTIVIDADES
      // =========================

      if (actividades.contains('senderismo')) {
        lista.add(
          ItemMaleta(
            nombre: 'Ropa deportiva',
            cantidad: dias > 6 ? 3 : 2,
            categoria: 'ropa',
          ),
        );

        lista.add(
          ItemMaleta(
            nombre: 'Calcetines térmicos',
            cantidad: clima == 'frio' ? (dias / 2).ceil() : 2,
            categoria: 'calzado',
          ),
        );
      }

      if (actividades.contains('formal')) {
        lista.add(
          ItemMaleta(
            nombre: 'Ropa formal',
            cantidad: dias > 4 ? 2 : 1,
            categoria: 'ropa',
          ),
        );
      }

      // =========================
      // PRENDAS BASE
      // =========================

      lista.add(
        ItemMaleta(nombre: 'Camisetas', cantidad: camisetas, categoria: 'ropa'),
      );

      lista.add(
        ItemMaleta(
          nombre: 'Pantalones',
          cantidad: pantalones,
          categoria: 'ropa',
        ),
      );

      lista.add(
        ItemMaleta(
          nombre: 'Ropa interior',
          cantidad: ropaInterior,
          categoria: 'ropa',
        ),
      );

      lista.add(
        ItemMaleta(
          nombre: 'Calcetines',
          cantidad: calcetines,
          categoria: 'calzado',
        ),
      );
    }

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
        lista.add(
          ItemMaleta(nombre: 'Sandalias', cantidad: 1, categoria: 'calzado'),
        );

        lista.add(ItemMaleta(nombre: 'Bloqueador solar', categoria: 'cuidado'));
        break;

      case 'montaña':
        lista.add(
          ItemMaleta(
            nombre: 'Abrigos',
            cantidad: dias <= 5 ? 1 : 2,
            categoria: 'ropa',
          ),
        );

        lista.add(
          ItemMaleta(nombre: 'Botas', cantidad: 1, categoria: 'calzado'),
        );

        lista.add(
          ItemMaleta(nombre: 'Bufandas', cantidad: 1, categoria: 'ropa'),
        );
        break;

      case 'bosque':
        lista.add(ItemMaleta(nombre: 'Repelente', categoria: 'cuidado'));

        lista.add(ItemMaleta(nombre: 'Linterna', categoria: 'herramientas'));

        lista.add(
          ItemMaleta(
            nombre: 'Botas para senderismo',
            cantidad: 1,
            categoria: 'calzado',
          ),
        );
        break;

      case 'desierto':
        lista.add(
          ItemMaleta(nombre: 'Sombreros', cantidad: 1, categoria: 'ropa'),
        );

        lista.add(ItemMaleta(nombre: 'Lentes de sol', categoria: 'accesorios'));
        break;

      case 'pueblo':
        lista.add(
          ItemMaleta(
            nombre: 'Conjuntos cómodos',
            cantidad: (dias / 2).ceil(),
            categoria: 'ropa',
          ),
        );
        break;
    }

    // =========================
    // CLIMA
    // =========================

    if (clima == 'frio') {
      lista.add(
        ItemMaleta(
          nombre: 'Ropa térmica',
          cantidad: dias <= 5 ? 2 : 3,
          categoria: 'ropa',
        ),
      );

      lista.add(ItemMaleta(nombre: 'Guantes', cantidad: 1, categoria: 'ropa'));

      lista.add(
        ItemMaleta(
          nombre: 'Sudaderas',
          cantidad: dias <= 6 ? 2 : 3,
          categoria: 'ropa',
        ),
      );
    }

    if (clima == 'lluvia') {
      lista.add(ItemMaleta(nombre: 'Impermeable', categoria: 'ropa'));

      lista.add(ItemMaleta(nombre: 'Paraguas', categoria: 'accesorios'));
    }

    // =========================
    // PRENDAS
    // =========================

    agregarPrendas(
      lista: lista,
      dias: dias,
      clima: clima,
      tipo: tipo,
      actividades: actividades,
    );

    // =========================
    // ACTIVIDADES FIRESTORE
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
        .orderBy('fechaInicio', descending: true)
        .limit(3)
        .get();

    final totalViajes = viajes.docs.length;

    if (totalViajes > 0) {
      final historial = await _db
          .collection('usuarios')
          .doc(uid)
          .collection('historial_maleta')
          .get();

      final totalViajes = viajes.docs.length;

      if (totalViajes > 0) {
        for (final doc in historial.docs) {
          final data = doc.data();

          final nombre = data['nombre'];

          final vecesUsado = data['veces_usado'] ?? 0;

          final porcentaje = (vecesUsado / totalViajes) * 100;

          // 🔥 SI USA EL ARTÍCULO EN 50% O MÁS
          if (porcentaje >= 50) {
            lista.add(
              ItemMaleta(
                nombre: nombre,
                categoria: 'personalizado',
                esPersonalizado: true,
                vecesUsado: vecesUsado,
              ),
            );
          }
        }
      }
    }

    // =========================
    // ASIGNAR DESTINO
    // =========================

    for (final item in lista) {
      item.destino = destino;
    }

    // =========================
    // ELIMINAR DUPLICADOS
    // =========================

    final identificadores = <String>{};

    lista.removeWhere((item) {
      final clave = '${item.destino}_${item.nombre}';

      if (identificadores.contains(clave)) {
        return true;
      }

      identificadores.add(clave);

      return false;
    });

    return lista;
  }

  Future<bool> destinoExiste(String destino) async {
    final destinoNormalizado = destino
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');

    // =========================
    // FIRESTORE
    // =========================

    final ciudadDoc = await _db
        .collection('ciudades')
        .doc(destinoNormalizado)
        .get();

    if (ciudadDoc.exists) {
      return true;
    }

    // =========================
    // MAPBOX
    // =========================

    return await mapbox.destinoValido(destino);
  }

  Future<String> obtenerClimaEsperado({
    required String destino,
    required DateTime fechaInicio,
  }) async {
    final destinoNormalizado = destino
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');

    final ciudadDoc = await _db
        .collection('ciudades')
        .doc(destinoNormalizado)
        .get();

    String tipo = 'ciudad';
    String clima = 'templado';

    if (ciudadDoc.exists) {
      final data = ciudadDoc.data()!;

      tipo = data['tipo'] ?? 'ciudad';

      final mes = fechaInicio.month;

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
      tipo = await mapbox.detectarTipoDestino(destino);

      final mes = fechaInicio.month;

      if (tipo == 'playa') {
        clima = (mes >= 6 && mes <= 9) ? 'lluvia' : 'calor';
      } else if (tipo == 'montaña') {
        clima = (mes == 12 || mes == 1 || mes == 2) ? 'frio' : 'templado';
      } else if (tipo == 'bosque') {
        clima = (mes >= 6 && mes <= 9) ? 'lluvia' : 'templado';
      } else if (tipo == 'desierto') {
        clima = 'calor';
      } else {
        if (mes == 12 || mes == 1 || mes == 2) {
          clima = 'frio';
        } else if (mes >= 6 && mes <= 9) {
          clima = 'lluvia';
        } else {
          clima = 'templado';
        }
      }
    }

    return clima;
  }
}
