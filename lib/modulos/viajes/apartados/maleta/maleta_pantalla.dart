import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/modelos/maleta.dart';
import 'package:proyecto/nucleo/servicios/generador_maleta_servicio.dart';
import 'package:proyecto/nucleo/servicios/maleta_firebase_servicio.dart';

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

  DateTime? inicio;
  DateTime? fin;

  @override
  void initState() {
    super.initState();
    cargarViajeYGenerar();
  }

  Future<void> cargarViajeYGenerar() async {
    final doc = await FirebaseFirestore.instance
        .collection("viajes")
        .doc(widget.idViaje)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;

    final inicioRaw = data["fechaInicio"];
    final finRaw = data["fechaFin"];

    if (inicioRaw == null || finRaw == null) return;

    inicio = (inicioRaw as Timestamp).toDate();
    fin = (finRaw as Timestamp).toDate();

    await generarMaletaInicial();
  }

  Future<void> generarMaletaInicial() async {
    if (inicio == null || fin == null) return;

    final ref = FirebaseFirestore.instance
        .collection("viajes")
        .doc(widget.idViaje)
        .collection("maleta");

    final snapshot = await ref.limit(1).get();

    if (snapshot.docs.isNotEmpty) return;

    final dias = fin!.difference(inicio!).inDays;

    final lista = await generador.generarMaleta(
      destino: widget.destino,
      inicio: inicio!,
      fin: fin!,
      actividades: ["senderismo"],
      dias: dias,
    );

    await servicio.guardarMaleta(widget.idViaje, lista);
  }

  void mostrarDialogo() {
    String texto = "";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Agregar artículo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          onChanged: (value) => texto = value,
          decoration: InputDecoration(
            hintText: "Ej: Bloqueador solar",
            filled: true,
            fillColor: const Color.fromARGB(255, 235, 235, 235),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Color(0xFF0066D2)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066D2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (texto.isNotEmpty) {
                servicio.agregarItem(
                  widget.idViaje,
                  ItemMaleta(nombre: texto, esPersonalizado: true),
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Agregar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),

      extendBodyBehindAppBar: false,
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
                      "Mi Maleta",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Lista de artículos para tu viaje",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.destino,
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

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              "Lista de artículos",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<ItemMaleta>>(
              stream: servicio.obtenerMaleta(widget.idViaje),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final lista = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final item = lista[i];

                    return Card(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              activeColor: const Color(0xFF0066D2),
                              value: item.completado,
                              onChanged: (v) {
                                servicio.actualizarEstado(
                                  widget.idViaje,
                                  item.id!,
                                  v!,
                                );
                              },
                            ),
                          ],
                        ),
                        title: Text(
                          item.nombre,
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            servicio.eliminarItem(widget.idViaje, item.id!);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0066D2),
        onPressed: mostrarDialogo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
