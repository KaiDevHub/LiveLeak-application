import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class MapViewPage extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MapViewPage({
    required this.latitude,
    required this.longitude,
  });

  @override
  _MapViewPageState createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  late GoogleMapController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: Text(
    'Location', 
    style: GoogleFonts.lobster(
      textStyle: TextStyle(
        color: Color.fromARGB(255, 253, 254, 254),
        fontSize: 26.0,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  backgroundColor: Color.fromARGB(255, 30, 144, 125),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.latitude, widget.longitude),
          zoom: 15.0,
        ),
        markers: {
          Marker(
            markerId: MarkerId('newsLocation'),
            position: LatLng(widget.latitude, widget.longitude),
          ),
        },
      ),
    );
  }
}
