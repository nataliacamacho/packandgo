import 'package:cloud_firestore/cloud_firestore.dart';

class Viaje {
  final String id;
  final String origen;
  final String destino;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String descripcion;
  final double destinoLat;
  final double destinoLng;

  Viaje({
    required this.id,
    required this.origen,
    required this.destino,
    required this.fechaInicio,
    required this.fechaFin,
    required this.descripcion,
    required this.destinoLat,
    required this.destinoLng,
  });

  factory Viaje.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Viaje(
      id: doc.id,
      origen: _string(data, "origen"),
      destino: _string(data, "destino"),
      descripcion: _string(data, "descripcion"),
      fechaInicio: _date(data, "fechaInicio"),
      fechaFin: _date(data, "fechaFin"),
      destinoLat: _double(data, "lat"),
      destinoLng: _double(data, "lng"),
    );
  }

  static Null get length => null;

  static String _string(Map d, String k) =>
      d[k]?.toString() ?? "Sin $k";

  static double _double(Map d, String k) {
    final v = d[k];
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v?.toString() ?? "") ?? 0.0;
  }

  static DateTime _date(Map d, String k) {
    final v = d[k];
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      "origen": origen,
      "destino": destino,
      "descripcion": descripcion,
      "fechaInicio": fechaInicio,
      "fechaFin": fechaFin,
      "lat": destinoLat,
      "lng": destinoLng,
    };
  }
}