import 'package:flutter/material.dart';
import 'package:growerp_inventory/l10n/generated/inventory_localizations.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(InventoryLocalizations.of(context)!.helloWorld),
        ),
      ),
    );
  }
}
