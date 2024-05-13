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
    double currentLat = currentLocation?.latitude?? 0;
    double currentLon = currentLocation?.longitude?? 0 ;

    double initLat = currentLat;
    double initLng = currentLon;

    // print("${initLat} adfaf");
    // print("${initLng} adfaf");
    double tenMeterInLat = 1 / 1800;
    double tenMeterInLng = 1 / 1400;

    initLat += 6 * tenMeterInLat;
    initLng -= 6 * tenMeterInLng;


    for (var i = 0; i < 12; i++) {
      for (var j = 0; j < 12; j++) {
        print("폴리곤 삽입");
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

    for (var i = 0; i < 12; i++) {
      for (var j = 0; j < 12; j++) {
        if(_isPointInPolygon(LatLng(currentLat, currentLon), polygonStore["${i}_${j}"]!.points)) {
          polygons["${i}_${j}"] = polygonStore["${i}_${j}"]!.clone();
          currentPolygonId = "${i}_${j}";
          print("현재 폴리곤 아이디");
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
    List<int> dx = [1, 1, 0, -1, -1, -1, 0, 1];
    List<int> dy = [0, 1, 1, 1, 0, -1, -1, -1];
    print("폴리곤 컬러 변경");

    for(var i = 0; i < 8; i++)  {
      List<String> split = currentPolygonId.split("_");
      int currentX = int.parse(split[0]);
      int currentY = int.parse(split[1]);
      int newX = currentX + dx[i];
      int newY = currentY + dy[i];
      if(_isPointInPolygon(LatLng(currentLocation!.latitude!, currentLocation!.longitude!), polygonStore["${newX}_${newY}"]!.points)) {
        Polygon tmp = polygonStore["${newX}_${newY}"]!.clone();
        currentPolygonId = "${newX}_${newY}";
        print(currentPolygonId);
        setState(() {
          polygons[tmp.polygonId.value] = Polygon(
              polygonId: PolygonId(tmp.polygonId.value),
              points: tmp.points,
              fillColor: Colors.red.withOpacity(0.3),
              strokeColor: Colors.red,
              strokeWidth: 1
          );
        });
      }
    }
    // for (var polygon in polygonStore.values) {
    //   if(_isPointInPolygon(LatLng(currentLocation!.latitude!, currentLocation!.longitude!), polygon.points)){
    //     print('로그');
    //     currentPolygonId = polygon.polygonId.value;
    //
    //     Polygon tmp = polygon.clone();
    //
    //     setState(() {
    //       polygons[tmp.polygonId.value] = Polygon(
    //           polygonId: PolygonId(tmp.polygonId.value),
    //           points: tmp.points,
    //           fillColor: Colors.red.withOpacity(0.3),
    //           strokeColor: Colors.red,
    //           strokeWidth: 1
    //       );
    //     }); // Add this line to update the UI
    //   }
    // }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    print('현재 위치');
    print('${point.latitude} ${point.longitude}');

    return point.latitude <= polygon[0].latitude &&
        point.latitude >= polygon[2].latitude &&
        point.longitude >= polygon[0].longitude &&
        point.longitude <= polygon[2].longitude;
  }
}