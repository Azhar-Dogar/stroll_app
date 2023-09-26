import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo_locator;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:screenshot/screenshot.dart';
import 'package:smartx_flutter_app/common/margin_widget.dart';
import 'package:smartx_flutter_app/extension/context_extension.dart';
import 'package:smartx_flutter_app/ui/map-walk/map_walk_controller.dart';
import 'package:smartx_flutter_app/ui/map-walk/stop_walk_screen.dart';
import 'package:smartx_flutter_app/util/constants.dart';

import '../main/main_screen_controller.dart';

class MapWalkScreen extends StatefulWidget {
  static const String route = '/map_walk_screen_route';
  static const String key_title = '/map_walk_screen_title';
  const MapWalkScreen({super.key});

  @override
  State<MapWalkScreen> createState() => _MapWalkScreenState();
}

class _MapWalkScreenState extends State<MapWalkScreen> {
  final controller = Get.put(MapWalkController());
  GoogleMapController? _controller;
  LocationData? _myLocation;
  late double width, height;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final permission_handler.PermissionStatus status =
        await permission_handler.Permission.location.request();
    if (status.isGranted) {
      print("granted");
      _getLocation();
      // Permission granted, proceed to get location
    } else {
      print("not granted");
      // Permission denied, handle accordingly
    }
  }

  Future<void> _getLocation() async {
    try {
      geo_locator.Position position =
          await geo_locator.Geolocator.getCurrentPosition(
        desiredAccuracy: geo_locator.LocationAccuracy.high,
      );
      double latitude = position.latitude;
      double longitude = position.longitude;
    } catch (e) {
      // Handle location fetching errors
    }
  }

  Future<void> _setMyLocation() async {
    final Location location = Location();
    location.onLocationChanged.listen((LocationData newLocation) {
        _myLocation = newLocation;
        controller.pathPoints
            .add(LatLng(newLocation.latitude!, newLocation.longitude!));
      if (controller.isStart.value) {
        Future.delayed(const Duration(seconds: 5)).then((value) {
          setState(() {
            _myLocation = newLocation;
            controller.pathPoints
                .add(LatLng(newLocation.latitude!, newLocation.longitude!));
            print("paths ${controller.pathPoints.length}");
          });
        });
      }
      if (_controller != null) {
        _controller!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(newLocation.latitude!, newLocation.longitude!),
          ),
        );
      }
    });
  }
  ScreenshotController screenshotController = ScreenshotController();
  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Constants.colorSecondary,
        // titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: InkWell(
          onTap: () => Get.back(),
          child: const Row(
            children: [
              Icon(
                Icons.arrow_back,
                color: Constants.colorOnBackground,
              ),
              Text(
                'Back',
                style: TextStyle(
                    fontFamily: Constants.workSansRegular,
                    color: Constants.colorOnBackground,
                    fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      body: SizedBox(
        height: height,
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GetX<MapWalkController>(
              builder: (_) {
                return Expanded(
                  child: Column(children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Screenshot(
                              controller: screenshotController,
                              child: googleMap()),
                          if (controller.isStart.value) ...[
                            stopButton()
                          ] else ...[
                            startButton()
                          ]
                        ],
                      ),
                    )
                  ]),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget stopButton() {
    DateTime date = DateTime.now();
    return Positioned(
      bottom: 10,
      left: width * 0.25,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          timer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text(controller.totalDistance.toStringAsFixed(3)),
              Container(
                  alignment: Alignment.center,
                  height: 40,
                  width: 40,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Constants.colorOnSurface),
                  child: const Icon(Icons.pause)),
              const MarginWidget(
                factor: 1,
                isHorizontal: true,
              ),
              GestureDetector(
                onTap: () async {
                  late File imagePath;
                  try{
                    var e = await _controller!.takeSnapshot().
                  then((Uint8List? image) async {
                    print("here we know");
                    if (image != null) {
                       final directory = await getTemporaryDirectory();
                       imagePath = await File('${directory.path}/image.png').create();
                      var e = await imagePath.writeAsBytes(image);
                       }
                  });}
                  catch(e){
                    print("error ");
                    print(e);
                  };
                  controller.calDistance();
                  Get.toNamed(StopWalkScreen.route,arguments: MapEntry(false,imagePath.path));
                  controller.pathPoints = [];
                  controller.timer!.cancel();
                  controller.isStart(false);
                  },
                child: Container(
                  alignment: Alignment.center,
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Constants.colorOnSurface.withOpacity(0.4)),
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Constants.colorSecondary),
                    child: const Text('Stop',
                        style: TextStyle(color: Constants.colorOnBackground)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget timer() {
    DateTime time = controller.time;
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      width: width * 0.25,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Constants.colorTextWhite),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
                "${controller.hours}:${controller.minutes}:${controller.seconds}")
          ],
        ),
      ),
    );
  }

  Widget startButton() {
    return Positioned(
      bottom: 10,
      right: width * 0.39,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Text(controller.totalDistance.toStringAsFixed(3)),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {
                controller.isStart(true);
                controller.pathPoints = [];
                controller.startTimer();
              },
              child: Container(
                alignment: Alignment.center,
                height: 80,
                width: 80,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Constants.colorSecondary),
                child: const Text('Start',
                    style: TextStyle(color: Constants.colorOnBackground)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget googleMap() {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
          zoom: 16, target: LatLng(31.5223654, 74.4390812)),
      onMapCreated: (GoogleMapController controller) {
        print('changes');
        _controller = controller;
        _setMyLocation();
      },
      myLocationEnabled: true,
      polylines: {
        Polyline(
          polylineId: const PolylineId('path'),
          color: Colors.blue,
          points: controller.pathPoints,
        ),
      },
    );
  }
}
