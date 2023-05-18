import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:objectdetection/screen/home/widget/map/model/entry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class EntryCard extends StatelessWidget {
  final Entry entry;
  final void Function(Entry) onDelete;
  EntryCard({this.entry, this.onDelete});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.date,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("기록 삭제"),
                        content: Text("이 기록을 삭제하시겠습니까?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text("취소"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onDelete(entry);
                            },
                            child: Text("예"),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.delete),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              "${(entry.distance / 1000).toStringAsFixed(2)} km",
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 5),
            Row(
              children: [
                Text(
                  "시간: ",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  entry.duration,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Row(
              children: [
                Text(
                  "평균속도: ",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  "${entry.speed.toStringAsFixed(2)} km/h",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
