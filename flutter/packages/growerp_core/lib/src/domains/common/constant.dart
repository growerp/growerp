import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Constant {
  static var numberFormat = NumberFormat.decimalPattern('en-US');
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
}
