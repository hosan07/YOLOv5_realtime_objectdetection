import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:objectdetection/screen/home/widget/map/model/entry.dart';
import 'package:objectdetection/screen/home/home_screen.dart';
import 'package:objectdetection/screen/home/widget/map/db/db.dart';

import '../../diary/diary_screen.dart';

class MapPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Set<Polyline> polyline = {};
  Location _location = Location();
  GoogleMapController _mapController;
  LatLng _center = const LatLng(0, 0);
  List<LatLng> route = [];

  double _dist = 0;
  String _displayTime;
  int _time;
  int _lastTime;
  double _speed = 0;
  double _avgSpeed = 0;
  int _speedCounter = 0;

  final StopWatchTimer _stopWatchTimer = StopWatchTimer();

  @override
  void initState() {
    super.initState();
    //현재 위치로
    _getLocationPermission();
    _stopWatchTimer.onExecute.add(StopWatchExecute.start);
  }
  //실시간 현재 위치로 이동
  void _getLocationPermission() async {
    final location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  @override
  void dispose() async {
    super.dispose();
    await _stopWatchTimer.dispose(); // Need to call dispose function.
  }

  void _onMapCreated(GoogleMapController controller) async{
    _mapController = controller;
    double appendDist;

    _location.onLocationChanged.listen((event) {
      LatLng loc = LatLng(event.latitude, event.longitude);
      _center = loc;
      _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: loc, zoom: 20)));

      if (route.length > 0) {
        appendDist = Geolocator.distanceBetween(route.last.latitude,
            route.last.longitude, loc.latitude, loc.longitude);
        _dist = _dist + appendDist;
        int timeDuration = (_time - _lastTime);

        if (_lastTime != null && timeDuration != 0) {
          _speed = (appendDist / (timeDuration / 100)) * 3.6;
          if (_speed != 0) {
            _avgSpeed = _avgSpeed + _speed;
            _speedCounter++;
          }

        }
      }
      _lastTime = _time;
      route.add(loc);

      polyline.add(Polyline(
          polylineId: PolylineId(event.toString()),
          visible: true,
          points: route,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          color: Colors.deepOrange));

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
          Container(
              child: GoogleMap(
                polylines: polyline,
                zoomControlsEnabled: false,
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                initialCameraPosition: CameraPosition(target: _center, zoom: 20),
              )),
          Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: double.infinity,
                height: 220,
                padding: EdgeInsets.fromLTRB(20, 60, 20, 10),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(40)),
                child: Column(
                  children: [
                    // Align(
                    //   alignment: Alignment.topLeft,
                    //   child: IconButton(
                    //     onPressed: (){
                    //       Navigator.pop(context);
                    //     },
                    //     icon:Icon(Icons.arrow_back_ios,color: Colors.white,),
                    //     //replace with our own icon data.
                    //   ),
                    // ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text("속도 (KM/H)",
                                style: GoogleFonts.montserrat(
                                    fontSize: 15, fontWeight: FontWeight.w300, color: Colors.white)),
                            Text(_speed.toStringAsFixed(2),
                                style: GoogleFonts.montserrat(
                                    fontSize: 30, fontWeight: FontWeight.w300, color: Colors.white))
                          ],
                        ),
                        Column(
                          children: [
                            Text("시간",
                                style: GoogleFonts.montserrat(
                                    fontSize: 15, fontWeight: FontWeight.w300, color: Colors.white)),
                            StreamBuilder<int>(
                              stream: _stopWatchTimer.rawTime,
                              initialData: 0,
                              builder: (context, snap) {
                                _time = snap.data;
                                _displayTime =
                                    StopWatchTimer.getDisplayTimeHours(_time) +
                                        ":" +
                                        StopWatchTimer.getDisplayTimeMinute(_time) +
                                        ":" +
                                        StopWatchTimer.getDisplayTimeSecond(_time);
                                return Text(_displayTime,
                                    style: GoogleFonts.montserrat(
                                        fontSize: 30, fontWeight: FontWeight.w300, color: Colors.white));
                              },
                            )
                          ],
                        ),
                        Column(
                          children: [
                            Text("거리 (KM)",
                                style: GoogleFonts.montserrat(
                                    fontSize: 15, fontWeight: FontWeight.w300, color: Colors.white)),
                            Text((_dist / 1000).toStringAsFixed(2),
                                style: GoogleFonts.montserrat(
                                    fontSize: 30, fontWeight: FontWeight.w300, color: Colors.white))
                          ],
                        )
                      ],
                    ),
                    Divider(),
                    IconButton(
                      icon: Icon(
                        Icons.stop_circle_outlined,
                        size: 50,
                        color: Colors.red,
                      ),
                      padding: EdgeInsets.all(0),
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("알림"),
                            content: Text("주행을 기록 하시겠습니까?"),
                            actions: [
                              TextButton(
                                child: Text("계속 주행"),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              TextButton(
                                child: Text("예"),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  Entry en = Entry(
                                      date: DateFormat.yMMMMd('en_US').format(DateTime.now()),
                                      duration: _displayTime,
                                      speed: _speedCounter == 0 ? 0 : _avgSpeed / _speedCounter,
                                      distance: _dist
                                  );
                                  await DB.insert(Entry.table, en);
                                  //Navigator.push(context, MaterialPageRoute(builder: (context) => DiaryScreen()));
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DiaryScreen()),
                                  );
                                },
                              ),

                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )),
        ]));
  }
}

