import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:random_avatar/random_avatar.dart';
import 'realtime_db.dart';
import 'team_page.dart';

class MapPage extends StatefulWidget {
  final String teamId;
  const MapPage({super.key, required this.teamId});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final RealtimeDBService _realtimeDB = RealtimeDBService();
  late Stream<List<UserLocationData>> _teamLocationsStream;
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
      if (!mounted) return;
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
    if (!mounted) return;
    setState(() => _currentLocation = LatLng(position.latitude, position.longitude));
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    var latitudes = points.map((p) => p.latitude).toList();
    var longitudes = points.map((p) => p.longitude).toList();
    return LatLngBounds(
      LatLng(latitudes.reduce(min), longitudes.reduce(min)),
      LatLng(latitudes.reduce(max), longitudes.reduce(max)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<UserLocationData>>(
        stream: _teamLocationsStream,
        builder: (context, snapshot) {
          _markers.clear();
          List<LatLng> allPoints = [];

          if (snapshot.hasData) {
            for (var user in snapshot.data!) {
              _markers.add(
                Marker(
                  width: 60,
                  height: 80,
                  point: LatLng(user.latitude, user.longitude),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(user.username),
                              content: SizedBox(
                                height: 100,
                                width: 100,
                                child: RandomAvatar(user.avatarSeed, width: 100, height: 100),
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.transparent,
                          child: ClipOval(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: RandomAvatar(user.avatarSeed, width: 40, height: 40),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.username,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              allPoints.add(LatLng(user.latitude, user.longitude));
            }
          }

          if (_currentLocation != null) {
            allPoints.add(_currentLocation!);
          }

          if (allPoints.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final bounds = _calculateBounds(allPoints);
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(40),
                  maxZoom: 15,
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
                urlTemplate:
                'https://tile.jawg.io/jawg-streets/{z}/{x}/{y}.png?access-token=GsQVPAN5Bpmv3rwGFWpEKDjMp0OBtfSrxGFGtrZ5guA4DvlML0X2y0hTtOy12mYR',
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
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const TeamPage()),
                    (route) => false,
              );
            },
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
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "zoom_btn",
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            onPressed: () {
              final allPoints = [
                ..._markers.map((m) => m.point),
                if (_currentLocation != null) _currentLocation!,
              ];
              if (allPoints.isNotEmpty) {
                final bounds = _calculateBounds(allPoints);
                _mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(40),
                    maxZoom: 15,
                  ),
                );
              }
            },
            child: const Icon(Icons.zoom_out_map, size: 28),
          ),
        ],
      ),
    );
  }
}
