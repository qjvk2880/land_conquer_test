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

  Map<String, Polygon> polygons = {};

  void initPolygons() {
    double initLat = 37.508600;
    double initLng = 127.041452;

    double tenMeterInLat = 1 / 3600;
    double tenMeterInLng = 1 / 3600;

    for (var i = 0; i < 25; i++) {
      for (var j = 0; j < 25; j++) {
        List<LatLng> latLngList = [];

        latLngList.add(LatLng(initLat + i * tenMeterInLat, initLng + j * tenMeterInLng));
        latLngList.add(LatLng(initLat + i * tenMeterInLat, initLng + ((j + 1) * tenMeterInLng)));
        latLngList.add(LatLng(initLat - ((i + 1) * tenMeterInLat), initLng + ((j + 1) * tenMeterInLng)));
        latLngList.add(LatLng(initLat - ((i + 1) * tenMeterInLat), initLng + j * tenMeterInLng));

        polygons["${i}_${j}"] = Polygon(
            polygonId: PolygonId("${i}_${j}"),
            points: latLngList,
            fillColor: Colors.transparent,
            strokeColor: Colors.red,
            strokeWidth: 1,
        );

        // polygonData?.add(latLngList);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    initPolygons();
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
        polygons: Set<Polygon>.of(
          polygons.values
          //
          // // for 문을 사용해 여러 개의 폴리곤 생성
          // [
          //   for (var i = 0; i < polygonData!.length; i++)
          //     Polygon(
          //       polygonId: PolygonId('polygon$i'),
          //       points: polygonData![i],
          //       fillColor: Colors.transparent,
          //       strokeColor: Colors.red,
          //       strokeWidth: 1,
          //     )
          // ],
        ),
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

    location.onLocationChanged.listen(
      (newLoc) {
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

      controller.animateCamera(CameraUpdate.newLatLng(
        LatLng(locationData.latitude!, locationData.longitude!),
      ));
    });
  }

}
