import 'package:flutter/material.dart';
import '../routing/route_names.dart';
import '../forms/@forms.dart';

Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case HomeRoute:
      return MaterialPageRoute(
          builder: (context) => const LayoutTemplate(form: HomeForm()));
    case AboutRoute:
      return MaterialPageRoute(
          builder: (context) => const LayoutTemplate(form: AboutForm()));
    case OfbizRoute:
      return MaterialPageRoute(
          builder: (context) => const LayoutTemplate(form: OfbizForm()));
    case MoquiRoute:
      return MaterialPageRoute(
          builder: (context) => const LayoutTemplate(form: MoquiForm()));
    default:
      return null;
  }
}
