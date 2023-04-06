import 'package:flutter/material.dart';


import 'package:objectdetection/screen/home/widget/map/db/db.dart';
import 'package:objectdetection/screen/home/widget/map/model/entry.dart';
import 'package:objectdetection/screen/home/widget/map/widgets/entry_card.dart';

class DiaryScreen extends StatefulWidget {
  DiaryScreen({Key key}) : super(key: key);

  @override
  _DiaryState createState() => _DiaryState();
}

class _DiaryState extends State<DiaryScreen> {
  List<Entry> _data;
  List<EntryCard> _cards = [];

  void initState() {
    super.initState();
    DB.init().then((value) => _fetchEntries());
  }

  void _fetchEntries() async {
    _cards = [];
    List<Map<String, dynamic>> _results = await DB.query(Entry.table);
    _data = _results.map((item) => Entry.fromMap(item)).toList();
    _data.forEach((element) => _cards.add(EntryCard(entry: element, onDelete: _deleteEntry,)));
    setState(() {});
  }

  void _addEntries(Entry en) async {
    await DB.insert(Entry.table, en);
    _fetchEntries();
  }
  void _deleteEntry(int id) async {
    int result = await DB.delete(Entry.table, id);
    if(result != 0){
      _fetchEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("기록이 삭제되었습니다.")),
      );
    }

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("다이어리"),
        leading: BackButton(color: Colors.black),

      ),
      body: ListView(
        children: _cards,
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => Navigator.push(
      //       context, MaterialPageRoute(builder: (context) => MapPage()))
      //       .then((value) => _addEntries(value)),
      //   tooltip: 'Increment',
      //   child: Icon(Icons.add),
      // ),// This trailing comma makes auto-formatting nicer for build methods.
      // floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
    );
  }
}
