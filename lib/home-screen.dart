import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';



class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  List<LatLng> _polylineCoordinates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _updateLocationPeriodically();
    _listenCurrentLocation();
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.add(Marker(
        markerId: MarkerId("currentLocation"),
        position: _currentPosition!,
        infoWindow: InfoWindow(
          title: "My current location",
          snippet: "${position.latitude}, ${position.longitude}",
        ),
      ));
      _isLoading = false;
    });
    _animateToCurrentLocation();
  }

  void _updateLocationPeriodically() {
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _markers.clear();
        _markers.add(Marker(
          markerId: MarkerId("currentLocation"),
          position: _currentPosition!,
          infoWindow: InfoWindow(
            title: "My current location",
            snippet: "${position.latitude}, ${position.longitude}",
          ),
        ));
        _polylineCoordinates.add(_currentPosition!);
      });
    });
  }

  void _animateToCurrentLocation() {
    mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
  }


  Future<void> _listenCurrentLocation() async {
    if (await _checkPermissionStatus()) {
      if (await _isGpsServiceEnable()) {
        // STREAM OF LOCATION
        Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 2,
              // timeLimit: Duration(seconds: 1),
            )
        ).listen((pos) {
          print(pos);
        });
      } else {
        _requestGpsService();
      }
    } else {
      _requestPermission();
    }
  }






  Future<bool> _checkPermissionStatus() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    }
    return false;
  }

  Future<bool> _requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    }
    return false;
  }

  Future<bool> _isGpsServiceEnable() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<void> _requestGpsService() async {
    await Geolocator.openLocationSettings();
  }







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-Time Location Tracker'),
      ),
      body:
      GoogleMap(
        onMapCreated: (controller) {
          setState(() {
            mapController = controller;
          });
        },
        initialCameraPosition: CameraPosition(
          target: _currentPosition ?? LatLng(0, 0),
          zoom: 14.0,
        ),
        markers: _markers,
        polylines: {
          Polyline(
            polylineId: PolylineId("route"),
            points: _polylineCoordinates,
            color: Colors.blue,
            width: 5,
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.add_location_outlined),
      ),
    );
  }
}