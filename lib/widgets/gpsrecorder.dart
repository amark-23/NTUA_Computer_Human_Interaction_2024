import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shake_gesture/shake_gesture.dart'; // Import shake_gesture package

class LocationRecorderWithMap extends StatefulWidget {
  final String userId;

  const LocationRecorderWithMap({super.key, required this.userId});

  @override
  _LocationRecorderWithMapState createState() =>
      _LocationRecorderWithMapState();
}

class _LocationRecorderWithMapState extends State<LocationRecorderWithMap> {
  bool _isRecording = false;
  bool _isShakeDetected = false; // Flag to track first shake
  LatLng? _startLocation;
  LatLng? _endLocation;
  StreamSubscription<Position>? _positionSubscription;
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    // Cancel subscriptions and dispose controller
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // Fetch current location
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentLocation!),
      );
    }
  }

  // Toggle recording
  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _startRecording();
    } else {
      _stopRecording();
    }
  }

  // Start recording
  Future<void> _startRecording() async {
    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _startLocation = LatLng(position.latitude, position.longitude);
        _endLocation = null; // Clear the previous ending location
        _routePoints = []; // Clear the previous route
      });
    }

    // Start listening to location updates
    _positionSubscription = Geolocator.getPositionStream().listen((position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  // Stop recording
  Future<void> _stopRecording() async {
    if (_currentLocation != null && mounted) {
      setState(() {
        _endLocation = _currentLocation;
        _isRecording = false;
      });
    }

    // Cancel the position subscription
    _positionSubscription?.cancel();
    _positionSubscription = null;

    // Fetch and draw the route only if the widget is still mounted
    if (mounted && _startLocation != null && _endLocation != null) {
      try {
        await _fetchRoute(_startLocation!, _endLocation!);
      } catch (e) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: "Your route is too small to trace!",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      }
    }
  }

  // Upload route to Firestore with user_id
  Future<void> _uploadRouteToFirestore() async {
    if (_startLocation == null ||
        _endLocation == null ||
        _routePoints.isEmpty) {
      Fluttertoast.showToast(
        msg: "No route to upload. Please record a route first!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final userId = widget.userId;

    final routeData = {
      'user_id': userId,
      'start': {
        'latitude': _startLocation!.latitude,
        'longitude': _startLocation!.longitude,
      },
      'end': {
        'latitude': _endLocation!.latitude,
        'longitude': _endLocation!.longitude,
      },
      'route': _routePoints
          .map((point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              })
          .toList(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('routes').add(routeData);

      Fluttertoast.showToast(
        msg: "Route uploaded successfully!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error uploading route: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      print("Error uploading route: $e");
    }
  }

  // Fetch the route from Google Maps Directions API
  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    const apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final points = data['routes'][0]['overview_polyline']['points'];
      if (mounted) {
        setState(() {
          _routePoints = _decodePolyline(points);
        });
      }
    } else {
      print('Failed to fetch directions: ${response.body}');
    }
  }

  // Decode the polyline from the API response
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  // Build markers for starting and ending locations
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_startLocation != null) {
      markers.add(
        Marker(
          markerId: MarkerId("start"),
          position: _startLocation!,
          infoWindow: const InfoWindow(title: "Starting Location"),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    if (_endLocation != null) {
      markers.add(
        Marker(
          markerId: MarkerId("end"),
          position: _endLocation!,
          infoWindow: const InfoWindow(title: "Ending Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_currentLocation != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation!,
                zoom: 14.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              markers: _buildMarkers(),
              polylines: {
                Polyline(
                  polylineId: const PolylineId("route"),
                  points: _routePoints,
                  color: Colors.blue,
                  width: 5,
                ),
              },
              myLocationEnabled: true,
            ),
          if (_currentLocation == null)
            const Center(child: CircularProgressIndicator()),

          // Add a back arrow button at the top-left
          Positioned(
            top: 40, // Adjust for the device's safe area (status bar)
            left: 10,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            right: 20,
            child: ShakeGesture(
              onShake: !_isShakeDetected
                  ? () {
                      setState(() {
                        _isShakeDetected = true;
                        _isRecording = true; // Start recording state
                      });
                      _startRecording(); // Start recording on first shake
                    }
                  : () {
                      if (_isRecording) {
                      } else {
                        setState(() {
                          _isShakeDetected = true;
                          _isRecording = true; // Start recording state
                        });
                        _startRecording();
                      }
                    }, // An empty function after the first shake to prevent further shakes from doing anything
              child: FloatingActionButton(
                onPressed: _toggleRecording,
                backgroundColor: _isRecording ? Colors.red : Colors.green,
                child: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 20,
            child: ElevatedButton(
              onPressed: _uploadRouteToFirestore,
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  iconColor: Colors.blue),
              child: const Text("Upload Route"),
            ),
          ),
        ],
      ),
    );
  }
}
