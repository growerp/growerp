import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_outreach/src/models/platform_settings.dart';

void main() {
  group('PlatformSettings', () {
    test('should create empty settings', () {
      final settings = PlatformSettings.empty();
      expect(settings.isEmpty, isTrue);
    });

    test('should parse valid JSON', () {
      const json = '''
      {
        "linkedin": {
          "actionType": "message_connections",
          "searchKeywords": "Flutter Developer",
          "messageTemplate": "Hello!"
        },
        "twitter": {
          "actionType": "post_tweet"
        }
      }
      ''';

      final settings = PlatformSettings.fromJson(json);
      expect(settings.isNotEmpty, isTrue);

      final linkedin = settings.getForPlatform('linkedin');
      expect(linkedin, isNotNull);
      expect(linkedin!.actionType, equals('message_connections'));
      expect(linkedin.searchKeywords, equals('Flutter Developer'));
      expect(linkedin.messageTemplate, equals('Hello!'));

      final twitter = settings.getForPlatform('twitter');
      expect(twitter, isNotNull);
      expect(twitter!.actionType, equals('post_tweet'));
    });

    test('should handle null JSON', () {
      final settings = PlatformSettings.fromJson(null);
      expect(settings.isEmpty, isTrue);
    });

    test('should handle empty JSON', () {
      final settings = PlatformSettings.fromJson('');
      expect(settings.isEmpty, isTrue);
    });

    test('should handle invalid JSON gracefully', () {
      final settings = PlatformSettings.fromJson('invalid json');
      expect(settings.isEmpty, isTrue);
    });

    test('should convert to JSON', () {
      final settings = PlatformSettings.empty().updatePlatform(
        'linkedin',
        const PlatformConfig(
          actionType: 'search_and_connect',
          searchKeywords: 'Dart',
        ),
      );

      final json = settings.toJson();
      expect(json, contains('linkedin'));
      expect(json, contains('search_and_connect'));
      expect(json, contains('Dart'));
    });

    test('should get message template with fallback', () {
      final settings = PlatformSettings.fromJson('''
      {
        "linkedin": {"messageTemplate": "Platform message"},
        "twitter": {"messageTemplate": ""}
      }
      ''');

      // Platform template exists
      expect(
        settings.getMessageTemplate('linkedin', 'Campaign default'),
        equals('Platform message'),
      );

      // Platform template empty - fallback to campaign
      expect(
        settings.getMessageTemplate('twitter', 'Campaign default'),
        equals('Campaign default'),
      );

      // Platform not configured - fallback to campaign
      expect(
        settings.getMessageTemplate('substack', 'Campaign default'),
        equals('Campaign default'),
      );
    });

    test('should get action type with default', () {
      final settings = PlatformSettings.fromJson('''
      {"linkedin": {"actionType": "message_connections"}}
      ''');

      expect(
        settings.getActionType('linkedin', 'default_action'),
        equals('message_connections'),
      );

      expect(
        settings.getActionType('twitter', 'default_action'),
        equals('default_action'),
      );
    });

    test('should update platform settings', () {
      final settings = PlatformSettings.empty();
      expect(settings.isEmpty, isTrue);

      final updated = settings.updatePlatform(
        'linkedin',
        const PlatformConfig(actionType: 'message_connections'),
      );

      expect(settings.isEmpty, isTrue); // Original unchanged
      expect(updated.isNotEmpty, isTrue);
      expect(updated.getForPlatform('linkedin')?.actionType,
          equals('message_connections'));
    });

    test('should be case insensitive for platform names', () {
      final settings = PlatformSettings.fromJson('''
      {"LINKEDIN": {"actionType": "test"}}
      ''');

      expect(settings.getForPlatform('linkedin')?.actionType, equals('test'));
      expect(settings.getForPlatform('LINKEDIN')?.actionType, equals('test'));
      expect(settings.getForPlatform('LinkedIn')?.actionType, equals('test'));
    });
  });

  group('PlatformConfig', () {
    test('should create from JSON', () {
      final config = PlatformConfig.fromJson({
        'actionType': 'post_tweet',
        'searchKeywords': 'Flutter',
        'messageTemplate': 'Hello!',
      });

      expect(config.actionType, equals('post_tweet'));
      expect(config.searchKeywords, equals('Flutter'));
      expect(config.messageTemplate, equals('Hello!'));
    });

    test('should convert to JSON', () {
      const config = PlatformConfig(
        actionType: 'post_note',
        searchKeywords: 'Substack',
      );

      final json = config.toJson();
      expect(json['actionType'], equals('post_note'));
      expect(json['searchKeywords'], equals('Substack'));
      expect(json.containsKey('messageTemplate'), isFalse);
    });

    test('should copy with new values', () {
      const config = PlatformConfig(
        actionType: 'message_connections',
        searchKeywords: 'Flutter',
      );

      final copied = config.copyWith(actionType: 'search_and_connect');

      expect(copied.actionType, equals('search_and_connect'));
      expect(copied.searchKeywords, equals('Flutter')); // Unchanged
    });
  });
}
