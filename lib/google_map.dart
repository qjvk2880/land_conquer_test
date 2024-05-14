import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart' show rootBundle;

class MapTest extends StatefulWidget {
  @override
  State<MapTest> createState() => _MapTestState();
}

class _MapTestState extends State<MapTest> {
  final Completer<GoogleMapController> _controller = Completer();
  final Location _location = Location();
  LocationData? currentLocation;
  LatLng? _currentLatLng;

  double tenMeterInLat = 1 / 1800;
  double tenMeterInLng = 1 / 1400;

  // 지도 마커 설정
  late Marker _marker = Marker(
    position: LatLng(0, 0),
    markerId: MarkerId("currentLocation"),
  );

  Map<String, Polygon> polygons = {};
  Map<String, LatLng> latLngList = {};

  late String currentPolygonId;

  String? _mapStyle;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString("assets/map_style.txt").then((string){
      _mapStyle = string;
    });

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

  void initPolygons() async {
    double currentLat = _currentLatLng!.latitude;
    double currentLon = _currentLatLng!.longitude;

    double initLat = currentLat + 6.5 * tenMeterInLat;
    double initLng = currentLon - 6.5 * tenMeterInLng;

    for (var i = 0; i < 12; i++) {
      for (var j = 0; j < 12; j++) {
        LatLng topLeftPoint = LatLng(initLat - i * tenMeterInLat, initLng + j * tenMeterInLng);
        latLngList["${i}_${j}"] = topLeftPoint;

        if (_isPointInRectangle(LatLng(currentLat, currentLon), _getRectangle(topLeftPoint: topLeftPoint))) {
          currentPolygonId = "${i}_${j}";
          setState(() {
            polygons[currentPolygonId] = _createPolygon(currentPolygonId);
          });
        }
      }
    }
  }

  Future<void> initLocation() async {
    currentLocation = await _location.getLocation();
    setState(() {
      _currentLatLng = LatLng(currentLocation!.latitude!, currentLocation!.longitude!);
      _isLoading = false;
    });
  }

  void trackLocation() async {
    _location.onLocationChanged.listen(
          (newLoc) {
        currentLocation = newLoc;
        _updateMarker(newLoc);
        _searchNearByPixels();
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

  void _searchNearByPixels() async {
    List<int> dx = [1, 1, 0, -1, -1, -1, 0, 1];
    List<int> dy = [0, 1, 1, 1, 0, -1, -1, -1];

    for(var i = 0; i < 8; i++)  {
      List<String> split = currentPolygonId.split("_");
      String searchingPolygonId = "${int.parse(split[0]) + dx[i]}_${int.parse(split[1]) + dy[i]}";

      List<LatLng> rectangle = _getRectangle(topLeftPoint: latLngList[searchingPolygonId]!);
      if(_isPointInRectangle(LatLng(currentLocation!.latitude!, currentLocation!.longitude!), rectangle)) {
        currentPolygonId = searchingPolygonId;
        setState(() {
          polygons[currentPolygonId] = _createPolygon(currentPolygonId);
        });
      }
    }
  }

  Polygon _createPolygon(String polygonId){
    List<LatLng> rectangle = _getRectangle(topLeftPoint: latLngList[polygonId]!);
    return Polygon(
        polygonId: PolygonId(polygonId),
        points: rectangle,
        fillColor: Colors.red.withOpacity(0.3),
        strokeColor: Colors.red,
        strokeWidth: 1
    );
  }

  bool _isPointInRectangle(LatLng point, List<LatLng> polygon) {
    return point.latitude <= polygon[0].latitude &&
        point.latitude >= polygon[2].latitude &&
        point.longitude >= polygon[0].longitude &&
        point.longitude <= polygon[2].longitude;
  }

  List<LatLng> _getRectangle({required LatLng topLeftPoint}) {
    return List<LatLng>.of({
      LatLng(topLeftPoint.latitude, topLeftPoint.longitude),
      LatLng(topLeftPoint.latitude, topLeftPoint.longitude + tenMeterInLng),
      LatLng(topLeftPoint.latitude - tenMeterInLat, topLeftPoint.longitude + tenMeterInLng),
      LatLng(topLeftPoint.latitude - tenMeterInLat, topLeftPoint.longitude),
    });
  }

}