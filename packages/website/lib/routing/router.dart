import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../routing/route_names.dart';
import '../forms/@forms.dart';

Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case HomeRoute:
      return MaterialPageRoute(
          builder: (context) => LayoutTemplate(form: HomeForm()));
    case AboutRoute:
      return MaterialPageRoute(
          builder: (context) => LayoutTemplate(form: AboutForm()));
    case OfbizRoute:
      return MaterialPageRoute(
          builder: (context) => LayoutTemplate(form: OfbizForm()));
    case MoquiRoute:
      return MaterialPageRoute(
          builder: (context) => LayoutTemplate(form: MoquiForm()));
    default:
      return null;
  }
}
