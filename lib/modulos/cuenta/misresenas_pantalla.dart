import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class MisResenasPantalla extends StatelessWidget {
  const MisResenasPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pack&Go",
          style: GoogleFonts.poppins(fontSize: 36),
        ),
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
                "Mis reseñas",
                style: GoogleFonts.poppins(fontSize: 24),
              ),

              const SizedBox(height: 30),

              // 📝 RESEÑAS REALIZADAS
              _botonSeccion(
                context,
                "Reseñas realizadas",
                const ListaResenasRealizadas(),
              
              ),

              const SizedBox(height: 18),

              // ❤️ RESEÑAS FAVORITAS
              _botonSeccion(
                context,
                "Reseñas favoritas",
                const ListaResenasFavoritas(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonSeccion(
    BuildContext context,
    String titulo,
    Widget pantalla,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => pantalla),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          titulo,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

// =======================================================
// 📝 RESEÑAS REALIZADAS
// =======================================================

class ListaResenasRealizadas extends StatelessWidget {
  const ListaResenasRealizadas({super.key});

  int _ranking(Map<String, dynamic> r) {
    return ((r['estrellas'] ?? 0) * 10) +
        ((r['likes'] ?? 0) * 1) +
        ((r['me_encanta'] ?? 0) * 2);
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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reseñas realizadas"),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
      ),

      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('resenas')
            .where('id_usuario', isEqualTo: uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          docs.sort((a, b) {
            final rankingA =
                _ranking(a.data() as Map<String, dynamic>);

            final rankingB =
                _ranking(b.data() as Map<String, dynamic>);

            final compararRanking =
                rankingB.compareTo(rankingA);

            if (compararRanking != 0) {
              return compararRanking;
            }

            final fechaA =
                (a['fecha'] as Timestamp?)?.toDate() ??
                DateTime(2000);

            final fechaB =
                (b['fecha'] as Timestamp?)?.toDate() ??
                DateTime(2000);

            return fechaB.compareTo(fechaA);
          });

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Aún no has realizado reseñas",
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data =
                  docs[i].data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 5,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10),
                      child: data['foto'] != null
                          ? Image.network(
                              data['foto'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.image,
                              ),
                            ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['nombre_lugar'] ?? "",
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 5),

                          _buildEstrellas(
                            data['estrellas'] ?? 0,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            data['texto'] ?? "",
                            maxLines: 3,
                            overflow:
                                TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                color:
                                    Colors.red.shade300,
                                size: 18,
                              ),

                              const SizedBox(width: 4),

                              Text(
                                "${data['me_encanta'] ?? 0}",
                              ),

                              const SizedBox(width: 15),

                              Icon(
                                Icons.thumb_up,
                                color:
                                    Colors.blue.shade300,
                                size: 18,
                              ),

                              const SizedBox(width: 4),

                              Text(
                                "${data['likes'] ?? 0}",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =======================================================
// ❤️ RESEÑAS FAVORITAS
// =======================================================

class ListaResenasFavoritas extends StatelessWidget {
  const ListaResenasFavoritas({super.key});

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

  Future<List<DocumentSnapshot>> _obtenerFavoritas(
    String uid,
  ) async {
    final favoritasSnap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('resenas_favoritas')
        .get();

    List<DocumentSnapshot> resenasFinales = [];

    for (var fav in favoritasSnap.docs) {
      final idResena = fav['id_resena'];

      final resenaDoc = await FirebaseFirestore.instance
          .collection('resenas')
          .doc(idResena)
          .get();

      if (resenaDoc.exists) {
        resenasFinales.add(resenaDoc);
      }
    }

    return resenasFinales;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reseñas favoritas"),
        backgroundColor: Colors.white,
      ),

      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _obtenerFavoritas(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Aún no tienes reseñas favoritas",
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data =
                  docs[i].data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 5,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10),
                      child: data['foto'] != null
                          ? Image.network(
                              data['foto'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.image,
                              ),
                            ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['nombre_lugar'] ?? "",
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 5),

                          _buildEstrellas(
                            data['estrellas'] ?? 0,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            data['texto'] ?? "",
                            maxLines: 3,
                            overflow:
                                TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                color:
                                    Colors.red.shade300,
                                size: 18,
                              ),

                              const SizedBox(width: 4),

                              Text(
                                "${data['me_encanta'] ?? 0}",
                              ),

                              const SizedBox(width: 15),

                              Icon(
                                Icons.thumb_up,
                                color:
                                    Colors.blue.shade300,
                                size: 18,
                              ),

                              const SizedBox(width: 4),

                              Text(
                                "${data['likes'] ?? 0}",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}