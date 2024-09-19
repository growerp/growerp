// general settings
import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

var companyUserPadding = const SpanPadding(trailing: 5, leading: 5);
SpanDecoration? getCompanyUserBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}
