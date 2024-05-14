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
  LatLng? _currentLatLng;

  double tenMeterInLat = 1 / 1800;
  double tenMeterInLng = 1 / 1400;

  late CameraPosition _initialPosition;

  // 지도 마커 설정
  late Marker _marker = Marker(
    position: LatLng(0, 0),
    markerId: MarkerId("currentLocation"),
  );

  Map<String, Polygon> polygonStore = {};
  Map<String, Polygon> polygons = {};
  Map<String, LatLng> latLngList = {};

  late String currentPolygonId;

  String? _mapStyle;

  bool _isLoading = true;

  void initPolygons() async {
    double currentLat = _currentLatLng!.latitude;
    double currentLon = _currentLatLng!.longitude;

    print("위도 ${currentLat}");
    print("경도 ${currentLon}");
    double initLat = currentLat;
    double initLng = currentLon;

    initLat += 6.5 * tenMeterInLat;
    initLng -= 6.5 * tenMeterInLng;

    for (var i = 0; i < 12; i++) {
      for (var j = 0; j < 12; j++) {
        LatLng topLeftPoint = LatLng(initLat - i * tenMeterInLat, initLng + j * tenMeterInLng);

        latLngList["${i}_${j}"] = topLeftPoint;
        if (_isPointInPolygon(LatLng(currentLat, currentLon), getRectangle(topLeftPoint: topLeftPoint))) {
          currentPolygonId = "${i}_${j}";
        }
      }
    }
  }

  void drawPolygon() {
    double latitude = latLngList[currentPolygonId]!.latitude;
    double longitude = latLngList[currentPolygonId]!.longitude;

    polygons[currentPolygonId] = Polygon(
      polygonId: PolygonId(currentPolygonId),
      points: getRectangle(topLeftPoint: LatLng(latitude, longitude)),
      fillColor: Colors.red.withOpacity(0.3),
      strokeColor: Colors.red,
      strokeWidth: 1
    );
  }

  @override
  void initState() {
    super.initState();
    rootBundle.loadString("assets/map_style.txt").then((string){
      _mapStyle = string;
    });
    // print(_mapStyle);
    initLocation().then((value) => {
      initPolygons(),
    });
    trackLocation();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("구글 맵"),
      ),
      body: _isLoading?
      Center(child:
        CircularProgressIndicator()
      )  :
      GoogleMap(
        mapType: MapType.normal,
        // initialCameraPosition: _initialPosition,
        initialCameraPosition: CameraPosition(
          target: _currentLatLng!,
          zoom: 16.0,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: {_marker},
        polygons: Set<Polygon>.of(
            polygons.values
        ),
        style: _mapStyle,
      ),
    );
  }

  Future<void> initLocation() async {
    print("위치 초기화");
    currentLocation = await location.getLocation();
    print("위치 초기화 완료");
    setState(() {
      _currentLatLng = LatLng(currentLocation!.latitude!, currentLocation!.longitude!);
      print(_currentLatLng);
      _isLoading = false;
    });
  }

  void trackLocation() async {
    location.onLocationChanged.listen(
          (newLoc) {
        currentLocation = newLoc;
        _updateMarker(newLoc);
        // changePolygonColor();
      },
    );
  }

  void _updateMarker(LocationData locationData) async {
    final GoogleMapController controller = await _controller.future;

    setState(() {
      print("현재 폴리곤아이디 ${currentPolygonId}");
      print("${latLngList[currentPolygonId]!}");

      polygons[currentPolygonId] = Polygon(
          polygonId: PolygonId(currentPolygonId),
          points: getRectangle(
              topLeftPoint: LatLng(
                  latLngList[currentPolygonId]!.latitude,
                  latLngList[currentPolygonId]!.longitude
              )
          ),
          fillColor: Colors.red.withOpacity(0.3),
          strokeColor: Colors.red,
          strokeWidth: 1
      );

      print("초기 폴리곤 ${polygons[currentPolygonId]}");
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
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    return point.latitude <= polygon[0].latitude &&
        point.latitude >= polygon[2].latitude &&
        point.longitude >= polygon[0].longitude &&
        point.longitude <= polygon[2].longitude;
  }

  List<LatLng> getRectangle({required LatLng topLeftPoint}) {
    return List<LatLng>.of({
      LatLng(topLeftPoint.latitude, topLeftPoint.longitude),
      LatLng(topLeftPoint.latitude, topLeftPoint.longitude + tenMeterInLng),
      LatLng(topLeftPoint.latitude - tenMeterInLat, topLeftPoint.longitude + tenMeterInLng),
      LatLng(topLeftPoint.latitude - tenMeterInLat, topLeftPoint.longitude),
    });
  }

}