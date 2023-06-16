import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:objectdetection/screen/home/widget/objectdetection/yolov5/ui/main_page.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:objectdetection/screen/home/widget/map/model/entry.dart';
import '../../diary/diary_screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
          CameraPosition(target: loc, zoom: 17)));

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
          Stack(
            children: [
              //HomeView(),
              Yolov5Page(),
              Container(
                width: double.infinity,
                height: 220,
                padding: EdgeInsets.fromLTRB(20, 60, 20, 10),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(40)),
                child: Column(
                  children: [
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
                                  String entryId = DateTime.now().microsecondsSinceEpoch.toString();
                                  Navigator.pop(context);
                                  Entry en = Entry(
                                    entryId: entryId,
                                    date: DateFormat.yMMMMd('en_US').format(DateTime.now()),
                                    duration: _displayTime,
                                    speed: _speedCounter == 0 ? 0 : _avgSpeed / _speedCounter,
                                    distance: _dist,
                                  );
                                  String uid = FirebaseAuth.instance.currentUser.uid;
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .collection('entry')
                                      //.doc(en.date)
                                      .doc(entryId)
                                      .set(en.toMap());
                                  Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (context) => DiaryScreen()),
                                        );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('기록이 저장되었습니다.')),
                                        );
                                  //     .then((value) {
                                  //   Navigator.pushReplacement(
                                  //     context,
                                  //     MaterialPageRoute(builder: (context) => DiaryScreen()),
                                  //   );
                                  // }).catchError((onError) {
                                  //   ScaffoldMessenger.of(context).showSnackBar(
                                  //     SnackBar(content: Text('운동 기록을 저장하는 중에 오류가 발생했습니다')),
                                  //   );
                                  // });
                                },
                              ),

                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
          SlidingUpPanel(
            collapsed: Container(
              height: 90,
              child: Column(
                  children: <Widget>[
                    Container(
                      //first container
                      height: 20,
                      width: 60,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          onPressed: () {},
                          child: Text('Button'),
                        ),
                      ),
                    ),
                  ]),
            ),
            color: Colors.transparent,
            maxHeight: MediaQuery.of(context).size.height*0.32,
            minHeight: 100,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            panel: Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height*0.3,
                  child: SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: GoogleMap(
                      polylines: polyline,
                      zoomControlsEnabled: false,
                      onMapCreated: _onMapCreated,
                      myLocationEnabled: true,
                      initialCameraPosition: CameraPosition(target: _center, zoom: 17),
                    ),
                  ),
                ),
              ),
            ),
          ),


          // SlidingUpPanel(
          //   minHeight: 90,
          //   maxHeight: MediaQuery.of(context).size.height / 2,
          //   //backdropEnabled: true,
          //   borderRadius: BorderRadius.vertical(
          //     top: Radius.circular(20),
          //   ),
          //   color: Colors.transparent,
          //   collapsed: Container(
          //     child: Container(
          //       height: 90,
          //       child: Column(
          //           mainAxisAlignment: MainAxisAlignment.end,
          //           children: <Widget>[
          //             Container(
          //               //first container
          //               height: 20,
          //               width: 60,
          //               child: Padding(
          //                 padding: EdgeInsets.only(bottom: 10),
          //                 // child: ElevatedButton(
          //                 //   style: ElevatedButton.styleFrom(
          //                 //     primary: Colors.white,
          //                 //     shape: RoundedRectangleBorder(
          //                 //       borderRadius: BorderRadius.circular(30.0),
          //                 //     ),
          //                 //   ),
          //                 //   onPressed: () {},
          //                 //   child: Text('Button'),
          //                 // ),
          //               ),
          //             ),
          //             Container(
          //               //second container
          //               height: 60,
          //               decoration: BoxDecoration(
          //                 color: Colors.white,
          //                 borderRadius: BorderRadius.vertical(
          //                   top: Radius.circular(20),
          //                 ),
          //               ),
          //               // child: GoogleMap(
          //               //   polylines: polyline,
          //               //   zoomControlsEnabled: false,
          //               //   onMapCreated: _onMapCreated,
          //               //   myLocationEnabled: true,
          //               //   initialCameraPosition: CameraPosition(target: _center, zoom: 17),
          //               // ),
          //             )
          //           ]),
          //     ),
          //   ),
          // ),





        ]));
  }
}

