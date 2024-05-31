import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:land_conquer/models/pixel.dart';
import 'package:land_conquer/service/pixel_service.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart' show rootBundle;

class MapTest extends StatefulWidget {
  final int userId;

  MapTest(this.userId);

  @override
  State<MapTest> createState() => _MapTestState();
}

class _MapTestState extends State<MapTest> {
  final Completer<GoogleMapController> _controller = Completer();
  final Location _location = Location();
  LocationData? currentLocation;
  late StreamSubscription<LocationData> locationSubscription;
  final PixelService pixelService = PixelService();
  Map<int, Color> userColor = {
    1 : Colors.red,
    2 : Colors.blue,
    3 : Colors.green,
    4 : Colors.yellow,
    5 : Colors.deepPurple
  };

  double tenMeterInLat = 1 / 1800;
  double tenMeterInLng = 1 / 1400;

  // 지도 마커 설정
  Marker _marker = Marker(
    position: LatLng(0, 0),
    markerId: MarkerId("currentLocation"),
  );

  Map<String, Polygon> polygons = {};
  Map<String, LatLng> latLngList = {};
  late List<Pixel> pixelList;

  late String currentPolygonId;

  String? _mapStyle;

  bool _isLoading = true;

  late Timer timer;

  @override
  void initState() {
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   print(pixelService.getPixels());
    // });
    print("current userId : ${widget.userId}");
    super.initState();
    rootBundle.loadString("assets/map_style.txt").then((string){
      _mapStyle = string;
    });

    initLocation().then((value) => {
      initPolygons(),
    });
    trackLocation();
    trackPixelOwner();
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
        initialCameraPosition: CameraPosition(
          target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
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

  void _updatePixelsColor() async {
    for (int i = 0; i < 144; i++) {
      Pixel currentPixel = pixelList[i];
      String pixelId = "${pixelList[i].x}_${pixelList[i].y}";

      if (currentPixel.userId != null) {
        setState(() {
          polygons[pixelId] = _createPolygon(pixelId, currentPixel.userId!);
        });
      }
    }
  }


  void initPolygons() async {
    pixelList = await pixelService.getPixels();
    print(pixelList);
    double currentLat = currentLocation!.latitude!;
    double currentLon = currentLocation!.longitude!;

    for (int i = 0; i < 144; i++) {
      Pixel currentPixel = pixelList[i];
      LatLng topLeftPoint = LatLng(currentPixel.lat, currentPixel.lon);
      latLngList["${currentPixel.x}_${currentPixel.y}"] = topLeftPoint;

      if (_isPointInRectangle(LatLng(currentLat, currentLon), _getRectangle(topLeftPoint: topLeftPoint))) {
        currentPolygonId = "${currentPixel.x}_${currentPixel.y}";
        setState(() {
          polygons[currentPolygonId] = _createPolygon(currentPolygonId, widget.userId);
          pixelService.updatePixel(currentPixel.x, currentPixel.y, widget.userId);
        });
      }
    }

    _updatePixelsColor();
  }

  Future<void> initLocation() async {
    currentLocation = await _location.getLocation();
    setState(() {
      _isLoading = false;
    });
  }

  void trackLocation() async {
    locationSubscription = _location.onLocationChanged.listen(
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
      int newX = int.parse(split[0]) + dx[i];
      int newY = int.parse(split[1]) + dy[i];

      List<LatLng> rectangle = _getRectangle(topLeftPoint: latLngList["${newX}_${newY}"]!);
      if(_isPointInRectangle(LatLng(currentLocation!.latitude!, currentLocation!.longitude!), rectangle)) {
        currentPolygonId = "${newX}_${newY}";
        setState(() {
          polygons[currentPolygonId] = _createPolygon(currentPolygonId, widget.userId);
          pixelService.updatePixel(newX, newY, widget.userId);
        });
      }
    }
  }

  Polygon _createPolygon(String polygonId, int userId){
    List<LatLng> rectangle = _getRectangle(topLeftPoint: latLngList[polygonId]!);
    return Polygon(
        polygonId: PolygonId(polygonId),
        points: rectangle,
        fillColor: userColor[userId]!.withOpacity(0.3),
        strokeColor: userColor[userId]!,
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

  @override
  void dispose(){
    _controller.future.then((controller) => controller.dispose());
    locationSubscription.cancel();
    timer.cancel();
    super.dispose();
  }

  void trackPixelOwner() async {
    timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      pixelList = await pixelService.getPixels();
      _updatePixelsColor();
    });
  }
}