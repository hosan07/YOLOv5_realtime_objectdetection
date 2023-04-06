import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:objectdetection/screen/objectdetection/ui/camera_view.dart';
import '../constants/sizes.dart';
import '../screen/home/widget/diary/diary_screen.dart';
import '../screen/home/home_screen.dart';
import '../screen/home/widget/map/pages/maps.dart';
import '../screen/objectdetection/ui/home_view.dart';
import 'widgets/nav_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.yellow,
        extendBody: true, // Important: to remove background of bottom navigation (making the bar transparent doesn't help)
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0), // adjust to your liking
              topRight: Radius.circular(20.0), // adjust to your liking
            ),
            color: Colors.transparent, // put the color here
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
                /*PostVideoButton(
                    onPressed: _onPostVideoButtonTap,
                    isInverted: _selectedIndex != 0,
                  ),*/
                //Gaps.h24,
                NavTab(
                  //text: 'Like',
                  isSelected: _selectedIndex == 2,
                  icon: Icons.favorite_border_outlined,
                  selectedIcon: Icons.favorite,
                  onTap: () => _onTapBottomNavigationItem(2),
                  selectedIndex: _selectedIndex,
                ),
                NavTab(
                  //text: 'Profile',
                  isSelected: _selectedIndex == 3,
                  icon: FontAwesomeIcons.message,
                  selectedIcon: FontAwesomeIcons.solidMessage,
                  onTap: () => _onTapBottomNavigationItem(3),
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
            child: HomeView(),
          ),
          Offstage(
            offstage: _selectedIndex != 1,
            //child: HomeView(),
            child: HomeScreen(),
            //child: MapScreen(),
          ),
          Offstage(
            offstage: _selectedIndex != 2,
            child: HomeScreen(),
          ),
          Offstage(
            offstage: _selectedIndex != 3,
            child: DiaryScreen(),
          ),
        ],
      ),
    );
  }

  void _onTapBottomNavigationItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  /*void _onPostVideoButtonTap() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Record Video'),
        ),
      ),
      fullscreenDialog: true,
    ));
  }*/
}
