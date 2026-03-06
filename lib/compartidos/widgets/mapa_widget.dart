import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapaWidget extends StatefulWidget {
  final double lat;
  final double lng;

  const MapaWidget({
    super.key,
    required this.lat,
    required this.lng,
  });

  @override
  State<MapaWidget> createState() => _MapaWidgetState();
}

class _MapaWidgetState extends State<MapaWidget> {

  MapboxMap? mapboxMap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: MapWidget(
        onMapCreated: (map) {
          mapboxMap = map;
          _configurarMapa();
        },
      ),
    );
  }

  void _configurarMapa() async {

  await mapboxMap?.setCamera(
    CameraOptions(
      center: Point(
        coordinates: Position(widget.lng, widget.lat),
      ),
      zoom: 14,
    ),
  );

  final annotationManager =
      await mapboxMap!.annotations.createPointAnnotationManager();

  // Crear marcador
  await annotationManager.create(
    PointAnnotationOptions(
      geometry: Point(
        coordinates: Position(widget.lng, widget.lat),
      ),
    ),
  );
}
}