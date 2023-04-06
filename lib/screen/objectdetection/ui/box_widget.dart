import 'package:flutter/material.dart';

import '../tflite/recognition.dart';


/// Individual bounding box
class BoxWidget extends StatelessWidget {
  final Recognition result;

  const BoxWidget({Key key, this.result, MaterialColor color}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    //일정 정확도미만이며 해당 물체 이외의 값일 경우 렌더링하지 않도록 한다
    if(result.score < 0.3 || !["car", "bus", "person", "keyboard", "motorcycle"].contains(result.label)){
      return SizedBox.shrink();
    }
    // if(result.score < 0.3){
    //   return SizedBox.shrink();
    // }
    // Color for bounding box
    Color color = Colors.primaries[
        (result.label.length + result.label.codeUnitAt(0) + result.id) %
            Colors.primaries.length];

    return Positioned(
      left: result.renderLocation.left,
      top: result.renderLocation.top + 30,
      width: result.renderLocation.width,
      height: result.renderLocation.height,
      child: Container(
        width: result.renderLocation.width,
        height: result.renderLocation.height,
        decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.all(Radius.circular(2))),
        child: Align(
          alignment: Alignment.topLeft,
          child: FittedBox(
            child: Container(
              color: color,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(result.label),
                  Text(" " + result.score.toStringAsFixed(2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
