import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';

void main() {
  group('HtmlView.clean', () {
    test('removes FreeMarker comments, also multi-line', () {
      expect(
        HtmlView.clean(
          '<#-- title: Pricing -->\n<#-- description: a\nb -->\n<h1>Hi</h1>',
        ).trim(),
        '<h1>Hi</h1>',
      );
    });

    test('removes directive tags but keeps their content', () {
      expect(
        HtmlView.clean('<#if x??><p>yes</p><#else>no</#if>'),
        '<p>yes</p>no',
      );
    });

    test('removes macro calls', () {
      expect(HtmlView.clean('<@header/><p>a</p></@x>'), '<p>a</p>');
    });

    test('keeps plain html and html comments', () {
      const html = '<!-- note --><div class="a">\${name}</div>';
      expect(HtmlView.clean(html), html);
    });
  });

  testWidgets('renders html without FreeMarker comment text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlView('<#-- title: Pricing --><h1>Simple Pricing</h1>'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Simple Pricing', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('<#--', findRichText: true), findsNothing);
    expect(
      find.textContaining('title: Pricing', findRichText: true),
      findsNothing,
    );
  });
}
