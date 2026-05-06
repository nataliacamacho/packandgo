import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class MisResenasPantalla extends StatefulWidget {
  const MisResenasPantalla({super.key});

  @override
  State<MisResenasPantalla> createState() => _MisResenasPantallaState();
}

class _MisResenasPantallaState extends State<MisResenasPantalla> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  int _ranking(Map<String, dynamic> r) {
    return (r['estrellas'] * 10) + (r['likes'] * 1) + (r['me_encanta'] * 2);
  }

  Future<List<QueryDocumentSnapshot>> _obtenerResenas() async {
    final snap = await FirebaseFirestore.instance
        .collection('resenas')
        .where('id_usuario', isEqualTo: uid)
        .get();

    final docs = snap.docs;

    docs.sort(
      (a, b) => _ranking(
        b.data() as Map<String, dynamic>,
      ).compareTo(_ranking(a.data() as Map<String, dynamic>)),
    );

    return docs;
  }

  Future<void> _toggleFavorita(String id, bool actual) async {
    await FirebaseFirestore.instance.collection('resenas').doc(id).update({
      'es_favorita': !actual,
    });

    setState(() {});
  }

  Widget _buildEstrellas(int estrellas) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < estrellas ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.orange,
        ),
      ),
    );
  }

  Widget _buildCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255), // gris claro como tu diseño
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔵 IMAGEN
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              "Imagen",
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),

          const SizedBox(width: 12),

          // 📝 INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nombre del lugar: ${data['nombre_lugar'] ?? ""}",
                  style: const TextStyle(fontSize: 13),
                ),

                const SizedBox(height: 4),

                Text(
                  "Calificación: ${data['estrellas'] ?? 0} ⭐",
                  style: const TextStyle(fontSize: 13),
                ),

                const SizedBox(height: 4),

                Text(
                  "Comentario: ${data['texto'] ?? ""}",
                  style: const TextStyle(fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pack&Go", style: GoogleFonts.poppins(fontSize: 36)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Text(
                "Reseñas realizadas",
                style: GoogleFonts.poppins(fontSize: 22),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: FutureBuilder<List<QueryDocumentSnapshot>>(
                  future: _obtenerResenas(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final resenas = snapshot.data!;

                    if (resenas.isEmpty) {
                      return const Center(
                        child: Text("Aún no has hecho reseñas"),
                      );
                    }

                    return ListView.builder(
                      itemCount: resenas.length,
                      itemBuilder: (_, i) => _buildCard(resenas[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
