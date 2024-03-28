import 'package:flutter/material.dart';

class TextWorkflowTask extends StatelessWidget {
  final List<String> text;
  const TextWorkflowTask(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text.join()));
  }
}
