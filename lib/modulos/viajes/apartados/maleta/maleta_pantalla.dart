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

  bool cargando = true;

  String? climaManual;

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

    if (!doc.exists) return;

    final data = doc.data()!;

    final inicio = (data['fechaInicio'] as Timestamp).toDate();

    final fin = (data['fechaFin'] as Timestamp).toDate();

    final actividades = List<String>.from(data['actividades'] ?? []);

    final lista = await generador.generarMaleta(
      destino: widget.destino,
      inicio: inicio,
      fin: fin,
      actividades: actividades,
      climaManual: climaManual,
    );

    await servicio.eliminarMaleta(widget.idViaje);

    await servicio.guardarMaleta(widget.idViaje, lista);

    setState(() {
      cargando = false;
    });
  }

  void mostrarDialogo() {
    String texto = '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Agregar artículo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (texto.trim().isNotEmpty) {
                await servicio.agregarItem(
                  widget.idViaje,
                  ItemMaleta(
                    nombre: texto.trim(),
                    esPersonalizado: true,
                    categoria: 'personalizado',
                  ),
                );
              }

              if (!mounted) return;

              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Widget botonClima(String texto) {
    final seleccionado = climaManual == texto;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
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
            // 🔥 Deseleccionar
            climaManual = null;
          } else {
            // 🔥 Seleccionar nuevo
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
          : Column(
              children: [
                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  children: [
                    botonClima('frio'),
                    botonClima('calor'),
                    botonClima('lluvia'),
                    botonClima('templado'),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Lista de artículos',
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
