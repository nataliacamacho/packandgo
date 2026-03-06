import 'package:flutter/material.dart';

class FiltrosBusqueda extends StatelessWidget {
  final String? destinoSeleccionado;
  final String? tipoSeleccionado;
  final String? estiloSeleccionado;
  final String? precioSeleccionado;

  final ValueChanged<String?> onDestinoChanged;
  final ValueChanged<String?> onTipoChanged;
  final ValueChanged<String?> onEstiloChanged;
  final ValueChanged<String?> onPrecioChanged;

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
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildDropdown(
            titulo: destinoSeleccionado ?? "Destino",
            opciones: const ["México", "Yucatán", "Jalisco"],
            seleccionado: destinoSeleccionado,
            onChanged: onDestinoChanged,
            siempreNaranja: true,
          ),

          const SizedBox(width: 8),

          _buildDropdown(
            titulo: tipoSeleccionado ?? "Tipo",
            opciones: const ["Playa", "Cultural", "Naturaleza"],
            seleccionado: tipoSeleccionado,
            onChanged: onTipoChanged,
          ),

          const SizedBox(width: 8),

          _buildDropdown(
            titulo: estiloSeleccionado ?? "Estilo",
            opciones: const ["Familiar", "Amigos", "En pareja", "Solo"],
            seleccionado: estiloSeleccionado,
            onChanged: onEstiloChanged,
          ),

          const SizedBox(width: 8),

          _buildDropdown(
            titulo: precioSeleccionado ?? "Precio",
            opciones: const ["\$", "\$\$", "\$\$\$"],
            seleccionado: precioSeleccionado,
            onChanged: onPrecioChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String titulo,
    required List<String> opciones,
    required String? seleccionado,
    required ValueChanged<String?> onChanged,
    bool siempreNaranja = false,
  }) {
    return PopupMenuButton<String>(
      onSelected: (valor) {
        // si selecciona el mismo valor → se deselecciona
        if (valor == seleccionado) {
          onChanged(null);
        } else {
          onChanged(valor);
        }
      },
      itemBuilder: (context) {
        return opciones.map((opcion) {
          return PopupMenuItem<String>(
            value: opcion,
            child: Row(
              children: [
                Expanded(child: Text(opcion)),
                if (opcion == seleccionado) const Icon(Icons.check, size: 14),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado != null || siempreNaranja
              ? const Color(0xFFF6A230)
              : const Color(0xFFF5D09E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(titulo, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }
}
