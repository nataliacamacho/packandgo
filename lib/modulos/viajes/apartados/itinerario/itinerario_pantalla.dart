import 'package:flutter/material.dart';
import 'package:proyecto/modulos/busqueda/busqueda_pantalla.dart';
import 'package:proyecto/modulos/busqueda/lugar_detalle_pantalla.dart';
import 'package:proyecto/nucleo/servicios/itinerario_servicio.dart';
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

  void agregarLugarADia(DateTime dia, Map<String, dynamic> lugar) {
    String fechaKey = dia.toString().split(' ')[0];
    itinerarioPorDia.putIfAbsent(fechaKey, () => []);

    final lugarNormalizado = {
      "nombre": lugar["nombre"],
      "categoria": (lugar["categoria"] ?? "").toString().trim(),
      "lat": lugar["lat"],
      "lng": lugar["lng"],
      "hours": lugar["hours"],
      "foto": lugar["foto"],
      "direccion": lugar["direccion"],
      "rating": lugar["rating"],
    };

    // Máximo 5 lugares
    if (itinerarioPorDia[fechaKey]!.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Máximo 5 lugares por día")));
      return;
    }

    /// 🔥 CAMBIO CLAVE: si no hay hours, lo dejamos pasar
    bool estaAbierto = true;

    if (lugar['hours'] != null) {
      estaAbierto = ItinerarioServicio.verificarApertura(dia, lugar['hours']);
    }

    if (estaAbierto) {
      setState(() {
        itinerarioPorDia[fechaKey]!.add(lugarNormalizado);
      });
    } else {
      ItinerarioServicio.mostrarAlertaCerrado(context);
    }

    debugPrint("LUGAR SELECCIONADO: $lugar");
  }

  String normalizarDestino(String destino) {
    destino = destino.toLowerCase().trim();

    // quitar todo después de coma (estado/país)
    if (destino.contains(",")) {
      destino = destino.split(",").first.trim();
    }

    // limpiar palabras comunes
    final removibles = [
      "heroica",
      "de juárez",
      "juarez",
      "pueblo mágico",
      "estado de",
      "cdmx",
      "ciudad de",
    ];

    for (final r in removibles) {
      destino = destino.replaceAll(r, "");
    }

    destino = destino.trim();

    // capitalizar
    return destino
        .split(" ")
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(" ");
  }

  Future<void> cargarItinerario() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      final viajeDoc = await FirebaseFirestore.instance
          .collection('viajes')
          .doc(widget.idViaje)
          .get();

      if (viajeDoc.exists) {
        final dataViaje = viajeDoc.data();

        destinoViaje = dataViaje?['destino'] ?? "";
      }

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('viajes')
          .doc(widget.idViaje)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['itinerario'] != null) {
          Map<String, dynamic> itinerarioFirebase = data['itinerario'];
          Map<String, List<Map<String, dynamic>>> mapaRecuperado = {};

          itinerarioFirebase.forEach((diaKey, lugares) {
            List<dynamic> listaLugares = lugares as List<dynamic>;

            mapaRecuperado[diaKey] = listaLugares
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
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

            // Botón de regreso encima sin afectar el centrado
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
          DateTime dia = diasDelViaje[index];
          String fechaStr = "${dia.day}/${dia.month}/${dia.year}";
          String fechaKey = dia.toString().split(' ')[0];

          return Card(
            elevation: 1.5,
            color: const Color.fromARGB(255, 255, 255, 255),
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor:
                    Colors.transparent, // quita línea fea del ExpansionTile
              ),
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

                subtitle: Text(
                  fechaStr,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),

                children: [
                  const SizedBox(height: 8),

                  /// Lugares agregados
                  /// Lugares agregados
                  if (itinerarioPorDia[fechaKey] != null)
                    ...itinerarioPorDia[fechaKey]!.asMap().entries.map((entry) {
                      int i = entry.key;
                      Map<String, dynamic> lugar = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),

                          /// FOTO
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: lugar['foto'] != null
                                ? Image.network(
                                    lugar['foto'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.image),
                                  ),
                          ),

                          /// NOMBRE
                          title: Text(
                            lugar['nombre'] ?? 'Lugar',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          /// CATEGORÍA
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lugar['categoria'] ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                "Orden #${i + 1}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),

                          /// BOTÓN ELIMINAR
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              setState(() {
                                itinerarioPorDia[fechaKey]!.removeAt(i);
                              });
                            },
                          ),

                          /// ABRIR DETALLES DEL LUGAR
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

                  /// Botón agregar
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final lugarSeleccionado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BusquedaPantalla(
                            esSeleccion: true,
                          ),
                        ),
                      );

                      if (lugarSeleccionado != null) {
                        agregarLugarADia(dia, lugarSeleccionado);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_location_alt, size: 20),
                          SizedBox(width: 6),
                          Text(
                            "Agregar lugar",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await ItinerarioServicio.guardarItinerarioEnFirebase(
            widget.idViaje,
            itinerarioPorDia,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("¡Itinerario guardado!"),
                backgroundColor: Color.fromARGB(255, 150, 150, 150),
              ),
            );
          }
        },
        icon: const Icon(
          Icons.cloud_upload,
          color: Color.fromARGB(255, 255, 255, 255),
        ),
        label: const Text(
          "Guardar",
          style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        ),
        backgroundColor: Color(0xFF0066D2),
      ),
    );
  }
}
