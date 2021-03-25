import 'package:flutter/material.dart';

/// class to configure tab screens, see example below
class MapItem {
  final Icon? icon; // bottom of screen tab icon
  final String? label; // label of tab top/bottom
  final Widget? form; // form to be displayed in a tab selection
  final String?
      floatButtonRoute; // action bottom routing per tab List at the top, string single at the bottom
  final dynamic floatButtonArgs; // argument for route.
  MapItem({
    this.icon,
    this.label,
    this.form,
    this.floatButtonRoute,
    this.floatButtonArgs,
  });
}
