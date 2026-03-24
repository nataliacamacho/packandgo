import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/modulos/viajes/crear_viaje_pantalla.dart';
import '../../nucleo/servicios/foursquare_servicio.dart'; 
import '../../nucleo/servicios/opentripmap_servicio.dart';
import 'lugar_seleccionado_pantalla.dart';

class ExploracionPantalla extends StatefulWidget {
  const ExploracionPantalla({super.key});

  @override
  State<ExploracionPantalla> createState() => _ExploracionPantallaState();
}

class _ExploracionPantallaState extends State<ExploracionPantalla> {
  List<dynamic> lugaresRecomendados = [];
  bool estaCargando = true; 
  
  // Llevamos la cuenta de qué tarjeta vamos viendo
  int indiceActual = 0; 

  @override
  void initState() {
    super.initState();
    _cargarLugares();
  }

  Future<void> _cargarLugares() async {
    // 1. Despertamos al nuevo mensajero de OpenTripMap
    final lugaresCulturales = await OpenTripMapServicio.buscarLugaresCulturales(20.659, -103.349);
    
    // 2. El "Traductor": Acomodamos los datos para que tu carrusel y la pantalla de detalles los entiendan
    List<dynamic> lugaresAdaptados = [];
    
    for (var item in lugaresCulturales) {
      final propiedades = item['properties'];
      
      // OpenTripMap a veces manda monumentos sin nombre, así que filtramos solo los que sí tengan
      if (propiedades != null && propiedades['name'] != '') {
        lugaresAdaptados.add({
          'name': propiedades['name'],
          // OTM manda las categorías juntas, le ponemos una genérica para que se vea bien en tu diseño
          'categories': [{'name': 'Cultura y Turismo'}], 
          'location': {'formatted_address': 'Guadalajara, Jalisco'} 
        });
      }
    }

    if (mounted) {
      setState(() {
        // Si encontró lugares, tomamos los primeros 5 para tu carrusel
        if (lugaresAdaptados.isNotEmpty) {
          lugaresRecomendados = lugaresAdaptados.take(5).toList();
        }
        estaCargando = false;
        indiceActual = 0; 
      });
    }
  }

  // Lógica para el botón derecho (Siguiente)
  void _siguienteLugar() {
    if (indiceActual < lugaresRecomendados.length - 1) {
      setState(() {
        indiceActual++;
      });
    }
  }

  // Lógica para el botón izquierdo (Anterior)
  void _anteriorLugar() {
    if (indiceActual > 0) {
      setState(() {
        indiceActual--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String nombre = 'Desconocido';
    String urlImagen = '';

    if (lugaresRecomendados.isNotEmpty) {
      final lugar = lugaresRecomendados[indiceActual];
      nombre = lugar['name'] ?? 'Lugar sin nombre';
      
      // Armamos el rompecabezas de la foto de Foursquare
      if (lugar['photos'] != null && lugar['photos'].isNotEmpty) {
        final foto = lugar['photos'][0];
        // Foursquare pide que metamos el tamaño entre el prefix y el suffix
        urlImagen = '${foto['prefix']}500x500${foto['suffix']}';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Pack&Go",
          style: TextStyle(
            color: Color(0xFF0066D2), 
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFF0066D2), size: 32),
            onPressed: () {
               Navigator.pushNamed(context, '/EditarPerfil');
            },
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "¡Tu app favorita de viajes!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "Recomendaciones",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              
              // --- CARRUSEL CENTRAL ---
              SizedBox(
                height: 250, 
                child: estaCargando 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0066D2)))
                    : lugaresRecomendados.isEmpty
                        ? const Center(child: Text("No hay recomendaciones cerca."))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              
                              // Flecha Izquierda
                              GestureDetector(
                                onTap: indiceActual > 0 ? _anteriorLugar : null,
                                child: Container(
                                  width: 40,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    // Si no hay lugares atrás, se pone gris
                                    color: indiceActual > 0 ? const Color(0xFF0066D2) : Colors.grey[300], 
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                                ),
                              ),

                              const SizedBox(width: 15),

                              // --- BLOQUE DE LA TARJETA CENTRAL ---
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    // 1. Tomamos los datos del lugar que se está mostrando
                                    final lugarSeleccionado = lugaresRecomendados[indiceActual];
                                    
                                    // 2. Viajamos a la nueva pantalla llevándonos los datos
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LugarSeleccionadoPantalla(lugar: lugarSeleccionado),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0066D2),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.blueAccent,
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.landscape, color: Colors.white, size: 70),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(15.0),
                                          child: Text(
                                            nombre,
                                            style: const TextStyle(
                                              color: Colors.white, 
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),

                              // Flecha Derecha
                              GestureDetector(
                                onTap: indiceActual < lugaresRecomendados.length - 1 ? _siguienteLugar : null,
                                child: Container(
                                  width: 40,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: indiceActual < lugaresRecomendados.length - 1 ? const Color(0xFF0066D2) : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
              ),
              const SizedBox(height: 40),

              // --- BOTÓN CREAR VIAJE (Fusionado con el de Natalia) ---
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CrearViajePantalla(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    "Crear Viaje",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6A230),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0066D2),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0: break;
            case 1: break;
            case 2: break;
            case 3: break;
            case 4: Navigator.pushNamed(context, '/EditarPerfil'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 32), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search, size: 32), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box, size: 32), label: 'Crear'),
          BottomNavigationBarItem(icon: Icon(Icons.luggage, size: 32), label: 'Viaje'),
          BottomNavigationBarItem(icon: Icon(Icons.person, size: 32), label: 'Perfil'),
        ],
      ),
    );
  }
}