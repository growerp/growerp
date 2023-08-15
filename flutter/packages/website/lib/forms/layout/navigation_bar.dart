import 'package:flutter/material.dart';
import '../../routing/route_names.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'nav_bar_item.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: const NavigationMenuMobile(),
      tablet: const NavigationMenuTabletDesktop(20),
      desktop: const NavigationMenuTabletDesktop(50),
    );
  }
}

class NavigationMenuMobile extends StatelessWidget {
  const NavigationMenuMobile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          const NavBarLogo()
        ],
      ),
    );
  }
}

class NavigationMenuTabletDesktop extends StatelessWidget {
  final double spacing;
  const NavigationMenuTabletDesktop(this.spacing, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const NavBarLogo(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const NavBarItem('Home', HomeRoute),
              SizedBox(width: spacing),
              const NavBarItem('About', AboutRoute),
              SizedBox(width: spacing),
              const NavBarItem('Moqui', MoquiRoute),
              SizedBox(width: spacing),
              const NavBarItem('OFBiz', OfbizRoute),
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
