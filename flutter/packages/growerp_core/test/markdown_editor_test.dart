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
}
