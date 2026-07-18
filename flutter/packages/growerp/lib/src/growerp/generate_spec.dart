/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';

import 'app_blocks.dart';
import 'create_app.dart';
import 'vertical_spec.dart';

final _logger = Logger(filter: ProductionFilter());

/// AI-assisted vertical creation. Turns a plain-language business [description]
/// into a validated [VerticalSpec] via a direct Gemini call, shows it for
/// confirmation, then runs the same deterministic [createApp] scaffold.
///
/// Requires the GOOGLE_API_KEY environment variable. The model is Gemini
/// (override with GEMINI_MODEL, default gemini-2.0-flash).
Future<void> createAppFromDescription(
  String description,
  String growerpPath,
) async {
  final apiKey = Platform.environment['GOOGLE_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    _logger.e(
      'GOOGLE_API_KEY is not set. Export it, or use the deterministic form:\n'
      '  growerp createApp <name> -b <blocks>',
    );
    exit(1);
  }

  _logger.i('Asking AI to design a vertical for: "$description"');

  VerticalSpec? spec;
  String? lastError;
  for (var attempt = 0; attempt < 2 && spec == null; attempt++) {
    final raw = await _callGemini(apiKey, description, lastError);
    try {
      spec = VerticalSpec.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException catch (e) {
      lastError = e.message;
      _logger.w('AI returned an invalid spec (attempt ${attempt + 1}): '
          '${e.message}');
    }
  }

  if (spec == null) {
    _logger.e('Could not obtain a valid spec from the AI. Try --blocks '
        'instead.');
    exit(1);
  }

  stdout.writeln('\nProposed vertical:\n$spec\n');
  stdout.write('Create this vertical? [y/N] ');
  final answer = stdin.readLineSync()?.trim().toLowerCase();
  if (answer != 'y' && answer != 'yes') {
    _logger.i('Aborted.');
    exit(0);
  }

  await createApp(
    spec.name,
    spec.blocks,
    growerpPath,
    appTitle: spec.appTitle,
  );
}

/// Calls Gemini generateContent in JSON mode and returns the raw JSON text.
Future<String> _callGemini(
  String apiKey,
  String description,
  String? priorError,
) async {
  final model = Platform.environment['GEMINI_MODEL'] ?? 'gemini-2.0-flash';
  final uri = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/'
    '$model:generateContent?key=$apiKey',
  );

  final catalog = appBlocks.values
      .map((b) => '- ${b.key}: ${b.description}')
      .join('\n');

  final prompt = StringBuffer()
    ..writeln(
      'You design a GrowERP vertical ERP app from a business description. '
      'Choose a short lowercase app name (letters/digits/underscore, starting '
      'with a letter) and the building blocks that fit the business.',
    )
    ..writeln('\nAvailable blocks:\n$catalog')
    ..writeln(
      '\nRules: pick only block keys from the list above. Always include '
      'user_company. Include adk unless the user clearly does not want an AI '
      'assistant. Prefer the smallest set that serves the business.',
    )
    ..writeln('\nBusiness description: $description');
  if (priorError != null) {
    prompt.writeln('\nYour previous answer was rejected: $priorError '
        'Return a corrected spec.');
  }

  final body = jsonEncode({
    'contents': [
      {
        'parts': [
          {'text': prompt.toString()},
        ],
      },
    ],
    'generationConfig': {
      'responseMimeType': 'application/json',
      'responseSchema': {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'appTitle': {'type': 'string'},
          'blocks': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'required': ['name', 'blocks'],
      },
    },
  });

  final client = HttpClient();
  try {
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.add(utf8.encode(body));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      _logger.e('Gemini API error ${response.statusCode}: $responseBody');
      exit(1);
    }

    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List?;
    final text = candidates == null || candidates.isEmpty
        ? null
        : (((candidates.first as Map)['content'] as Map?)?['parts']
                as List?)
            ?.map((p) => (p as Map)['text'])
            .whereType<String>()
            .join();
    if (text == null || text.isEmpty) {
      _logger.e('Gemini returned no content: $responseBody');
      exit(1);
    }
    return text;
  } finally {
    client.close();
  }
}
