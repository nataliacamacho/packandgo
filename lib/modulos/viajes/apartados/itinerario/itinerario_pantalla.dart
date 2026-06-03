import 'package:flutter/material.dart';
import 'package:proyecto/modulos/busqueda/busqueda_pantalla.dart';
import 'package:proyecto/modulos/busqueda/lugar_detalle_pantalla.dart';
import 'package:proyecto/nucleo/servicios/itinerario_servicio.dart';
import 'package:proyecto/nucleo/servicios/google_places_servicio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItinerarioPantalla extends StatefulWidget {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String idViaje;

  const ItinerarioPantalla({
    super.key,
    required this.fechaInicio,
    required this.fechaFin,
    required this.idViaje,
  });

  @override
  State<ItinerarioPantalla> createState() => _ItinerarioPantallaState();
}

class _ItinerarioPantallaState extends State<ItinerarioPantalla> {
  late List<DateTime> diasDelViaje;
  Map<String, List<Map<String, dynamic>>> itinerarioPorDia = {};
  String destinoViaje = "";

  @override
  void initState() {
    super.initState();
    diasDelViaje = ItinerarioServicio.generarListaDias(
      widget.fechaInicio,
      widget.fechaFin,
    );
    cargarItinerario();
  }

  // ---------------------------------------------------------------------------
  // Determina si el lugar está cerrado el día indicado.
  // weekdayText es la lista que devuelve Place Details:
  //   ["Monday: Closed", "Tuesday: 9:00 AM – 6:00 PM", ...]
  // ---------------------------------------------------------------------------
  bool _estaCerradoEseDia(List<String> weekdayText, int weekday) {
    // DateTime.monday = 1 ... DateTime.sunday = 7
    // weekday_text de Google: índice 0 = lunes, 6 = domingo
    final indice = weekday - 1; // lunes→0, martes→1 ... domingo→6
    if (indice < 0 || indice >= weekdayText.length) return false;

    final lineaDia = weekdayText[indice].toLowerCase();
    return lineaDia.contains('closed') || lineaDia.contains('cerrado');
  }

  // ---------------------------------------------------------------------------
  // Flujo completo al agregar un lugar:
  // 1. Validar máximo 5 (RQNF40)
  // 2. Si viene de Google (tiene place_id) → llamar Place Details para weekday_text
  //    Si viene de OpenTripMap → no tiene horarios, avisar y permitir
  // 3. Comparar día del itinerario con weekday_text (RQNF43)
  // 4. Bloquear si cerrado (RQNF44) o avisar si sin horarios
  // 5. Agregar y guardar (RQF126 / RQF129)
  // ---------------------------------------------------------------------------
  Future<void> agregarLugarADia(
    DateTime dia,
    Map<String, dynamic> lugar,
  ) async {
    final fechaKey = dia.toString().split(' ')[0];
    itinerarioPorDia.putIfAbsent(fechaKey, () => []);

    // RQNF40: máximo 5 lugares por día
    if (itinerarioPorDia[fechaKey]!.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Máximo 5 lugares por día")));
      return;
    }

    final placeId = lugar['place_id']?.toString() ?? '';
    final esFuenteGoogle = lugar['fuente'] == 'google' || placeId.isNotEmpty;

    List<String> weekdayText = [];
    bool? tieneHorarios;

    if (esFuenteGoogle && placeId.isNotEmpty) {
      // RQF123: consultamos los horarios reales via Place Details
      // Mostramos indicador de carga mientras llama a la API
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text("Verificando disponibilidad..."),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      final detalles = await GooglePlacesServicio.obtenerDetallesHorario(
        placeId,
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final dias = detalles['dias'];
      if (dias != null && dias is List && dias.isNotEmpty) {
        weekdayText = List<String>.from(dias);
        tieneHorarios = true;
      } else {
        tieneHorarios = false;
      }
    } else {
      // OpenTripMap no provee horarios por diseño
      tieneHorarios = false;
    }

    // RQNF42/43/44: validar disponibilidad con los horarios reales
    if (tieneHorarios == true && weekdayText.isNotEmpty) {
      if (_estaCerradoEseDia(weekdayText, dia.weekday)) {
        // RQNF44 + RQF125: bloquear y mostrar mensaje exacto del requerimiento
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Este lugar no estará disponible el día seleccionado. ¿Deseas elegir otro día o lugar?",
              ),

              backgroundColor: Color.fromARGB(255, 150, 150, 150),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return; // No se agrega
      }

      // RQF124: detectar horario especial o festivo en el texto del día
      final lineaDia = weekdayText[dia.weekday - 1].toLowerCase();
      final tieneHorarioEspecial =
          lineaDia.contains('hours might differ') ||
          lineaDia.contains('holiday') ||
          lineaDia.contains('festivo') ||
          lineaDia.contains('horario especial');

      if (tieneHorarioEspecial && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Aviso: este lugar puede tener horario especial ese día. Verifica antes de visitar.",
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else {
      // Sin horarios (OpenTripMap o Google sin datos): avisar pero permitir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "El horario de este lugar puede variar según el día seleccionado.",
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    // RQF127: normalizar campos para mostrar foto, nombre y categoría
    final lugarNormalizado = {
      "nombre": lugar["name"] ?? lugar["nombre"] ?? "Lugar",
      "categoria": (lugar["categoriaPrincipal"] ?? lugar["categoria"] ?? "")
          .toString()
          .trim(),
      "lat": lugar["lat"] ?? 0.0,
      "lng": lugar["lng"] ?? 0.0,
      "place_id": placeId,
      // Guardamos weekday_text como string para poder revalidar en el futuro
      "hours": weekdayText.isNotEmpty ? weekdayText.join(' | ') : '',
      "foto": lugar["foto"] ?? lugar["imagen"] ?? "",
      "direccion": lugar["direccion"] ?? "",
      "rating": lugar["rating"] ?? 0.0,
    };

    // RQF126: agregar al final conservando orden de inserción
    setState(() {
      itinerarioPorDia[fechaKey]!.add(lugarNormalizado);
    });

    // RQF129 / RQNF45: guardado automático
    ItinerarioServicio.guardarItinerarioEnFirebase(
      widget.idViaje,
      itinerarioPorDia,
    );
  }

  // ---------------------------------------------------------------------------
  // Carga itinerario desde Firebase
  // ---------------------------------------------------------------------------
  Future<void> cargarItinerario() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final viajeDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('viajes')
          .doc(widget.idViaje)
          .get();

      if (viajeDoc.exists) {
        destinoViaje = viajeDoc.data()?['destino'] ?? "";
      }

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('viajes')
          .doc(widget.idViaje)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['itinerario'] != null) {
          final itinerarioFirebase = data['itinerario'] as Map<String, dynamic>;
          final Map<String, List<Map<String, dynamic>>> mapaRecuperado = {};

          itinerarioFirebase.forEach((diaKey, lugares) {
            mapaRecuperado[diaKey] = (lugares as List<dynamic>)
                .map((l) => Map<String, dynamic>.from(l))
                .toList();
          });

          setState(() {
            itinerarioPorDia = mapaRecuperado;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al cargar itinerario: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(color: Color(0xFFF6A230)),
              child: const SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Itinerario",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Organiza tus actividades por día",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: diasDelViaje.length,
        itemBuilder: (context, index) {
          final dia = diasDelViaje[index];
          final fechaStr = "${dia.day}/${dia.month}/${dia.year}";
          final fechaKey = dia.toString().split(' ')[0];
          final cantidadLugares = itinerarioPorDia[fechaKey]?.length ?? 0;

          return Card(
            elevation: 1.5,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  "Día ${index + 1}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Text(
                      fechaStr,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    if (cantidadLugares > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6A230),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "$cantidadLugares/5",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                children: [
                  const SizedBox(height: 8),

                  if (itinerarioPorDia[fechaKey] != null)
                    ...itinerarioPorDia[fechaKey]!.asMap().entries.map((entry) {
                      final i = entry.key;
                      final lugar = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                (lugar['foto'] != null &&
                                    lugar['foto'].toString().isNotEmpty)
                                ? Image.network(
                                    lugar['foto'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _iconoSinFoto(),
                                  )
                                : _iconoSinFoto(),
                          ),
                          title: Text(
                            lugar['nombre'] ?? 'Lugar',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            lugar['categoria'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              setState(() {
                                itinerarioPorDia[fechaKey]!.removeAt(i);
                              });
                              ItinerarioServicio.guardarItinerarioEnFirebase(
                                widget.idViaje,
                                itinerarioPorDia,
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    LugarDetallePantalla(lugar: lugar),
                              ),
                            );
                          },
                        ),
                      );
                    }),

                  const SizedBox(height: 6),

                  Builder(
                    builder: (context) {
                      final lleno = cantidadLugares >= 5;
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: lleno
                            ? null
                            : () async {
                                final lugarSeleccionado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BusquedaPantalla(
                                      esSeleccion: true,
                                      destinoInicial: destinoViaje,
                                    ),
                                  ),
                                );
                                if (lugarSeleccionado != null) {
                                  await agregarLugarADia(
                                    dia,
                                    lugarSeleccionado,
                                  );
                                }
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: lleno ? Colors.grey.shade100 : null,
                            border: Border.all(
                              color: lleno
                                  ? Colors.grey.shade200
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                lleno ? Icons.block : Icons.add_location_alt,
                                size: 20,
                                color: lleno
                                    ? Colors.grey.shade400
                                    : Colors.black87,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                lleno
                                    ? "Máximo 5 lugares por día"
                                    : "Agregar lugar",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: lleno
                                      ? Colors.grey.shade400
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _iconoSinFoto() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}
