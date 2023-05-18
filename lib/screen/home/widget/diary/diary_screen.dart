import 'package:flutter/material.dart';
import 'package:objectdetection/bottomnavigation/main_naviagation_screen.dart';
import 'package:objectdetection/screen/home/widget/map/model/entry.dart';
import 'package:objectdetection/screen/home/widget/map/widgets/entry_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    _fetchEntries();
  }

  void _fetchEntries() async {
    //_cards = [];
    String uid = FirebaseAuth.instance.currentUser.uid;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entry')
        .get();
    setState(() {
      _data = snapshot.docs.map((doc) => Entry.fromMap(doc.data())).toList();
      _data.sort((a,b)=> b.entryId.compareTo(a.entryId));
      _cards = _data.map((entry) => EntryCard(entry: entry, onDelete: _deleteEntry)).toList();
      // _cards = [];
      // _cards.addAll(newCards);
    });
  }

  void _deleteEntry(Entry entry) async {
    //String entryId = DateTime.now().microsecondsSinceEpoch.toString();
    String uid = FirebaseAuth.instance.currentUser.uid;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entry')
        .get();
    List<QueryDocumentSnapshot> documentsToDelete = snapshot.docs
        .where((doc) => doc.id == entry.entryId)
        .toList();
    for (QueryDocumentSnapshot doc in documentsToDelete) {
      await doc.reference.delete();
    }
    setState(() {
      _data.remove(entry);
      _cards.removeWhere((card) => card.entry == entry);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("기록이 삭제되었습니다.")),
      );
    });
    await _fetchEntries();
    // setState(() {
    // });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("다이어리"),
        leading: BackButton(color: Colors.black, onPressed: (){
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainNavigationScreen())
          );
        },),

      ),
      body: ListView(
        children: _cards,
      ),
    );
  }
}
