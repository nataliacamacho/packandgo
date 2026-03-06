import 'package:flutter/material.dart';

class BarraBusqueda extends StatelessWidget {
  final Function(String) onChanged;

  const BarraBusqueda({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: const InputDecoration(
          icon: Icon(Icons.search),
          hintText: "Busca tu siguiente aventura",
          border: InputBorder.none,
        ),
      ),
    );
  }
}