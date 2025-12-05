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

/// Enum representing available outreach platforms
enum OutreachPlatform {
  EMAIL,
  LINKEDIN,
  TWITTER,
  MEDIUM,
  SUBSTACK,
  FACEBOOK;

  /// Returns the display name for the platform
  String get displayName {
    switch (this) {
      case OutreachPlatform.EMAIL:
        return 'Email';
      case OutreachPlatform.LINKEDIN:
        return 'LinkedIn';
      case OutreachPlatform.TWITTER:
        return 'X';
      case OutreachPlatform.MEDIUM:
        return 'Medium';
      case OutreachPlatform.SUBSTACK:
        return 'Substack';
      case OutreachPlatform.FACEBOOK:
        return 'Facebook';
    }
  }

  /// Returns the enum value from a string
  static OutreachPlatform fromString(String value) {
    return OutreachPlatform.values.firstWhere(
      (platform) => platform.name == value.toUpperCase(),
      orElse: () => throw ArgumentError('Invalid platform: $value'),
    );
  }
}
