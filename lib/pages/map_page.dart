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
  LatLng? _currentLocation;

  final List<LatLng> _markerPoints = [
    LatLng(13.0827, 80.2707),
    LatLng(13.0604, 80.2496),
    LatLng(13.0878, 80.2785),
  ];

  bool isPublic = false;
  double moveValue = 0;

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

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      print("not enabled");
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentLocation ?? LatLng(13.0827, 80.2707),
              initialZoom: 13.5,
              interactionOptions: const InteractionOptions(),
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
                      child:
                      Icon(Icons.location_on, color: Colors.black, size: 32),
                    ),
                  ),
                  if (_currentLocation != null)
                    Marker(
                      width: 40,
                      height: 40,
                      point: _currentLocation!,
                      child:
                      Icon(Icons.my_location, color: Colors.blue, size: 36),
                    ),
                ],
              ),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.18,
            minChildSize: 0.18,
            maxChildSize: 0.35,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Public',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        Switch(
                          value: isPublic,
                          activeColor: Colors.white,
                          activeTrackColor: Colors.black,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.black,
                          onChanged: (val) {
                            setState(() {
                              isPublic = val;
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Move ±30m',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        SizedBox(
                          width: 180,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.black,
                              inactiveTrackColor: Colors.black12,
                              thumbColor: Colors.white,
                              overlayColor: Colors.black12,
                              valueIndicatorColor: Colors.black,
                              valueIndicatorTextStyle:
                              const TextStyle(color: Colors.white),
                            ),
                            child: Slider(
                              min: -30,
                              max: 30,
                              value: moveValue,
                              label: '${moveValue.round()}m',
                              onChanged: (val) {
                                setState(() {
                                  moveValue = val;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.10,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                onPressed: () {},
                child: const Icon(Icons.sos, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
