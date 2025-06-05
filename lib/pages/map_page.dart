import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'realtime_db.dart';

class MapPage extends StatefulWidget {
  final String teamId;
  const MapPage({super.key, required this.teamId});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final RealtimeDBService _realtimeDB = RealtimeDBService();
  late Stream<Map<String, dynamic>> _teamLocationsStream;
  LatLng? _currentLocation;
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _teamLocationsStream = _realtimeDB.teamLocationsStream(widget.teamId);
    _setupLocationUpdates();
    _getUserLocation();
  }

  void _setupLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _realtimeDB.updateUserLocation(
        teamId: widget.teamId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() => _currentLocation = LatLng(position.latitude, position.longitude));
    });
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => _currentLocation = LatLng(position.latitude, position.longitude));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _teamLocationsStream,
        builder: (context, snapshot) {
          _markers.clear();

          if (snapshot.hasData) {
            snapshot.data!.forEach((userId, location) {
              _markers.add(
                Marker(
                  width: 36,
                  height: 36,
                  point: LatLng(
                    (location['latitude'] as num).toDouble(),
                    (location['longitude'] as num).toDouble(),
                  ),
                  child: const Icon(Icons.location_on, color: Colors.black, size: 32),
                ),
              );
            });
          }

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? const LatLng(13.0827, 80.2707),
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.jawg.io/jawg-streets/{z}/{x}/{y}.png?access-token=GsQVPAN5Bpmv3rwGFWpEKDjMp0OBtfSrxGFGtrZ5guA4DvlML0X2y0hTtOy12mYR',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  ..._markers,
                  if (_currentLocation != null)
                    Marker(
                      width: 40,
                      height: 40,
                      point: _currentLocation!,
                      child: const Icon(Icons.my_location, color: Colors.red, size: 36),
                    ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "exit_btn",
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            onPressed: () => Navigator.pop(context),
            child: const Icon(Icons.exit_to_app, size: 28),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "track_btn",
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            onPressed: () {
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, 15);
              }
            },
            child: const Icon(Icons.my_location, size: 28),
          ),
        ],
      ),
    );
  }
}
