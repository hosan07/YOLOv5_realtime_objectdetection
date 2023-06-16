import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:objectdetection/screen/home/widget/diary/diary_screen.dart';
import 'package:objectdetection/screen/home/widget/map/map_screen.dart';
import '../constants/sizes.dart';
import '../screen/home/home_screen.dart';
import '../screen/home/widget/map/pages/maps.dart';
import '../screen/user/user_screen2.dart';
import 'widgets/nav_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  // Future<void> _fetchEntries() async{
  //   List<Entry> entries = (await DBHelper.getEntries()).cast<Entry>();
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        extendBody: true, // Important: to remove background of bottom navigation (making the bar transparent doesn't help)
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0), // adjust to your liking
              topRight: Radius.circular(20.0), // adjust to your liking
            ),
            color: Colors.white, // put the color here
          ),
        child: BottomAppBar(
          elevation: 0,
          height: Sizes.size96,
          //color: _selectedIndex == 0 ? Colors.black : Colors.white,
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 25, 10,0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NavTab(
                  isSelected: _selectedIndex == 0,
                  icon: FontAwesomeIcons.house,
                  selectedIcon: FontAwesomeIcons.house,
                  onTap: () => _onTapBottomNavigationItem(0),
                  selectedIndex: _selectedIndex,
                ),
                NavTab(
                  //text: 'Map',
                  isSelected: _selectedIndex == 1,
                  icon: Icons.location_pin,
                  selectedIcon: Icons.location_pin,
                  onTap: () => _onTapBottomNavigationItem(1),
                  selectedIndex: _selectedIndex,
                ),
                NavTab(
                  //text: 'Profile',
                  isSelected: _selectedIndex == 2,
                  icon: FontAwesomeIcons.user,
                  selectedIcon: FontAwesomeIcons.solidUser,
                  onTap: () => _onTapBottomNavigationItem(2),
                  selectedIndex: _selectedIndex,
                ),

              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Offstage(
            offstage: _selectedIndex != 0,
            child: HomeScreen(),
            //child: ChooseDemo(),
          ),
          Offstage(
            offstage: _selectedIndex != 1,
            //child: HomeView2(),
            child: MapView(),
          ),
          Offstage(
            offstage: _selectedIndex != 2,
            child: UserScreen2(),
          ),
        ],
      ),
      floatingActionButtonLocation: _selectedIndex == 0 ? FloatingActionButtonLocation.endFloat : null,
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        heroTag: 'uniqueTag',
        onPressed: () async {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => MapPage()));
              //context, MaterialPageRoute(builder: (context) => ChooseDemo()));
        },
        child: Text("주행 시작",style: TextStyle(color: Colors.black,fontSize: 10, fontWeight: FontWeight.bold),),
        backgroundColor: Colors.grey[350],
        elevation: 8,
      ) : null,
    );
  }
  void _onTapBottomNavigationItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
