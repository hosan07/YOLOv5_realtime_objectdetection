import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/gaps.dart';
import '../../constants/padding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:objectdetection/screen/home/widget/map/model/entry.dart';
import '../home/widget/diary/diary_screen.dart';
import 'package:http/http.dart'as http;
import '../home/widget/weather/geolocator.dart';

class UserScreen2 extends StatefulWidget {
  @override
  _UserScreen2State createState() => _UserScreen2State();
}

class _UserScreen2State extends State<UserScreen2> {
  var currentUser = FirebaseAuth.instance.currentUser;
  final _authentication = FirebaseAuth.instance;
  User loggedUser;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // 환경설정 아이콘을 눌렀을 때의 동작을 구현합니다.
            },
            icon: Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () {
              // 환경설정 아이콘을 눌렀을 때의 동작을 구현합니다.
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
                height: MediaQuery.of(context).size.height*0.25,
                //color: Theme.of(context).primaryColor,
                //color: Colors.grey[400],
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20),

                    ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 0.1,
                      blurRadius: 7,
                      offset: Offset(0, 15), // changes position of shadow
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeSize.padding1,
                  child: Column(
                    children: [
                      Gaps.v10,
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey,
                                  blurRadius: 3.0,
                                  spreadRadius: 1.0,
                                  offset: const Offset(0,7),
                                ),
                              ],
                              color: Theme.of(context).scaffoldBackgroundColor,
                              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor,width: 3),
                              borderRadius: BorderRadius.circular(60),
                            ),

                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.asset(
                                'images/logo.png',
                                height: MediaQuery.of(context).size.height*0.1,
                                width: MediaQuery.of(context).size.width*0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Gaps.v10,
                      Text('${FirebaseAuth.instance.currentUser.displayName}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          color: Colors.black,
                        ),),
                      SizedBox(
                        height: MediaQuery.of(context).size.height*0.01,
                      ),
                      //Text('${FirebaseAuth.instance.currentUser!.email}',
                      Text('${FirebaseAuth.instance.currentUser.email}',
                        style: TextStyle(
                          fontSize: 20,
                        ),),
                      Gaps.v20,
                    ],
                  ),
                )
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height*0.05,
            )
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              color: Colors.white,
              child: Padding(
                padding: EdgeSize.padding1,
                child: Container(
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: FutureBuilder<Entry>(
                      future: fetchLatestEntry(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          Entry latestEntry = snapshot.data;
                          
                          // return Column(
                          //   crossAxisAlignment: CrossAxisAlignment.start,
                          //   mainAxisAlignment: MainAxisAlignment.start,
                          //   children: [
                          //     Gaps.v10,
                          //     Row(
                          //       children: [
                          //         Text(
                          //           '${FirebaseAuth.instance.currentUser.displayName} 님의 기록',
                          //           style: TextStyle(
                          //             color: Colors.black,
                          //             fontSize: 18,
                          //             fontWeight: FontWeight.bold,
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //     Gaps.v10,
                          //     Text(
                          //       '${(latestEntry.distance / 1000).toStringAsFixed(2)} km, ${latestEntry.duration}',
                          //       style: TextStyle(
                          //         color: Colors.black,
                          //         fontSize: 16,
                          //       ),
                          //     ),
                          //   ],
                          // );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Gaps.v10,
                              Row(
                                children: [
                                  Text(
                                    '${FirebaseAuth.instance.currentUser.displayName} 님의 기록',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Spacer(),
                                  Icon(Icons.navigate_next, color: Colors.black,)
                                ],
                              ),
                              Gaps.v10,
                              Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: Colors.grey,
                                  child: SizedBox(height: MediaQuery.of(context).size.height*0.1,)),
                              Gaps.v20,
                              Text(
                                latestEntry.date,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "${(latestEntry.distance / 1000).toStringAsFixed(2)} km",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Text(
                                    "시간: ",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    latestEntry.duration,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Text(
                                    "평균속도: ",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    "${latestEntry.speed.toStringAsFixed(2)} km/h",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
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
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Gaps.v32,
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              color: Colors.white,
              child: Padding(
                padding: EdgeSize.padding1,
                child: Text('dd'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              color: Colors.white,
              child: Padding(
                padding: EdgeSize.padding1,
                child: Text('dd'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              color: Colors.white,
              child: Padding(
                padding: EdgeSize.padding1,
                child: Text('dd'),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
