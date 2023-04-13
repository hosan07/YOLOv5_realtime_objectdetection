import 'package:flutter/material.dart';
import 'package:objectdetection/screen/home/widget/diary/diary_screen.dart';
import 'package:objectdetection/screen/home/widget/map/db/dbhelper.dart';
import 'package:objectdetection/screen/home/widget/map/model/entry.dart';
import 'package:objectdetection/screen/home/widget/map/pages/maps.dart';
import 'package:objectdetection/screen/home/widget/objectdetection/tflite/recognition.dart';
import 'package:objectdetection/screen/home/widget/objectdetection/tflite/stats.dart';
import 'package:objectdetection/constants/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:objectdetection/screen/home/widget/weather/geolocator.dart';

class HomeScreen extends StatefulWidget {

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Future<void> _fetchEntries() async{
  //   List<Entry> entries = (await DBHelper.getEntries()).cast<Entry>();
  // }
  Future<void> _fetchEntries() async{
    List<Entry> entries = (await DBHelper.getEntries()).cast<Entry>();
  }
  /// Results to draw bounding boxes
  List<Recognition> results;

  /// Realtime stats
  Stats stats;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeSize.padding2,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('...')
              ],
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
                      Text("안녕하세요",style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w300
                      ),),
                      Gaps.v5,
                      Text("호산님",style: TextStyle(
                          fontSize: 25, fontWeight: FontWeight.w600
                      ),
                      ),
                      Gaps.v20,
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        child: Container(
                          color: Colors.white,
                          width: double.infinity,
                          height: 170,
                          child: Weather(),
                        ),
                      ),
                      Gaps.v20,
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            child: Container(
                              width: 170,
                              height: 100,
                              child: SizedBox(
                                height: 300,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => DiaryScreen()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF13C5D1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                  child: Text(
                                    '주행 기록',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Gaps.h10,
                          ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            child: Container(
                              width: 170,
                              height: 100,
                              child: SizedBox(
                                height: 300,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Entry newEntry = await Navigator.push(
                                        context, MaterialPageRoute(builder: (context) => MapPage()));
                                    if (newEntry != null) {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => DiaryScreen())).then((value) => _fetchEntries());
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF13C5D1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                  child: Text(
                                    '주행 시작',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                )
            ),
          ),


        ],
      ),
    );
  }
}