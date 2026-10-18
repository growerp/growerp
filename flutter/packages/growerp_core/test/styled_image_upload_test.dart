/*
 * StyledImageUpload: an Add/Update button right of Remove uploads, and a tap
 * on an existing image shows it larger instead of uploading (Oct 2026).
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';

// a 1x1 png
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('without image: Add button and a tap on the image upload', (
    tester,
  ) async {
    int uploads = 0;
    await tester.pumpWidget(
      _host(StyledImageUpload(label: 'Image', onUploadTap: () => uploads++)),
    );
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Remove'), findsNothing);

    await tester.tap(find.byKey(const Key('imageUpload')));
    await tester.tap(find.byType(ClipOval));
    expect(uploads, 2);
    expect(find.byKey(const Key('imageLargeDialog')), findsNothing);
  });

  testWidgets('with image: Update uploads, a tap on the image enlarges it', (
    tester,
  ) async {
    int uploads = 0;
    int removes = 0;
    await tester.pumpWidget(
      _host(
        StyledImageUpload(
          label: 'Image',
          imageBytes: _png,
          onUploadTap: () => uploads++,
          onRemove: () => removes++,
        ),
      ),
    );
    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    // Update sits right of Remove
    expect(
      tester.getTopLeft(find.text('Update')).dx,
      greaterThan(tester.getTopLeft(find.text('Remove')).dx),
    );

    await tester.tap(find.byKey(const Key('imageUpload')));
    await tester.tap(find.text('Remove'));
    expect(uploads, 1);
    expect(removes, 1);

    await tester.tap(find.byType(ClipOval));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('imageLargeDialog')), findsOneWidget);
    expect(uploads, 1, reason: 'a tap on the image must not upload');
  });

  testWidgets('with image and onImageTap: the callback replaces the enlarge', (
    tester,
  ) async {
    int imageTaps = 0;
    await tester.pumpWidget(
      _host(
        StyledImageUpload(
          label: 'Image',
          imageBytes: _png,
          onUploadTap: () {},
          onImageTap: () => imageTaps++,
        ),
      ),
    );
    await tester.tap(find.byType(ClipOval));
    await tester.pumpAndSettle();
    expect(imageTaps, 1);
    expect(find.byKey(const Key('imageLargeDialog')), findsNothing);
  });
}
