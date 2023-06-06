import 'package:flutter/material.dart';
import '../../routing/route_names.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'nav_bar_item.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: NavigationMenuMobile(),
      tablet: NavigationMenuTabletDesktop(20),
      desktop: NavigationMenuTabletDesktop(50),
    );
  }
}

class NavigationMenuMobile extends StatelessWidget {
  const NavigationMenuMobile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          NavBarLogo()
        ],
      ),
    );
  }
}

class NavigationMenuTabletDesktop extends StatelessWidget {
  final double spacing;
  const NavigationMenuTabletDesktop(this.spacing);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          NavBarLogo(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              NavBarItem('Home', HomeRoute),
              SizedBox(width: spacing),
              NavBarItem('About', AboutRoute),
              SizedBox(width: spacing),
              NavBarItem('Moqui', MoquiRoute),
              SizedBox(width: spacing),
              NavBarItem('OFBiz', OfbizRoute),
            ],
          )
        ],
      ),
    );
  }
}

class NavBarLogo extends StatelessWidget {
  const NavBarLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        mouseCursor: MaterialStateMouseCursor.clickable,
        onTap: () {
          Navigator.pushNamed(context, HomeRoute);
        },
        child: SizedBox(
          child: Image.asset('assets/growerp.png'),
        ));
  }
}
