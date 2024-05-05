import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapTest extends StatefulWidget {
  @override
  State<MapTest> createState() => _MapTestState();
}

class _MapTestState extends State<MapTest> {
  final Completer<GoogleMapController> _controller = Completer();
  LocationData? currentLocation;
  Location location = Location();

  CameraPosition _initialPosition = CameraPosition(
    target: LatLng(0, 0),
    zoom: 14.4746,
  );

  // 지도 마커 설정
  late Marker _marker;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("구글 맵"),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initialPosition,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: Set.of([_marker]),
      ),
    );
  }

  void getCurrentLocation() async {
    currentLocation = await location.getLocation();
    _initialPosition = CameraPosition(
      target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
      zoom: 14.4746,
    );

    _marker = Marker(
      markerId: MarkerId("currentLocation"),
      position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
    );

    if (mounted) {
      setState(() {});
    }

    location.onLocationChanged.listen((newLoc) {
      currentLocation = newLoc;
      _updateMarker(newLoc);
      },
    );

  }

  void _updateMarker(LocationData locationData) async {
    final GoogleMapController controller = await _controller.future;

    setState(() {
      _marker = Marker(
        markerId: MarkerId("currentLocation"),
        position: LatLng(locationData.latitude!, locationData.longitude!),
      );

      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(locationData.latitude!, locationData.longitude!),
          zoom: 14
        ),
      ));
    });
  }

  // Location initCurrentLocation() {
  //   Location location = Location();
  //   location.getLocation().then(
  //         (location) {
  //       currentLocation = location;
  //     },
  //   );
  //   return location;
  // }
}

