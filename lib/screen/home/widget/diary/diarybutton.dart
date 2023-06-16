// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:objectdetection/screen/home/widget/map/model/entry.dart';
// import '../map/pages/maps.dart';
//
// class AddEntryButton extends StatelessWidget {
//   final Function(Entry) onPressed;
//
//   const AddEntryButton({Key key, this.onPressed}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return FloatingActionButton(
//       onPressed: () async {
//         final result = await Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => MapPage()),
//         );
//         if (result != null) {
//           onPressed(result);
//         }
//       },
//       tooltip: 'Increment',
//       child: Icon(Icons.add),
//     );
//   }
// }