import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;

  final List<LatLng> _markerPoints = [
    LatLng(13.0827, 80.2707),
    LatLng(13.0604, 80.2496),
    LatLng(13.0878, 80.2785),
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation ?? LatLng(13.0827, 80.2707),
          initialZoom: 13.5,
        ),
        children: [
          TileLayer(
            urlTemplate:
            'https://tile.jawg.io/jawg-streets/{z}/{x}/{y}{r}.png?access-token=GsQVPAN5Bpmv3rwGFWpEKDjMp0OBtfSrxGFGtrZ5guA4DvlML0X2y0hTtOy12mYR',
            userAgentPackageName: 'com.example.app',
            retinaMode: RetinaMode.isHighDensity(context),
            minZoom: 0,
            maxZoom: 22,
          ),
          MarkerLayer(
            markers: [
              ..._markerPoints.map(
                    (point) => Marker(
                  width: 36,
                  height: 36,
                  point: point,
                  child: const Icon(Icons.location_on,
                      color: Colors.black, size: 32),
                ),
              ),
              if (_currentLocation != null)
                Marker(
                  width: 40,
                  height: 40,
                  point: _currentLocation!,
                  child: const Icon(Icons.location_on,
                      color: Colors.black, size: 32),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "sos_btn",
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            child: const Icon(Icons.sos, size: 32),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "track_btn",
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            onPressed: () {
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, 15.0);
              } else {
              }
            },
            child: const Icon(Icons.my_location, size: 28),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "exit_btn",
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.exit_to_app, size: 28),
          ),
        ],
      ),
    );
  }
}
