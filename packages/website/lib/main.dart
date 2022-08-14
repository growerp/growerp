import 'package:flutter/material.dart';
import 'forms/home_form.dart';
import 'forms/layout/layout_template.dart';
import 'routing/router.dart' as router;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void main() {
  configureApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrowERP open source flutter frontend.',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Open Sans'),
      ),
      onGenerateRoute: router.generateRoute,
      home: LayoutTemplate(form: HomeForm()),
    );
  }
}

void configureApp() {
  setUrlStrategy(PathUrlStrategy());
}
