import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart'as http;
import 'package:objectdetection/screen/home/widget/map/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:objectdetection/screen/home/widget/diary/diary_screen.dart';
import 'package:objectdetection/screen/home/widget/map/model/entry.dart';
import 'package:objectdetection/screen/home/widget/map/pages/maps.dart';
import 'package:objectdetection/constants/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:objectdetection/screen/home/widget/weather/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class HomeScreen extends StatefulWidget {

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> weatherData = {};
  final _openweatherKey = '2834387742b25d5393a21e88fee8246a';

  var currentUser = FirebaseAuth.instance.currentUser;
  final _authentication = FirebaseAuth.instance;
  User loggedUser;
  @override
  void initState() {
    super.initState();
    getCurrentUser();
    getPosition();
  }
  Future<void> getPosition() async {
    var currentPosition = await Geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    var lastPosition = await Geolocator
        .getLastKnownPosition();
    print(currentPosition);
    print(lastPosition);
    getWeatherData(
        lat: currentPosition.latitude.toString(),
        lon: currentPosition.longitude.toString());
  }

  Future<void> getWeatherData({
    @required String lat,
    @required String lon,
  }) async {
    String str ='http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_openweatherKey';
    print(str);
    final response = await http.get(Uri.parse(str));

    if (response.statusCode == 200) {
      var data = response.body;
      var dataJson = jsonDecode(data); // string to json
      setState(() {
        weatherData = dataJson;
      });
      print('data = $data');
      print('${dataJson['main']['temp']}');
    } else {
      print('response status code = ${response.statusCode}');
    }
  }

  Future<void> _refreshData() async {
    await getPosition();
  }

  void getCurrentUser(){
    try {
      final user = _authentication.currentUser;
      if (user != null) {
        loggedUser = user;
        print(loggedUser.email);
        print(loggedUser.displayName);
      }
    }catch(e){
      print(e);
    }
  }
  //최근 다이어리 기록 위젯 가져오기
  Future<Entry> fetchLatestEntry() async {
    String uid = FirebaseAuth.instance.currentUser.uid;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entry')
        .orderBy('entryId', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return Entry.fromMap(snapshot.docs.first.data());
    } else {
      return null;
    }
  }


  // Future<void> _fetchEntries() async{
  //   List<Entry> entries = (await DBHelper.getEntries()).cast<Entry>();
  // }
  // Future<void> _fetchEntries() async{
  //   List<Entry> entries = (await DBHelper.getEntries()).cast<Entry>();
  // }
  // /// Results to draw bounding boxes
  // List<Recognition> results;
  //
  // /// Realtime stats
  // Stats stats;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        backgroundColor: Colors.white,
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).size.height*0.07,),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height:MediaQuery.of(context).size.height*0.08,
                child: Weather(
                  weatherData: weatherData,
                  refreshData: _refreshData,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                  height: MediaQuery.of(context).size.height*0.45,
                  //color: Theme.of(context).primaryColor,
                  //color: Colors.grey[400],
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 0.1,
                        blurRadius: 12,
                        offset: Offset(0,-15), // changes position of shadow
                      ),
                    ],
                  ),
                child: Padding(
                  padding: EdgeSize.padding1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height*0.05,
                      ),
                      Text("안녕하세요",style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w300
                      ),),
                      Gaps.v5,
                      Text('${loggedUser?.displayName} 님',style: TextStyle(
                          fontSize: 25, fontWeight: FontWeight.w600
                      ),
                      ),
                      Gaps.v20,
                      Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 3.0,
                              spreadRadius: 0.0,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          height: 300,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pushReplacement(
                                  context, MaterialPageRoute(builder: (context) => MapPage()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '주행 시작',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                Gaps.v5,

                                Text(
                                  '안전한 주행 되세요',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      //fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Gaps.v20,
                      Row(
                        children: [
                          Container(
                            width: 170,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 3.0,
                                  spreadRadius: 0.0,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => DiaryScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                primary: Colors.grey[300],
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: FutureBuilder<Entry>(
                                future: fetchLatestEntry(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    Entry latestEntry = snapshot.data;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '최근 주행 기록',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                             Spacer(),
                                            Icon(Icons.navigate_next, color: Colors.black,)
                                          ],
                                        ),
                                        Gaps.v5,
                                        Container(
                                            width: double.infinity,
                                            height: 1,
                                            color: Colors.grey,
                                            child: SizedBox(height: MediaQuery.of(context).size.height*0.1,)),
                                        Gaps.v10,
                                        Text(
                                          '${(latestEntry.distance / 1000).toStringAsFixed(2)} km, ${latestEntry.duration}',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    );
                                  } else if (snapshot.hasError) {
                                    return Text('오류 발생');
                                  } else {
                                    return CircularProgressIndicator();
                                  }
                                },
                              ),
                            ),
                          ),
                          Gaps.h10,
                          Container(
                            width: 170,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 3.0,
                                  spreadRadius: 0.0,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              height: 300,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => MapView()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '길 찾기',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeSize.padding1,
                child: Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.grey,
                    child: SizedBox(height: MediaQuery.of(context).size.height*0.1,)),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                  height: MediaQuery.of(context).size.height*1,
                  //color: Theme.of(context).primaryColor,
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeSize.padding1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Gaps.v20,
                        //Text('dd'),

                      ],
                    ),
                  )
              ),
            ),


          ],
        ),
      ),
    );
  }
}