import 'package:flutter/material.dart';
import '../routing/route_names.dart';
import '../forms/forms.dart';

Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case homeRoute:
      return MaterialPageRoute(
        builder: (context) => const LayoutTemplate(form: HomeForm()),
      );
    case aboutRoute:
      return MaterialPageRoute(
        builder: (context) => const LayoutTemplate(form: AboutForm()),
      );
    case ofbizRoute:
      return MaterialPageRoute(
        builder: (context) => const LayoutTemplate(form: OfbizForm()),
      );
    case moquiRoute:
      return MaterialPageRoute(
        builder: (context) => const LayoutTemplate(form: MoquiForm()),
      );
    default:
      return null;
  }
}
