import 'package:flutter/material.dart';

class LugarSeleccionadoPantalla extends StatelessWidget {
  // Esta variable es la "caja" donde recibiremos los datos del lugar al que le diste clic
  final Map<String, dynamic> lugar;

  const LugarSeleccionadoPantalla({super.key, required this.lugar, required nombre});

  @override
  Widget build(BuildContext context) {
    // Extraemos la información del lugar (Foursquare nos da estos campos)
    final nombre = lugar['name'] ?? 'Lugar desconocido';
    
    // Extraemos la categoría (Foursquare las manda en una lista, tomamos la primera)
    final categoria = (lugar['categories'] != null && lugar['categories'].isNotEmpty)
        ? lugar['categories'][0]['name']
        : 'Atracción turística';
        
    final ubicacion = lugar['location']?['formatted_address'] ?? 'Ubicación desconocida';

    return Scaffold(
      backgroundColor: Colors.white,
      
      // 1. ENCABEZADO CON BOTÓN DE REGRESO
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0066D2)),
          onPressed: () {
            Navigator.pop(context); // Esto hace que el botón de regresar funcione
          },
        ),
        title: const Text(
          "Pack&Go",
          style: TextStyle(color: Color(0xFF0066D2), fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
      ),
      
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2. IMAGEN DEL LUGAR (Por ahora la montañita azul)
              Container(
                width: double.infinity,
                height: 150, 
                decoration: BoxDecoration(
                  color: const Color(0xFF0066D2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Icon(Icons.landscape, color: Colors.white, size: 60),
                ),
              ),
              const SizedBox(height: 20),
              
              // 3. INFORMACIÓN DEL LUGAR
              Text(nombre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(categoria, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 15),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFF6A230), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ubicacion, style: const TextStyle(fontSize: 14))),
                ],
              ),
              const SizedBox(height: 10),
              
              const Row(
                children: [
                  Icon(Icons.access_time, color: Color(0xFFF6A230), size: 20),
                  SizedBox(width: 8),
                  Text("Horario disponible pronto", style: TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 20),
              
              // 4. RESEÑAS DESPLEGABLES
              ExpansionTile(
                title: const Text("Reseñas", style: TextStyle(fontWeight: FontWeight.bold)),
                iconColor: const Color(0xFF0066D2),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    width: double.infinity,
                    color: Colors.grey[50],
                    child: const Text("Aún no hay reseñas para este lugar. ¡Sé el primero en opinar!"),
                  )
                ],
              ),
              const SizedBox(height: 20),
              
              // 5. MAPA (Placeholder)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Text("🗺️ Fragmento de Mapa aquí", style: TextStyle(fontSize: 16, color: Colors.black54)),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // 6. BARRA DE NAVEGACIÓN INFERIOR ACTIVA
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0066D2),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: 0, // Seguimos en el flujo de exploración
        onTap: (index) {
          switch (index) {
            case 0:
              // Para ir al inicio, destruimos esta pantalla y volvemos a la exploración
              Navigator.pushNamedAndRemoveUntil(context, '/exploracion', (route) => false);
              break;
            case 4:
              // Ir al Perfil
              Navigator.pushNamed(context, '/EditarPerfil');
              break;
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