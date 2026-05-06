import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/nucleo/constanstes/categorias.dart';

class FiltrosBusqueda extends StatelessWidget {
  final String? destinoSeleccionado;
  final String? tipoSeleccionado;
  final String? estiloSeleccionado;
  final String? precioSeleccionado;

  final ValueChanged<String?> onDestinoChanged;
  final ValueChanged<String?> onTipoChanged;
  final ValueChanged<String?> onEstiloChanged;
  final ValueChanged<String?> onPrecioChanged;

  final bool mostrarDestino;
  final bool mostrarTipo;
  final bool mostrarEstilo;
  final bool mostrarPrecio;

  const FiltrosBusqueda({
    super.key,
    required this.destinoSeleccionado,
    required this.tipoSeleccionado,
    required this.estiloSeleccionado,
    required this.precioSeleccionado,
    required this.onDestinoChanged,
    required this.onTipoChanged,
    required this.onEstiloChanged,
    required this.onPrecioChanged,
    this.mostrarDestino = true,
    this.mostrarTipo = true,
    this.mostrarEstilo = true,
    this.mostrarPrecio = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (mostrarDestino) ...[
            _buildDropdownCiudades(),
            const SizedBox(width: 8),
          ],

          if (mostrarTipo) ...[
            _buildDropdown(
              titulo: tipoSeleccionado ?? "Tipo",
              opciones: const [
                {"label": "Restaurante", "value": "restaurante"},
                {"label": "Cafetería", "value": "cafeteria"},
                {"label": "Bar", "value": "bar"},
                {"label": "Parque", "value": "parque"},
                {"label": "Museo", "value": "museo"},
                {"label": "Playa", "value": "playa"},
                {"label": "Monumento", "value": "monumento"},
                {"label": "Zona arqueológica", "value": "zona_arqueologica"},
                {"label": "Mirador", "value": "mirador"},
                {"label": "Centro comercial", "value": "centro_comercial"},
                {
                  "label": "Actividades extremas",
                  "value": "actividades_extremas",
                },
              ],
              seleccionado: tipoSeleccionado,
              onChanged: onTipoChanged,
            ),
            const SizedBox(width: 8),
          ],

          if (mostrarEstilo) ...[
            _buildDropdown(
              titulo: estiloSeleccionado ?? "Experiencia",
              opciones: const [
                {"label": "Familiar", "value": "familiar"},
                {"label": "Amigos", "value": "amigos"},
                {"label": "Solo", "value": "solo"},
                {"label": "En pareja", "value": "pareja"},
              ],
              seleccionado: estiloSeleccionado,
              onChanged: onEstiloChanged,
            ),
            const SizedBox(width: 8),
          ],

          if (mostrarPrecio) ...[
            _buildDropdown(
              titulo: precioSeleccionado ?? "Precio",
              opciones: const [
                {"label": "\$", "value": "\$"},
                {"label": "\$\$", "value": "\$\$"},
                {"label": "\$\$\$", "value": "\$\$\$"},
              ],
              seleccionado: precioSeleccionado,
              onChanged: onPrecioChanged,
            ),
          ],
        ],
      ),
    );
  }

  // 🔥 CIUDADES DESDE FIRESTORE (CLAVE = doc.id)
  Widget _buildDropdownCiudades() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ciudades')
          .orderBy('nombre')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _container("Cargando...", false);
        }

        final docs = snapshot.data!.docs;

        return PopupMenuButton<String>(
          onSelected: (valor) {
            if (valor == destinoSeleccionado) {
              onDestinoChanged(null);
            } else {
              onDestinoChanged(valor);
            }
          },
          itemBuilder: (context) {
            return docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return PopupMenuItem<String>(
                value: doc.id, // 🔥 IMPORTANTE: usamos el ID (gdl, cdmx...)
                child: Row(
                  children: [
                    Expanded(child: Text(data["nombre"])),
                    if (doc.id == destinoSeleccionado)
                      const Icon(Icons.check, size: 14),
                  ],
                ),
              );
            }).toList();
          },
          child: _container(
            _nombreSeleccionado(docs),
            destinoSeleccionado != null,
          ),
        );
      },
    );
  }

  String _nombreSeleccionado(List docs) {
    if (destinoSeleccionado == null) return "Destino";

    try {
      final doc = docs.firstWhere((d) => d.id == destinoSeleccionado);
      return (doc.data() as Map<String, dynamic>)["nombre"];
    } catch (_) {
      return "Destino";
    }
  }

  Widget _buildDropdown({
    required String titulo,
    required List<Map<String, String>> opciones,
    required String? seleccionado,
    required ValueChanged<String?> onChanged,
  }) {
    return PopupMenuButton<String>(
      onSelected: (valor) {
        if (valor == seleccionado) {
          onChanged(null);
        } else {
          onChanged(valor);
        }
      },
      itemBuilder: (context) {
        return opciones.map((opcion) {
          final label = opcion["label"]!;
          final value = opcion["value"]!;

          return PopupMenuItem<String>(
            value: value,
            child: Row(
              children: [
                Expanded(child: Text(label)),
                if (value == seleccionado) const Icon(Icons.check, size: 14),
              ],
            ),
          );
        }).toList();
      },
      child: _container(
        opciones.firstWhere(
          (e) => e["value"] == seleccionado,
          orElse: () => {"label": titulo},
        )["label"]!,
        seleccionado != null,
      ),
    );
  }

  Widget _container(String texto, bool activo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFF6A230) : const Color(0xFFF5D09E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(texto),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
    );
  }
}
