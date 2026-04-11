import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> subirCiudades() async {
  final ciudades = [
    {"id":"cdmx","nombre":"Ciudad de México","estado":"CDMX","lat":19.4326,"lng":-99.1332,"popularidad":10,"clima":"templado","tipo":"ciudad","region":"centro","costa":false},
    {"id":"gdl","nombre":"Guadalajara","estado":"Jalisco","lat":20.6597,"lng":-103.3496,"popularidad":9.5,"clima":"templado","tipo":"ciudad","region":"centro","costa":false},
    {"id":"mty","nombre":"Monterrey","estado":"Nuevo León","lat":25.6866,"lng":-100.3161,"popularidad":9.5,"clima":"seco","tipo":"ciudad","region":"norte","costa":false},
    {"id":"cancun","nombre":"Cancún","estado":"Quintana Roo","lat":21.1619,"lng":-86.8515,"popularidad":10,"clima":"tropical","tipo":"playa","region":"sur","costa":true},
    {"id":"puebla","nombre":"Puebla","estado":"Puebla","lat":19.0414,"lng":-98.2063,"popularidad":9,"clima":"templado","tipo":"ciudad","region":"centro","costa":false},
    {"id":"merida","nombre":"Mérida","estado":"Yucatán","lat":20.9674,"lng":-89.5926,"popularidad":9,"clima":"calido","tipo":"ciudad","region":"sur","costa":false},
    {"id":"tijuana","nombre":"Tijuana","estado":"Baja California","lat":32.5149,"lng":-117.0382,"popularidad":8.5,"clima":"templado","tipo":"ciudad","region":"norte","costa":true},
    {"id":"leon","nombre":"León","estado":"Guanajuato","lat":21.1220,"lng":-101.6823,"popularidad":8.5,"clima":"templado","tipo":"ciudad","region":"centro","costa":false},
    {"id":"queretaro","nombre":"Querétaro","estado":"Querétaro","lat":20.5888,"lng":-100.3899,"popularidad":9,"clima":"templado","tipo":"ciudad","region":"centro","costa":false},
    {"id":"toluca","nombre":"Toluca","estado":"Estado de México","lat":19.2826,"lng":-99.6557,"popularidad":8,"clima":"frio","tipo":"ciudad","region":"centro","costa":false},

    {"id":"acapulco","nombre":"Acapulco","estado":"Guerrero","lat":16.8531,"lng":-99.8237,"popularidad":9,"clima":"tropical","tipo":"playa","region":"sur","costa":true},
    {"id":"puertovallarta","nombre":"Puerto Vallarta","estado":"Jalisco","lat":20.6534,"lng":-105.2253,"popularidad":9.5,"clima":"tropical","tipo":"playa","region":"centro","costa":true},
    {"id":"loscabos","nombre":"Los Cabos","estado":"Baja California Sur","lat":22.8905,"lng":-109.9167,"popularidad":9.5,"clima":"seco","tipo":"playa","region":"norte","costa":true},
    {"id":"mazatlan","nombre":"Mazatlán","estado":"Sinaloa","lat":23.2494,"lng":-106.4111,"popularidad":9,"clima":"calido","tipo":"playa","region":"norte","costa":true},
    {"id":"veracruz","nombre":"Veracruz","estado":"Veracruz","lat":19.1738,"lng":-96.1342,"popularidad":8.5,"clima":"tropical","tipo":"playa","region":"centro","costa":true},
    {"id":"oaxaca","nombre":"Oaxaca","estado":"Oaxaca","lat":17.0732,"lng":-96.7266,"popularidad":9.5,"clima":"templado","tipo":"ciudad","region":"sur","costa":false},
    {"id":"sanmiguel","nombre":"San Miguel de Allende","estado":"Guanajuato","lat":20.9144,"lng":-100.7430,"popularidad":9.5,"clima":"templado","tipo":"pueblo_magico","region":"centro","costa":false},
    {"id":"guanajuato","nombre":"Guanajuato","estado":"Guanajuato","lat":21.0190,"lng":-101.2574,"popularidad":9,"clima":"templado","tipo":"ciudad","region":"centro","costa":false},
    {"id":"morelia","nombre":"Morelia","estado":"Michoacán","lat":19.7050,"lng":-101.1949,"popularidad":8.5,"clima":"templado","tipo":"ciudad","region":"centro","costa":false},
    {"id":"zacatecas","nombre":"Zacatecas","estado":"Zacatecas","lat":22.7709,"lng":-102.5832,"popularidad":8.5,"clima":"seco","tipo":"ciudad","region":"norte","costa":false},

    {"id":"tuxtla","nombre":"Tuxtla Gutiérrez","estado":"Chiapas","lat":16.7528,"lng":-93.1167,"popularidad":7.5,"clima":"calido","tipo":"ciudad","region":"sur","costa":false},
    {"id":"sancristobal","nombre":"San Cristóbal de las Casas","estado":"Chiapas","lat":16.7370,"lng":-92.6376,"popularidad":9,"clima":"templado","tipo":"pueblo_magico","region":"sur","costa":false},
    {"id":"villahermosa","nombre":"Villahermosa","estado":"Tabasco","lat":17.9895,"lng":-92.9475,"popularidad":7.5,"clima":"tropical","tipo":"ciudad","region":"sur","costa":false},
    {"id":"campeche","nombre":"Campeche","estado":"Campeche","lat":19.8301,"lng":-90.5349,"popularidad":8,"clima":"calido","tipo":"playa","region":"sur","costa":true},
    {"id":"chetumal","nombre":"Chetumal","estado":"Quintana Roo","lat":18.5043,"lng":-88.3053,"popularidad":7.5,"clima":"tropical","tipo":"ciudad","region":"sur","costa":true},
    {"id":"playadelcarmen","nombre":"Playa del Carmen","estado":"Quintana Roo","lat":20.6296,"lng":-87.0739,"popularidad":9.5,"clima":"tropical","tipo":"playa","region":"sur","costa":true},
    {"id":"tulum","nombre":"Tulum","estado":"Quintana Roo","lat":20.2114,"lng":-87.4654,"popularidad":9.5,"clima":"tropical","tipo":"playa","region":"sur","costa":true},
    {"id":"cozumel","nombre":"Cozumel","estado":"Quintana Roo","lat":20.4229,"lng":-86.9223,"popularidad":9,"clima":"tropical","tipo":"playa","region":"sur","costa":true},

    {"id":"aguascalientes","nombre":"Aguascalientes","estado":"Aguascalientes","lat":21.8853,"lng":-102.2916,"popularidad":8,"clima":"seco","tipo":"ciudad","region":"centro","costa":false},
    {"id":"saltillo","nombre":"Saltillo","estado":"Coahuila","lat":25.4383,"lng":-100.9737,"popularidad":7.5,"clima":"seco","tipo":"ciudad","region":"norte","costa":false},
    {"id":"torreon","nombre":"Torreón","estado":"Coahuila","lat":25.5428,"lng":-103.4068,"popularidad":7.5,"clima":"seco","tipo":"ciudad","region":"norte","costa":false},
    {"id":"chihuahua","nombre":"Chihuahua","estado":"Chihuahua","lat":28.6329,"lng":-106.0691,"popularidad":8,"clima":"seco","tipo":"ciudad","region":"norte","costa":false},
    {"id":"juarez","nombre":"Ciudad Juárez","estado":"Chihuahua","lat":31.6904,"lng":-106.4245,"popularidad":7.5,"clima":"seco","tipo":"ciudad","region":"norte","costa":false},
    {"id":"durango","nombre":"Durango","estado":"Durango","lat":24.0277,"lng":-104.6532,"popularidad":8,"clima":"seco","tipo":"ciudad","region":"norte","costa":false},
    {"id":"hermosillo","nombre":"Hermosillo","estado":"Sonora","lat":29.0729,"lng":-110.9559,"popularidad":8,"clima":"seco","tipo":"ciudad","region":"norte","costa":false},
    {"id":"caborca","nombre":"Caborca","estado":"Sonora","lat":30.7167,"lng":-112.1500,"popularidad":7,"clima":"seco","tipo":"naturaleza","region":"norte","costa":false},

    {"id":"lapaz","nombre":"La Paz","estado":"Baja California Sur","lat":24.1426,"lng":-110.3128,"popularidad":9,"clima":"calido","tipo":"playa","region":"norte","costa":true},
    {"id":"ensenada","nombre":"Ensenada","estado":"Baja California","lat":31.8667,"lng":-116.6000,"popularidad":8.5,"clima":"templado","tipo":"playa","region":"norte","costa":true},
    {"id":"colima","nombre":"Colima","estado":"Colima","lat":19.2433,"lng":-103.7241,"popularidad":8,"clima":"calido","tipo":"ciudad","region":"centro","costa":false},
    {"id":"manzanillo","nombre":"Manzanillo","estado":"Colima","lat":19.1138,"lng":-104.3385,"popularidad":8.5,"clima":"tropical","tipo":"playa","region":"centro","costa":true},
    {"id":"tepic","nombre":"Tepic","estado":"Nayarit","lat":21.5085,"lng":-104.8956,"popularidad":7.5,"clima":"templado","tipo":"ciudad","region":"centro","costa":false},
    {"id":"nuevovallarta","nombre":"Nuevo Vallarta","estado":"Nayarit","lat":20.6829,"lng":-105.2850,"popularidad":9,"clima":"tropical","tipo":"playa","region":"centro","costa":true},

    {"id":"cuernavaca","nombre":"Cuernavaca","estado":"Morelos","lat":18.9242,"lng":-99.2216,"popularidad":8.5,"clima":"calido","tipo":"ciudad","region":"centro","costa":false},
    {"id":"taxco","nombre":"Taxco","estado":"Guerrero","lat":18.5563,"lng":-99.6057,"popularidad":9,"clima":"templado","tipo":"pueblo_magico","region":"sur","costa":false},
    {"id":"tlaxcala","nombre":"Tlaxcala","estado":"Tlaxcala","lat":19.3139,"lng":-98.2404,"popularidad":7.5,"clima":"templado","tipo":"ciudad","region":"centro","costa":false},
    {"id":"pachuca","nombre":"Pachuca","estado":"Hidalgo","lat":20.1011,"lng":-98.7591,"popularidad":8,"clima":"templado","tipo":"ciudad","region":"centro","costa":false},
    {"id":"tula","nombre":"Tula de Allende","estado":"Hidalgo","lat":20.0544,"lng":-99.3429,"popularidad":8,"clima":"templado","tipo":"zona_arqueologica","region":"centro","costa":false},

    {"id":"xalapa","nombre":"Xalapa","estado":"Veracruz","lat":19.5438,"lng":-96.9102,"popularidad":8,"clima":"templado","tipo":"ciudad","region":"centro","costa":false},
    {"id":"coatepec","nombre":"Coatepec","estado":"Veracruz","lat":19.4524,"lng":-96.9613,"popularidad":8,"clima":"templado","tipo":"pueblo_magico","region":"centro","costa":false},
    {"id":"orizaba","nombre":"Orizaba","estado":"Veracruz","lat":18.8506,"lng":-97.1036,"popularidad":8.5,"clima":"templado","tipo":"ciudad","region":"centro","costa":false},

    {"id":"metepec","nombre":"Metepec","estado":"Estado de México","lat":19.2530,"lng":-99.6010,"popularidad":7.5,"clima":"templado","tipo":"ciudad","region":"centro","costa":false},
    {"id":"vallebravo","nombre":"Valle de Bravo","estado":"Estado de México","lat":19.1925,"lng":-100.1327,"popularidad":9,"clima":"templado","tipo":"naturaleza","region":"centro","costa":false},

    {"id":"izamal","nombre":"Izamal","estado":"Yucatán","lat":20.9300,"lng":-89.0200,"popularidad":8.5,"clima":"calido","tipo":"pueblo_magico","region":"sur","costa":false},
    {"id":"valladolid","nombre":"Valladolid","estado":"Yucatán","lat":20.6896,"lng":-88.2017,"popularidad":9,"clima":"calido","tipo":"pueblo_magico","region":"sur","costa":false},

    {"id":"bacalar","nombre":"Bacalar","estado":"Quintana Roo","lat":18.6783,"lng":-88.3891,"popularidad":9.5,"clima":"tropical","tipo":"naturaleza","region":"sur","costa":false},
    {"id":"holbox","nombre":"Isla Holbox","estado":"Quintana Roo","lat":21.5236,"lng":-87.3000,"popularidad":9.5,"clima":"tropical","tipo":"playa","region":"sur","costa":true},

    {"id":"realcatorce","nombre":"Real de Catorce","estado":"San Luis Potosí","lat":23.6900,"lng":-100.8900,"popularidad":9,"clima":"seco","tipo":"pueblo_magico","region":"centro","costa":false},
    {"id":"slp","nombre":"San Luis Potosí","estado":"San Luis Potosí","lat":22.1565,"lng":-100.9855,"popularidad":8.5,"clima":"seco","tipo":"ciudad","region":"centro","costa":false},

    {"id":"tequila","nombre":"Tequila","estado":"Jalisco","lat":20.8823,"lng":-103.8355,"popularidad":9.5,"clima":"templado","tipo":"pueblo_magico","region":"centro","costa":false},
    {"id":"chapala","nombre":"Chapala","estado":"Jalisco","lat":20.2967,"lng":-103.1917,"popularidad":8.5,"clima":"templado","tipo":"naturaleza","region":"centro","costa":false},
    {"id":"ajijic","nombre":"Ajijic","estado":"Jalisco","lat":20.2972,"lng":-103.2542,"popularidad":8.5,"clima":"templado","tipo":"pueblo_magico","region":"centro","costa":false}
  ];

  for (var ciudad in ciudades) {
    final id = ciudad["id"];
    final data = Map<String, dynamic>.from(ciudad)..remove("id");

    await FirebaseFirestore.instance
        .collection('ciudades')
        .doc(id as String)
        .set(data);
  }

  print("✅ Ciudades subidas correctamente");
}