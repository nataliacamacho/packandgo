import 'package:flutter/material.dart';
import 'package:proyecto/modelos/maleta.dart';
import 'package:proyecto/nucleo/servicios/maleta_firebase_servicio.dart';
import 'package:proyecto/nucleo/servicios/generador_maleta_servicio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    generarMaletaInicial();
  }

  // 🔥 GENERAR SOLO UNA VEZ
  Future<void> generarMaletaInicial() async {
    final ref = FirebaseFirestore.instance
        .collection("usuarios")
        .doc(servicio.uid)
        .collection("viajes")
        .doc(widget.idViaje)
        .collection("maleta");

    final snapshot = await ref.limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      print("🛑 Maleta ya existe, no se regenera");
      return;
    }

    print("✅ Generando maleta por primera vez...");

    final lista = await generador.generarMaleta(
      destino: widget.destino,
      inicio: DateTime(2026, 7, 1), // ⚠️ luego cámbialo por datos reales
      fin: DateTime(2026, 7, 5),
      actividades: ["senderismo"],
    );

    await servicio.guardarMaleta(widget.idViaje, lista);
  }

  // -------------------------
  void mostrarDialogo() {
    String texto = "";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        backgroundColor: Colors.white, // 👈 fondo limpio

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // 👈 bordes modernos
        ),

        title: Row(
          children: const [
            SizedBox(width: 8),
            Text(
              "Agregar artículo",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        content: TextField(
          onChanged: (value) => texto = value,
          decoration: InputDecoration(
            hintText: "Ej: Bloqueador solar",

            filled: true,
            fillColor: Color(0xFFF5F5F5), // 👈 gris suave

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        actions: [
          // 🔹 CANCELAR
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),

          // 🔹 AGREGAR
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066D2), // 👈 azul app
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

  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔥 HEADER
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
                      "Una lista de artículos\n recomendados para tu viaje",
                      textAlign: TextAlign.center,
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

            // 🔙 BACK
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

      // 🔥 BODY CORREGIDO
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 TÍTULO FIJO
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              "Lista de artículos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // 🔹 LISTA DINÁMICA
          Expanded(
            child: StreamBuilder<List<ItemMaleta>>(
              stream: servicio.obtenerMaleta(widget.idViaje),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final lista = snapshot.data!;

                if (lista.isEmpty) {
                  return const Center(child: Text("No hay artículos"));
                }

                return ListView.builder(
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final item = lista[i];

                    return ListTile(
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
                      title: Text(item.nombre),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () {
                          servicio.eliminarItem(widget.idViaje, item.id!);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 15, left: 15),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  
                  "Lista generada según clima y duración",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),

      // 🔥 FAB
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0066D2),
        onPressed: mostrarDialogo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
