import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart' show rootBundle;

class MapTest extends StatefulWidget {
  @override
  State<MapTest> createState() => _MapTestState();
}

class _MapTestState extends State<MapTest> {
  final Completer<GoogleMapController> _controller = Completer();
  LocationData? currentLocation;
  Location location = Location();

  CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37, 127),
    zoom: 14.4746,
  );

  // 지도 마커 설정
  late Marker _marker = Marker(
    position: LatLng(37, 127),
    markerId: MarkerId("currentLocation"),
  );

  Map<String, Polygon> polygonStore = {};
  Map<String, Polygon> polygons = {};

  late String currentPolygonId;

  String? _mapStyle;

  void initPolygons() async {

    currentLocation = await location.getLocation();


    double initLat = currentLocation?.latitude?? 0;
    double initLng = currentLocation?.longitude?? 0 ;

    print("${initLat} adfaf");
    print("${initLng} adfaf");
    double tenMeterInLat = 1 / 1800;
    double tenMeterInLng = 1 / 1400;

    initLat += 6 * tenMeterInLat;
    initLng -= 6 * tenMeterInLng;


    for (var i = 0; i < 12; i++) {
      for (var j = 0; j < 12; j++) {
        List<LatLng> latLngList = [
          LatLng(initLat - i * tenMeterInLat, initLng + j * tenMeterInLng),
          LatLng(initLat - i * tenMeterInLat, initLng + ((j + 1) * tenMeterInLng)),
          LatLng(initLat - ((i + 1) * tenMeterInLat), initLng + ((j + 1) * tenMeterInLng)),
          LatLng(initLat - ((i + 1) * tenMeterInLat), initLng + j * tenMeterInLng),
        ];

        polygonStore["${i}_${j}"] = Polygon(
            polygonId: PolygonId("${i}_${j}"),
            points: latLngList,
            fillColor: Colors.transparent,
            strokeColor: Colors.red,
            strokeWidth: 1
        );// polygonData?.add(latLngList);
      }
    }
    double currentLat = currentLocation?.latitude?? 0;
    double currentLon = currentLocation?.longitude?? 0 ;
    for (var i = 0; i < 12; i++) {
      for (var j = 0; j < 12; j++) {
        if(_isPointInPolygon(LatLng(currentLat, currentLon), polygonStore["${i}_${j}"]!.points)) {
          polygons["${i}_${j}"] = polygonStore["${i}_${j}"]!.clone();
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // initPolygons();
    rootBundle.loadString("assets/map_style.txt").then((string){
      _mapStyle = string;
    });
    print(_mapStyle);
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
        polygons: Set<Polygon>.of(
            polygons.values
        ),
        style: _mapStyle,
      ),
    );
  }

  void getCurrentLocation() async {
    currentLocation = await location.getLocation();

    initPolygons();

    changePolygonColor();
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
        changePolygonColor();
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

  void changePolygonColor() async {
    for (var polygon in polygonStore.values) {
      if(_isPointInPolygon(LatLng(currentLocation!.latitude!, currentLocation!.longitude!), polygon.points)){
        print('로그');
        currentPolygonId = polygon.polygonId.value;

        Polygon tmp = polygon.clone();

        setState(() {
          polygons[tmp.polygonId.value] = Polygon(
              polygonId: PolygonId(tmp.polygonId.value),
              points: tmp.points,
              fillColor: Colors.red.withOpacity(0.3),
              strokeColor: Colors.red,
              strokeWidth: 1
          );
        }); // Add this line to update the UI
      }
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    print('현재 위치');
    print('${point.latitude} ${point.longitude}');

    return point.latitude < polygon[0].latitude &&
        point.latitude > polygon[2].latitude &&
        point.longitude > polygon[0].longitude &&
        point.longitude < polygon[2].longitude;
  }
}