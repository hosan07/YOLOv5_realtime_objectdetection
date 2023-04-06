import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:objectdetection/constants/constants.dart';

class NavTab extends StatelessWidget {
  const NavTab({
    //required this.text,
    this.isSelected,
    this.icon,
    this.selectedIcon,
    this.onTap,
    this.selectedIndex,
    this.text,
  });

  //final String text;
  final bool isSelected;
  final IconData icon;
  final IconData selectedIcon;
  final Function() onTap;
  final int selectedIndex;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          //color: selectedIndex == 0 ? Colors.black : Colors.white,
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: isSelected ? 1 : 0.6,
            duration: const Duration(milliseconds: 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  isSelected ? selectedIcon : icon,
                  size: 25,
                  //color: selectedIndex == 0 ? Colors.white : Colors.black,
                  color: Colors.black,
                ),
                Gaps.v6,
                /*Text(
                  text,
                  style: TextStyle(
                    //color: selectedIndex == 0 ? Colors.white : Colors.black,
                    color: Colors.black,
                  ),
                )*/
              ],
            ),
          ),
        ),
      ),
    );
  }
}
