import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ListKeysFinder extends MatchFinder {
  ListKeysFinder({super.skipOffstage});

  @override
  String get description => 'List all keys';

  @override
  bool matches(Element candidate) {
    final Widget widget = candidate.widget;
    return widget.key != null;
  }
}

extension ListKeys on CommonFinders {
  Finder listKeys({bool skipOffstage = true}) =>
      ListKeysFinder(skipOffstage: skipOffstage);
}
