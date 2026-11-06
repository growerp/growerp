import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/src/domains/common/widgets/styled_data_table.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('table start/end follow $direction, left stays physical', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: StyledDataTable(
                columns: const [
                  StyledColumn(header: 'start'),
                  StyledColumn(header: 'end', alignment: TextAlign.end),
                  StyledColumn(header: 'left', alignment: TextAlign.left),
                ],
                rows: const [
                  [Text('start cell'), Text('end cell'), Text('left cell')],
                ],
              ),
            ),
          ),
        ),
      );
      for (final entry in {
        'start cell': AlignmentDirectional.centerStart.resolve(direction),
        'end cell': AlignmentDirectional.centerEnd.resolve(direction),
        'left cell': Alignment.centerLeft,
      }.entries) {
        final align = tester.widget<Align>(
          find
              .ancestor(of: find.text(entry.key), matching: find.byType(Align))
              .first,
        );
        expect(align.alignment.resolve(direction), entry.value);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
