import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../home/widgets/sos_button.dart';

class FullMapScreen extends StatefulWidget {
  const FullMapScreen({super.key});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  static const LatLng _center = LatLng(-26.1076, 28.0567); // Sandton, Joburg area
  
  final Set<Marker> _markers = {
    const Marker(markerId: MarkerId('1'), position: LatLng(-26.105, 28.054), infoWindow: InfoWindow(title: 'Sector Alpha')),
    const Marker(markerId: MarkerId('2'), position: LatLng(-26.110, 28.060), infoWindow: InfoWindow(title: 'Active Patrol')),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _center, zoom: 15),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            style: _mapStyle,
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => context.pop()),
                  ),
                  const Spacer(),
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.layers_outlined, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
          
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActiveResponderCard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
          
          Center(
            child: SosButton(onTriggered: () => context.push('/emergency')),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveResponderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 24, backgroundColor: Color(0xFF3F51B5), child: Text('BM', style: TextStyle(color: Colors.white))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('brendan mbele', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('City of Johannesburg Metropolitan...', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text('Since 7:03 PM', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Image.asset('assets/images/blurry.png', height: 100, width: double.infinity, fit: BoxFit.cover),
        ],
      ),
    );
  }

  final String _mapStyle = '''[
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road",
    "elementType": "labels",
    "stylers": [{"visibility": "on"}]
  }
]''';
}
