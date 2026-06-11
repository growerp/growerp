import 'package:flutter/material.dart';

/// A [Page] that displays a dialog.
class DialogPage<T> extends Page<T> {
  final Widget child;

  const DialogPage({required this.child, super.key, super.name, super.arguments});

  @override
  Route<T> createRoute(BuildContext context) {
    return DialogRoute<T>(
      context: context,
      settings: this,
      builder: (context) => child,
    );
  }
}
