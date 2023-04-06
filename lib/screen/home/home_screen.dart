import 'package:flutter/material.dart';

import 'package:objectdetection/screen/home/widget/diary/diary_screen.dart';
import 'package:objectdetection/screen/home/widget/map/db/dbhelper.dart';
import 'package:objectdetection/screen/home/widget/map/model/entry.dart';
import 'package:objectdetection/screen/home/widget/map/pages/maps.dart';
import 'package:objectdetection/screen/objectdetection/ui/home_view.dart';

class HomeScreen extends StatelessWidget {
  // Future<void> _fetchEntries() async{
  //   List<Entry> entries = (await DBHelper.getEntries()).cast<Entry>();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text('좋아요',style: Theme.of(context).appBarTheme.titleTextStyle,),
      ),
      body: Column(
        children: [
          Text('d'),
          // FloatingActionButton(
          //   onPressed: () async {
          //     Entry newEntry = await Navigator.push(
          //         context, MaterialPageRoute(builder: (context) => MapPage()));
          //     if (newEntry != null) {
          //       Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //               builder: (context) => DiaryScreen())).then((value) => _fetchEntries());
          //     }
          //   },
          //   tooltip: 'Add Entry',
          //   child: Icon(Icons.add),
          // ),
          /*ElevatedButton(
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0), // 원하는 모서리 반지름 크기
              ),
              padding: EdgeInsets.all(16.0), // 버튼 내부 패딩 설정
            ),
            child: Icon(Icons.add),
          ),*/
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DiaryScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: Text('주행기록'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeView()),
              );
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: Text('카메라'),
          ),
        ],
      ),
    );
  }
}