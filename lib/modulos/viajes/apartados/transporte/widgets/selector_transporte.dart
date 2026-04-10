import 'package:flutter/material.dart';

class SelectorTransporte extends StatelessWidget {
  const SelectorTransporte({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),

        _tarjetaTransporte(
          context,
          icono: Icons.directions_car,
          titulo: "Carro",
          descripcion: "Ruta en automóvil con mapa en tiempo real",
          color: const Color(0xFF0066D2),
          onTap: () {
            Navigator.pushNamed(context, '/transporte/carro');
          },
        ),

        _tarjetaTransporte(
          context,
          icono: Icons.directions_bus,
          titulo: "Autobús",
          descripcion: "Rutas con horarios, precios y terminales",
          color: Colors.orange,
          onTap: () {
            Navigator.pushNamed(context, '/transporte/autobus');
          },
        ),

        _tarjetaTransporte(
          context,
          icono: Icons.flight,
          titulo: "Avión",
          descripcion: "Vuelos disponibles y estimaciones de precio",
          color: Colors.purple,
          onTap: () {
            Navigator.pushNamed(context, '/transporte/avion');
          },
        ),

        _tarjetaTransporte(
          context,
          icono: Icons.route,
          titulo: "Ruta Mixta",
          descripcion: "Combina carro, bus y avión en una sola ruta",
          color: Colors.green,
          onTap: () {
            Navigator.pushNamed(context, '/transporte/mixto');
          },
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _tarjetaTransporte(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String descripcion,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 30),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}