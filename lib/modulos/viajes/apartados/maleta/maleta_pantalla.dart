import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:proyecto/modelos/item_maleta.dart';
import 'package:proyecto/nucleo/servicios/generador_maleta_servicio.dart';
import 'package:proyecto/nucleo/servicios/maleta_firebase_servicio.dart';
import 'package:proyecto/nucleo/utilidades/formatear_destino.dart';

class MaletaPantalla extends StatefulWidget {
  final String idViaje;
  final String destino;

  const MaletaPantalla({
    super.key,
    required this.idViaje,
    required this.destino,
  });

  @override
  State<MaletaPantalla> createState() => _MaletaPantallaState();
}

class _MaletaPantallaState extends State<MaletaPantalla> {
  final servicio = MaletaFirebaseServicio();

  final generador = GeneradorMaletaServicio();

  final escalaController = TextEditingController();

  bool cargando = true;
  bool mostrarLavado = false;

  String? climaManual;

  DateTime? fechaInicioViaje;
  DateTime? fechaFinViaje;

  List<Map<String, dynamic>> escalasActuales = [];

  @override
  void initState() {
    super.initState();

    generar();
  }

  Future<void> generar() async {
    setState(() {
      cargando = true;
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final viajeRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('viajes')
        .doc(widget.idViaje);

    final doc = await viajeRef.get();

    if (!doc.exists) {
      setState(() {
        cargando = false;
      });

      return;
    }

    final data = doc.data()!;

    final inicio = (data['fechaInicio'] as Timestamp).toDate();

    final fin = (data['fechaFin'] as Timestamp).toDate();

    fechaInicioViaje = inicio;
    fechaFinViaje = fin;

    final dias = fin.difference(inicio).inDays + 1;

    mostrarLavado = dias > 7;

    final actividades = List<String>.from(data['actividades'] ?? []);

    final escalasRaw = data['escalas'] ?? [];

    List<Map<String, dynamic>> escalas = [];

    for (final escala in escalasRaw) {
      if (escala is Map<String, dynamic>) {
        escalas.add(escala);
      } else if (escala is String) {
        escalas.add({
          'destino': escala,
          'inicio': data['fechaInicio'],
          'fin': data['fechaFin'],
        });
      }
    }

    escalasActuales = escalas;

    List<ItemMaleta> listaFinal = [];

    // =========================
    // DESTINO PRINCIPAL
    // =========================

    final destinoPrincipal = FormateadorDestino.formatear(widget.destino);

    final maletaPrincipal = await generador.generarMaleta(
      destino: destinoPrincipal,
      inicio: inicio,
      fin: fin,
      actividades: actividades,
      climaManual: climaManual,
    );

    listaFinal.addAll(maletaPrincipal);

    // =========================
    // ESCALAS
    // =========================

    for (final escala in escalas) {
      final destinoEscala = escala['destino'];

      final inicioEscala = (escala['inicio'] as Timestamp).toDate();

      final finEscala = (escala['fin'] as Timestamp).toDate();

      final actividadesEscala = List<String>.from(
        escala['actividades'] ?? actividades,
      );

      final maletaEscala = await generador.generarMaleta(
        destino: destinoEscala,
        inicio: inicioEscala,
        fin: finEscala,
        actividades: actividadesEscala,
        climaManual: climaManual,
      );

      listaFinal.addAll(maletaEscala);
    }

    await servicio.eliminarMaleta(widget.idViaje);

    await servicio.guardarMaleta(widget.idViaje, listaFinal);

    setState(() {
      cargando = false;
    });
  }

  // =========================
  // VALIDAR FECHAS OCUPADAS
  // =========================

  bool fechaYaOcupada(DateTime fecha) {
    for (final escala in escalasActuales) {
      final inicio = (escala['inicio'] as Timestamp).toDate();

      final fin = (escala['fin'] as Timestamp).toDate();

      DateTime actual = inicio;

      while (!actual.isAfter(fin)) {
        if (actual.year == fecha.year &&
            actual.month == fecha.month &&
            actual.day == fecha.day) {
          return true;
        }

        actual = actual.add(const Duration(days: 1));
      }
    }
    return false;
  }

  // =========================
  // AGREGAR ESCALA
  // =========================

  Future<void> agregarEscala() async {
    final texto = escalaController.text.trim();

    if (texto.isEmpty) return;

    if (texto.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un destino válido')),
      );
      return;
    }

    final existe = await generador.destinoExiste(texto);

    if (!existe) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el destino ingresado')),
      );

      return;
    }

    if (fechaInicioViaje == null || fechaFinViaje == null) return;

    final rango = await showDateRangePicker(
      context: context,
      firstDate: fechaInicioViaje!,
      lastDate: fechaFinViaje!,
      selectableDayPredicate: (DateTime dia, DateTime? inicio, DateTime? fin) {
        return !fechaYaOcupada(dia);
      },
    );

    if (rango == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final viajeRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('viajes')
        .doc(widget.idViaje);

    await viajeRef.update({
      'escalas': FieldValue.arrayUnion([
        {
          'destino': texto,
          'inicio': Timestamp.fromDate(rango.start),
          'fin': Timestamp.fromDate(rango.end),
        },
      ]),
    });

    escalaController.clear();

    await generar();
  }

  // =========================
  // DIALOGO ARTICULO
  // =========================

  void mostrarDialogo() {
    String texto = '';
    String destinoSeleccionado = FormateadorDestino.formatear(widget.destino);

    final destinos = [
      FormateadorDestino.formatear(widget.destino),

      ...escalasActuales
          .map((e) => FormateadorDestino.formatear(e['destino'].toString()))
          .toSet(),
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Agregar artículo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) => texto = value,
                    decoration: InputDecoration(
                      hintText: 'Ej: Bloqueador solar',
                      filled: true,
                      fillColor: const Color.fromARGB(255, 235, 235, 235),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: destinoSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Destino',

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF0066D2),
                          width: 2,
                        ),
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                    ),

                    items: destinos.map((destino) {
                      return DropdownMenuItem(
                        value: destino,
                        child: Text(FormateadorDestino.formatear(destino)),
                      );
                    }).toList(),

                    onChanged: (value) {
                      if (value == null) return;

                      setModalState(() {
                        destinoSeleccionado = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066D2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (texto.trim().isNotEmpty) {
                    await servicio.agregarItem(
                      widget.idViaje,
                      ItemMaleta(
                        nombre: texto.trim(),
                        esPersonalizado: true,
                        categoria: 'personalizado',
                        destino: destinoSeleccionado,
                      ),
                    );
                    await servicio.registrarHabitoMaleta(
                      item: ItemMaleta(
                        nombre: texto.trim(),
                        esPersonalizado: true,
                        categoria: 'personalizado',
                        destino: destinoSeleccionado,
                      ),
                    );
                  }

                  if (!mounted) return;

                  Navigator.pop(context);
                },
                child: const Text(
                  'Agregar',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================
  // BOTONES CLIMA
  // =========================

  Widget botonClima(String texto) {
    final seleccionado = climaManual == texto;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 0,
        backgroundColor: seleccionado ? const Color(0xFF0066D2) : Colors.white,
        foregroundColor: seleccionado ? Colors.white : Colors.black,
        side: BorderSide(
          color: seleccionado ? const Color(0xFF0066D2) : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        setState(() {
          if (climaManual == texto) {
            climaManual = null;
          } else {
            climaManual = texto;
          }
        });

        await generar();
      },
      child: Text(texto),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinoFormateado = FormateadorDestino.formatear(widget.destino);

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 50,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: const BoxDecoration(color: Color(0xFFF6A230)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Center(
                    child: Text(
                      'Mi Maleta',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const Center(
                    child: Text(
                      'Lista recomendada para tu viaje',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    destinoFormateado,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    SizedBox(
                      height: 45,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          botonClima('frio'),
                          const SizedBox(width: 8),

                          botonClima('calor'),
                          const SizedBox(width: 8),

                          botonClima('lluvia'),
                          const SizedBox(width: 8),

                          botonClima('templado'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Destinos adicionales',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: escalaController,
                                  cursorColor: const Color(0xFF0066D2),
                                  decoration: InputDecoration(
                                    hintText: 'Ej: Guadalajara',

                                    // 🔵 borde normal
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),

                                    // 🔵 cuando está activo (FOCUS)
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF0066D2), // tu azul
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              ElevatedButton(
                                onPressed: agregarEscala,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0066D2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Agregar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (mostrarLavado)
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.symmetric(horizontal: 16),

                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_laundry_service,
                              color: Colors.orange,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                'Para viajes largos se recomienda considerar opciones de lavado de ropa durante la estancia y reutilizar combinaciones básicas de prendas.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Lista de artículos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    StreamBuilder<List<ItemMaleta>>(
                      stream: servicio.obtenerMaleta(widget.idViaje),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final lista = snapshot.data!;

                        final destinoPrincipal = FormateadorDestino.formatear(
                          widget.destino,
                        ).toLowerCase().trim();

                        final Map<String, List<ItemMaleta>> maletasPorDestino =
                            {};

                        for (final item in lista) {
                          final destino = FormateadorDestino.formatear(
                            item.destino ?? widget.destino,
                          ).toLowerCase().trim();

                          if (!maletasPorDestino.containsKey(destino)) {
                            maletasPorDestino[destino] = [];
                          }

                          maletasPorDestino[destino]!.add(item);
                        }

                        final destinoPrincipalNormalizado =
                            FormateadorDestino.formatear(
                              widget.destino,
                            ).toLowerCase().trim();

                        // 1. Destino principal primero
                        final List<String> destinosOrdenados = [];

                        if (maletasPorDestino.keys.any(
                          (d) =>
                              d.toLowerCase().trim() ==
                              destinoPrincipalNormalizado,
                        )) {
                          destinosOrdenados.add(
                            maletasPorDestino.keys.firstWhere(
                              (d) =>
                                  d.toLowerCase().trim() ==
                                  destinoPrincipalNormalizado,
                            ),
                          );
                        }

                        // 2. Escalas después (en orden original)
                        destinosOrdenados.addAll(
                          maletasPorDestino.keys.where(
                            (d) =>
                                d.toLowerCase().trim() !=
                                destinoPrincipalNormalizado,
                          ),
                        );

                        return ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: destinosOrdenados.map((destino) {
                            final items = maletasPorDestino[destino]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6A230),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.white,
                                      ),

                                      const SizedBox(width: 8),

                                      Expanded(
                                        child: Text(
                                          FormateadorDestino.formatear(destino),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                ...items.map((item) {
                                  return Card(
                                    color: Colors.white,
                                    child: ListTile(
                                      leading: Checkbox(
                                        value: item.completado,
                                        onChanged: (v) {
                                          servicio.actualizarEstado(
                                            widget.idViaje,
                                            item.id!,
                                            v!,
                                          );
                                        },
                                      ),

                                      title: Text(
                                        item.cantidad > 1
                                            ? '${item.nombre} (${item.cantidad})'
                                            : item.nombre,
                                      ),

                                      subtitle: Text(item.categoria),

                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          servicio.eliminarItem(
                                            widget.idViaje,
                                            item.id!,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFB7D4FF)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF0066D2),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              'Las recomendaciones de artículos son sugeridas automáticamente según el destino, clima, duración y actividades del viaje. Puedes agregar o eliminar artículos libremente para personalizar tu maleta según tus necesidades.',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 13.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0066D2),
        onPressed: mostrarDialogo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
