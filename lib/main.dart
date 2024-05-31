import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:land_conquer/google_map.dart';
import 'package:location/location.dart' as l;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(title: 'Flutter Demo Home Page'),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool gpsEnabled = false;
  bool permissionGranted = false;
  l.Location location = l.Location();
  late StreamSubscription subscription;

  Map<int, MaterialColor> userColor = {
    1 : Colors.red,
    2 : Colors.blue,
    3 : Colors.green,
    4 : Colors.yellow,
    5 : Colors.deepPurple
  };

  int currentUserId = 1;

  @override
  void initState() {
    super.initState();
    checkStatus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location App'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            buildListTile(
              "GPS",
              gpsEnabled
                  ? const Text("Okey")
                  : ElevatedButton(
                      onPressed: () {
                        requestEnableGps();
                      },
                      child: const Text("Enable Gps")),
            ),
            buildListTile(
              "Permission",
              permissionGranted
                  ? const Text("Okey")
                  : ElevatedButton(
                      onPressed: () {
                        requestLocationPermission();
                      },
                      child: const Text("Request Permission")),
            ),
            buildListTile(
              "Location",
              ElevatedButton(
                child: const Text("위치 트래킹 시작"),
                onPressed: gpsEnabled && permissionGranted ? () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => MapTest(currentUserId)));
                } : null,
              )
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: userColor.length,
              itemBuilder: (context, index) {
                int userId = userColor.keys.elementAt(index);
                MaterialColor color = userColor[userId]!;
                return Padding(
                  padding: const EdgeInsets.only(left: 130.0, right: 130.0, top: 8.0, bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentUserId = userId;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      // fixedSize: Size(70.0, 20.0)
                      // onPrimary: Colors.white,
                    ),
                    child: Text('User ID: $userId',
                      style: TextStyle(
                          color: Colors.white
                      ),
                    ),
                  ),
                );},
            ),
            Text("Seleted User : ${currentUserId}",
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: userColor[currentUserId],
              ),
            )
          ],
        ),
      ),
    );
  }

  ListTile buildListTile(
    String title,
    Widget? trailing,
  ) {
    return ListTile(
      dense: true,
      title: Text(title),
      trailing: trailing,
    );
  }

  void checkStatus() async {
    bool _permissionGranted = await isPermissionGranted();
    bool _gpsEnabled = await isGpsEnabled();
    setState(() {
      permissionGranted = _permissionGranted;
      gpsEnabled = _gpsEnabled;
    });
  }

  Future<bool> isPermissionGranted() async {
    return await Permission.locationWhenInUse.isGranted;
  }

  Future<bool> isGpsEnabled() async {
    return await Permission.location.serviceStatus.isEnabled;
  }

  void requestEnableGps() async {
    if (gpsEnabled) {
      log("Already open");
    } else {
      bool isGpsActive = await location.requestService();
      if (!isGpsActive) {
        setState(() {
          gpsEnabled = false;
        });
        log("User did not turn on GPS");
      } else {
        log("gave permission to the user and opened it");
        setState(() {
          gpsEnabled = true;
        });
      }
    }
  }

  void requestLocationPermission() async {
    PermissionStatus permissionStatus =
        await Permission.locationWhenInUse.request();
    if (permissionStatus == PermissionStatus.granted) {
      setState(() {
        permissionGranted = true;
      });
    } else {
      setState(() {
        permissionGranted = false;
      });
    }
  }
}
