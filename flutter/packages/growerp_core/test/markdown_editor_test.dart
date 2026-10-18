import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';

void main() {
  test('article markdown survives the visual editor', () {
    const article = '''
Intro paragraph with **bold**, *italic* and a [link](https://growerp.com).

## First subheading

- one
- two

1. first
2. second

> a quote

Closing text with `code`.
''';
    expect(MarkdownEditor.roundTrips(article), isTrue);
    expect(MarkdownEditor.roundTrips(''), isTrue);
  });

  test('literal markdown characters stay literal', () {
    expect(
      MarkdownEditor.roundTrips(
        '1\\. not a list\n\n\\# not a heading\n\nsnake\\_case and 2 \\* 3',
      ),
      isTrue,
    );
  });

  test('raw html is not visual safe', () {
    expect(
      MarkdownEditor.roundTrips('<div class="hero">Hello</div>\n\nText'),
      isFalse,
    );
  });

  test('plain text for list cells', () {
    expect(
      MarkdownEditor.toPlainText('## Title\n\n**bold** & *it*\n\n- one\n- two'),
      'Title bold & it one two',
    );
    expect(MarkdownEditor.toPlainText('a &amp;lt; b'), 'a &lt; b');
    expect(MarkdownEditor.toPlainText(''), '');
  });

  testWidgets('editor lays out inside an AlertDialog', (tester) async {
    final controller = TextEditingController(text: 'some **text**');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlertDialog(
            content: SingleChildScrollView(
              child: Column(
                children: [
                  const TextField(),
                  MarkdownEditor(controller: controller, height: 200),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(MarkdownEditor), findsOneWidget);
    // let the cursor blink timer of the visual editor go
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
