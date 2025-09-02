import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

bool isPhone(BuildContext context) {
  return ResponsiveBreakpoints.of(context).equals(MOBILE);
}

// to be assigned to 'isPhone' locally
bool isAPhone(BuildContext context) {
  return ResponsiveBreakpoints.of(context).equals(MOBILE);
}

bool isLargerThanPhone(BuildContext context) {
  return ResponsiveBreakpoints.of(context).largerThan(MOBILE);
}
