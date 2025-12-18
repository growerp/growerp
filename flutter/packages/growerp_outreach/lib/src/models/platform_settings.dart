import 'dart:convert';

/// Helper class for managing per-platform settings stored as JSON
/// in the platformSettings field of OutreachCampaign.
///
/// JSON structure:
/// ```json
/// {
///   "linkedin": {
///     "actionType": "message_connections",
///     "searchKeywords": "Flutter Developer",
///     "messageTemplate": ""
///   },
///   "twitter": {
///     "actionType": "post_tweet",
///     "searchKeywords": "",
///     "messageTemplate": "Check out our new feature!"
///   },
///   "substack": {
///     "actionType": "post_note",
///     "searchKeywords": "",
///     "messageTemplate": ""
///   }
/// }
/// ```
class PlatformSettings {
  final Map<String, PlatformConfig> _settings;

  PlatformSettings._(this._settings);

  /// Create empty platform settings
  factory PlatformSettings.empty() => PlatformSettings._({});

  /// Parse from JSON string stored in database
  factory PlatformSettings.fromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return PlatformSettings.empty();
    }
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final settings = <String, PlatformConfig>{};
      for (final entry in json.entries) {
        if (entry.value is Map<String, dynamic>) {
          settings[entry.key.toLowerCase()] =
              PlatformConfig.fromJson(entry.value);
        }
      }
      return PlatformSettings._(settings);
    } catch (e) {
      return PlatformSettings.empty();
    }
  }

  /// Convert to JSON string for database storage
  String toJson() {
    final json = <String, dynamic>{};
    for (final entry in _settings.entries) {
      json[entry.key] = entry.value.toJson();
    }
    return jsonEncode(json);
  }

  /// Get settings for a specific platform
  PlatformConfig? getForPlatform(String platform) {
    return _settings[platform.toLowerCase()];
  }

  /// Get message template for a platform with fallback to campaign template
  String getMessageTemplate(String platform, String? campaignTemplate) {
    final config = getForPlatform(platform);
    final platformTemplate = config?.messageTemplate;
    if (platformTemplate != null && platformTemplate.isNotEmpty) {
      return platformTemplate;
    }
    return campaignTemplate ?? '';
  }

  /// Get action type for a platform with default fallback
  String getActionType(String platform, String defaultAction) {
    final config = getForPlatform(platform);
    return config?.actionType ?? defaultAction;
  }

  /// Get search keywords for a platform
  String getSearchKeywords(String platform) {
    final config = getForPlatform(platform);
    return config?.searchKeywords ?? '';
  }

  /// Update settings for a platform and return new PlatformSettings instance
  PlatformSettings updatePlatform(String platform, PlatformConfig config) {
    final newSettings = Map<String, PlatformConfig>.from(_settings);
    newSettings[platform.toLowerCase()] = config;
    return PlatformSettings._(newSettings);
  }

  /// Check if there are any settings
  bool get isEmpty => _settings.isEmpty;
  bool get isNotEmpty => _settings.isNotEmpty;

  @override
  String toString() => 'PlatformSettings($_settings)';
}

/// Configuration for a single platform
class PlatformConfig {
  final String? actionType;
  final String? searchKeywords;
  final String? messageTemplate;

  /// List of recipients with personalized messages for DM actions
  /// Format: [{"name": "...", "handle": "...", "message": "..."}]
  final List<Map<String, String>>? messageList;

  const PlatformConfig({
    this.actionType,
    this.searchKeywords,
    this.messageTemplate,
    this.messageList,
  });

  factory PlatformConfig.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>>? parsedList;
    if (json['messageList'] is List) {
      parsedList = (json['messageList'] as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    }
    return PlatformConfig(
      actionType: json['actionType'] as String?,
      searchKeywords: json['searchKeywords'] as String?,
      messageTemplate: json['messageTemplate'] as String?,
      messageList: parsedList,
    );
  }

  Map<String, dynamic> toJson() => {
        if (actionType != null) 'actionType': actionType,
        if (searchKeywords != null) 'searchKeywords': searchKeywords,
        if (messageTemplate != null) 'messageTemplate': messageTemplate,
        if (messageList != null && messageList!.isNotEmpty)
          'messageList': messageList,
      };

  PlatformConfig copyWith({
    String? actionType,
    String? searchKeywords,
    String? messageTemplate,
    List<Map<String, String>>? messageList,
  }) {
    return PlatformConfig(
      actionType: actionType ?? this.actionType,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      messageTemplate: messageTemplate ?? this.messageTemplate,
      messageList: messageList ?? this.messageList,
    );
  }

  @override
  String toString() =>
      'PlatformConfig(action: $actionType, keywords: $searchKeywords, listSize: ${messageList?.length ?? 0})';
}
