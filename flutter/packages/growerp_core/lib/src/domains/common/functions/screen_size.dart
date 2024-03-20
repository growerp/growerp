import 'package:responsive_framework/responsive_framework.dart';

bool isPhone(context) {
  return ResponsiveBreakpoints.of(context).equals(MOBILE);
}

// to be assigned to 'isPhone' locally
bool isAPhone(context) {
  return ResponsiveBreakpoints.of(context).equals(MOBILE);
}

bool isLargerThanPhone(context) {
  return ResponsiveBreakpoints.of(context).largerThan(MOBILE);
}
