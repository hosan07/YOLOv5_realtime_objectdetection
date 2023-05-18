import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../diary/diary_screen.dart';
import '../tflite/recognition.dart';
import '../tflite/stats.dart';
import 'box_widget.dart';
import 'camera_view.dart';
import 'camera_view_singleton.dart';
import 'package:objectdetection/screen/home/widget/map/model/entry.dart';

/// [HomeView] stacks [CameraView] and [BoxWidget]s with bottom sheet for stats
class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Future<void> _fetchEntries() async{
  //   List<Entry> entries = (await DBHelper.getEntries()).cast<Entry>();
  // }
  /// Results to draw bounding boxes
  List<Recognition> results;

  /// Realtime stats
  Stats stats;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          // Camera View
          CameraView(resultsCallback, statsCallback),
          // 객체 트래킹 박스
          boundingBoxes(results),
          // Heading
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: EdgeInsets.only(top: 40),
              // child: Text(
              //   '실시간 물체 감지',
              //   textAlign: TextAlign.left,
              //   style: TextStyle(
              //     fontSize: 28,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.deepOrangeAccent.withOpacity(0.6),
              //   ),
              // ),
              // child: IconButton(
              //   onPressed: (){
              //     Navigator.pop(context);
              //   },
              //   icon:Icon(Icons.arrow_back_ios,color: Colors.white,),
              //   //replace with our own icon data.
              // ),
            ),
          ),
          // Align(
          //   alignment: Alignment.bottomRight,
          //   child: Padding(
          //     padding: EdgeInsets.all(50),
          //     child: Expanded(
          //       child: ElevatedButton(
          //         onPressed: () {
          //           Navigator.push(
          //             context,
          //             MaterialPageRoute(builder: (context) => DiaryScreen()),
          //           );
          //         },
          //         style: ElevatedButton.styleFrom(
          //           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(25.0),
          //           ),
          //           primary: Colors.white.withOpacity(0.1),
          //         ),
          //         child: Text(
          //           '주행 기록',
          //           style: TextStyle(
          //             color: Colors.white,
          //             fontSize: 18,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          //주행시작, 주행기록 버튼
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 20),
          //   child: Align(
          //     alignment: Alignment.bottomCenter,
          //     child: Padding(
          //       padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
          //       child: Row(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           Expanded(
          //             child: ElevatedButton(
          //               onPressed: () async {
          //                 Entry newEntry = await Navigator.push(
          //                     context, MaterialPageRoute(builder: (context) => MapPage()));
          //                 if (newEntry != null) {
          //                   Navigator.push(
          //                       context,
          //                       MaterialPageRoute(builder: (context) => DiaryScreen())).then((value) => _fetchEntries());
          //                 }
          //               },
          //               style: ElevatedButton.styleFrom(
          //                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          //                 shape: RoundedRectangleBorder(
          //                   borderRadius: BorderRadius.circular(25.0),
          //                 ),
          //                 primary: Colors.white.withOpacity(0.1),
          //               ),
          //               child: Text(
          //                 '주행 시작',
          //                 style: TextStyle(
          //                   color: Colors.white,
          //                   fontSize: 18,
          //                 ),
          //               ),
          //             ),
          //           ),
          //           SizedBox(width: 30,),
          //           Expanded(
          //             child: ElevatedButton(
          //               onPressed: () {
          //                 Navigator.push(
          //                   context,
          //                   MaterialPageRoute(builder: (context) => DiaryScreen()),
          //                 );
          //               },
          //               style: ElevatedButton.styleFrom(
          //                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          //                 shape: RoundedRectangleBorder(
          //                   borderRadius: BorderRadius.circular(25.0),
          //                 ),
          //                 primary: Colors.white.withOpacity(0.1),
          //               ),
          //               child: Text(
          //                 '주행 기록',
          //                 style: TextStyle(
          //                   color: Colors.white,
          //                   fontSize: 18,
          //
          //                 ),
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                (stats != null)
                    ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                    StatsRow('Inference time:',
                        '${stats.inferenceTime} ms'),
                    StatsRow('Total prediction time:',
                        '${stats.totalElapsedTime} ms'),
                    StatsRow('Pre-processing time:',
                        '${stats.preProcessingTime} ms'),
                    StatsRow('Frame',
                        '${CameraViewSingleton.inputImageSize?.width} X ${CameraViewSingleton.inputImageSize?.height}'),
                  ],
                  ),
                )
                    : Container()
              ],
            ),
          ),
          // Center(
          //   child: Align(
          //     alignment: Alignment.bottomCenter,
          //     child: Hero(
          //       tag: 'button',
          //       child: ElevatedButton(
          //         child: Text('지도로'),
          //         onPressed: (){
          //           Navigator.pushReplacementNamed(context, '/map');
          //         },
          //       ),
          //     ),
          //   ),
          // ),
          // Bottom Sheet
          /*Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.1,
              maxChildSize: 0.5,
              builder: (_, ScrollController scrollController) => Container(
                width: double.maxFinite,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BORDER_RADIUS_BOTTOM_SHEET),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard_arrow_up,
                            size: 48, color: Colors.orange),
                        (stats != null)
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    StatsRow('Inference time:',
                                        '${stats.inferenceTime} ms'),
                                    StatsRow('Total prediction time:',
                                        '${stats.totalElapsedTime} ms'),
                                    StatsRow('Pre-processing time:',
                                        '${stats.preProcessingTime} ms'),
                                    StatsRow('Frame',
                                        '${CameraViewSingleton.inputImageSize?.width} X ${CameraViewSingleton.inputImageSize?.height}'),
                                  ],
                                ),
                              )
                            : Container()
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),*/
        ],
      ),
    );
  }

  /// Returns Stack of bounding boxes
  /*Widget boundingBoxes(List<Recognition> results) {
    if (results == null) {
      return Container();
    }
    return Stack(
      children: results
          .map((e) => BoxWidget(
                result: e,
              ))
          .toList(),
    );
  }*/

  /*Widget boundingBoxes(List<Recognition> results) {
    if (results == null) {
      return Container();
    }
    return Stack(
      children: results
          .map((e) => Positioned(
        left: e.location.left,
        top: e.location.top,
        width: e.location.width,
        height: e.location.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              '${e.label} 감지됨!',
              style: TextStyle(
                  backgroundColor: Colors.black54,
                  color: Colors.white,
                  fontSize: 16.0),
            ),
            BoxWidget(
              result: e,
            ),
          ],
        ),
      ))
          .toList(),
    );
  }*/
  /*Widget boundingBoxes(List<Recognition> results) {
    if (results == null) {
      return Container();
    }
    bool isCarDetected = false; // car가 감지되었는지 확인하는 변수
    Recognition carResult; // car가 감지된 Recognition 객체
    for (Recognition result in results) {
      if (result.label == "cup" && result.score > 0.5) { // car가 감지되었다면
        isCarDetected = true;
        carResult = result;
        break;
      }
    }
    return Stack(
      children: [
        ...results.map((e) => BoxWidget(result: e)).toList(),
        if (isCarDetected) // car가 감지되었다면 큰 텍스트를 표시
          Positioned(
            top: 300,
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.car_crash, size: 200),

                  Text(
                    "차 감지!!",
                    style: TextStyle(fontSize: 50, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        if (carResult != null) // car가 감지되었다면 차의 위치를 표시
          BoxWidget(
            result: carResult,
            color: Colors.red,
          ),
      ],
    );
  }*/
  Widget boundingBoxes(List<Recognition> results) {
    if (results == null) {
      return Container();
    }

    // 감지된 객체를 저장할 Map
    Map<String, Recognition> detectedObjects = {};

    // 각 라벨에 대한 색상을 지정할 Map
    Map<String, Color> labelColorMap = {
      "car": Colors.red,
      "person": Colors.green,
      "bus": Colors.yellow,
      "keyboard" : Colors.red,
      "motorcycle" : Colors.blue,
    };
    // 각 라벨에 대한 이미지를 지정할 Map
    Map<String, String> labelImageMap = {
      "car": "images/car.png",
      "bus": "images/bus.png",
      "person": "images/person.png",
      "keyboard": "images/keyboard.png",
      "motorcycle": "images/motorcycle.png",
    };

    // 결과를 순회하면서 score가 0.5보다 높고 labelColorMap에 해당 라벨이 등록되어 있는 경우에만 detectedObjects에 추가
    for (Recognition result in results) {
      if (result.score > 0.3 && labelColorMap.containsKey(result.label)) {
        detectedObjects[result.label] = result;
        if (result.label == "car" || result.label == "bus" ||
            result.label == "person" || result.label == "keyboard" ||
            result.label == "motorcycle"
        ) {
          //진동을 주는 라이브러리 duration: 1000(진동이 발생할 시간 기본값은 500ms),
          //amplitude: 255(진동 세기 기본값 -1 최대 255)
          print(result.label);
          Vibration.vibrate();
        }
      }
    }

    // 화면에 표시할 위젯들을 Stack에 추가
    return Stack(
      children: [
        // 모든 결과에 대한 BoxWidget을 추가
        ...results.map((e) => BoxWidget(result: e)).toList(),
        // 감지된 객체가 있을 경우
        if (detectedObjects.isNotEmpty)
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 감지된 객체들의 라벨과 아이콘, 텍스트를 표시
                for (String label in detectedObjects.keys)
                  Column(
                    children: [
                      Image.asset(labelImageMap[label], width: 200, height: 200, color: labelColorMap[label]),
                      Text(
                        "$label 감지!",
                        style: TextStyle(fontSize: 20, color: labelColorMap[label]),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        // 감지된 객체들에 대한 BoxWidget을 추가
        ...detectedObjects.values
            .map((e) => BoxWidget(result: e, color: labelColorMap[e.label]))
            .toList(),
      ],
    );
  }

  /// Callback to get inference results from [CameraView]
  void resultsCallback(List<Recognition> results) {
    setState(() {
      this.results = results;
    });
  }

  /// Callback to get inference stats from [CameraView]
  void statsCallback(Stats stats) {
    setState(() {
      this.stats = stats;
    });
  }

  static const BOTTOM_SHEET_RADIUS = Radius.circular(24.0);
  static const BORDER_RADIUS_BOTTOM_SHEET = BorderRadius.only(
      topLeft: BOTTOM_SHEET_RADIUS, topRight: BOTTOM_SHEET_RADIUS);
}

/// Row for one Stats field
class StatsRow extends StatelessWidget {
  final String left;
  final String right;

  StatsRow(this.left, this.right);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(left), Text(right)],
      ),
    );
  }
}
