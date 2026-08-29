/*
 * Regression test for the lead dialog not showing a just created company:
 * AutocompleteLabel kept its first initialValue because Flutter's Autocomplete
 * and FormField only read initialValue in initState (Aug 2026).
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';

/// Rebuilds an AutocompleteLabel with a new initialValue, as the user dialog
/// does with setState after its company dialog pops.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        // a Form ancestor, as every dialog using this widget has: a controller
        // write during build would mark it dirty mid-build
        body: Form(
          child: Column(
            children: [
              AutocompleteLabel<String>(
                key: const Key('field'),
                label: 'company',
                initialValue: _value,
                optionsBuilder: (_) async => const ['picked'],
                displayStringForOption: (v) => v,
                onSelected: (v) => setState(() => _value = v),
              ),
              TextButton(
                key: const Key('create'),
                onPressed: () => setState(() => _value = 'created'),
                child: const Text('create'),
              ),
              TextButton(
                key: const Key('remove'),
                onPressed: () => setState(() => _value = null),
                child: const Text('remove'),
              ),
              TextButton(
                key: const Key('rebuild'),
                onPressed: () => setState(() {}),
                child: const Text('rebuild'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  String fieldText(WidgetTester tester) => tester
      .widget<TextFormField>(
        find.descendant(
          of: find.byKey(const Key('field')),
          matching: find.byType(TextFormField),
        ),
      )
      .controller!
      .text;

  testWidgets('shows a value assigned by the parent after the first build', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    expect(fieldText(tester), '');

    await tester.tap(find.byKey(const Key('create')));
    await tester.pumpAndSettle();

    expect(fieldText(tester), 'created');
  });

  testWidgets('clears when the parent removes the value', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.tap(find.byKey(const Key('create')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('remove')));
    await tester.pumpAndSettle();

    expect(fieldText(tester), '');
  });

  testWidgets('keeps what the user typed while the parent rebuilds', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    await tester.enterText(find.byType(TextFormField), 'typ');
    await tester.pump();

    // an unrelated parent rebuild with an unchanged initialValue
    await tester.tap(find.byKey(const Key('rebuild')));
    await tester.pumpAndSettle();

    expect(fieldText(tester), 'typ');
  });
}
