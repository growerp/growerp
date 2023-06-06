import 'package:flutter/material.dart';

class NavBarItem extends StatelessWidget {
  final bool drawer;
  final String title;
  final String navigationPath;
  const NavBarItem(this.title, this.navigationPath, [this.drawer = false]);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      mouseCursor: MaterialStateMouseCursor.clickable,
      onTap: () {
        if (drawer) Navigator.pop(context);
        Navigator.pushNamed(context, navigationPath);
      },
      child: Text(
        title,
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
