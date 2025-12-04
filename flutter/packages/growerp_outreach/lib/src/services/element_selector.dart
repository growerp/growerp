import 'snapshot_parser.dart';

/// Element selector utility for finding and interacting with page elements
class ElementSelector {
  final SnapshotElement root;

  const ElementSelector(this.root);

  /// Find element by data-testid
  SnapshotElement? byTestId(String testId) {
    return SnapshotParser.findFirst(root, testId: testId);
  }

  /// Find element by text content
  SnapshotElement? byText(String text, {bool exact = false}) {
    return SnapshotParser.findByText(root, text, exact: exact);
  }

  /// Find button by text
  SnapshotElement? button(String text) {
    return SnapshotParser.findButton(root, text);
  }

  /// Find input field
  SnapshotElement? input({String? label, String? placeholder}) {
    return SnapshotParser.findInput(root,
        label: label, placeholder: placeholder);
  }

  /// Find link by text
  SnapshotElement? link(String text) {
    return SnapshotParser.findLink(root, text);
  }

  /// Find element by role
  List<SnapshotElement> byRole(String role) {
    return SnapshotParser.getElementsByRole(root, role);
  }

  /// Find element by custom predicate
  SnapshotElement? where(bool Function(SnapshotElement) predicate) {
    return SnapshotParser.findFirst(root, predicate: predicate);
  }

  /// Find all elements matching predicate
  List<SnapshotElement> whereAll(bool Function(SnapshotElement) predicate) {
    return SnapshotParser.findAll(root, predicate: predicate);
  }
}

/// Twitter-specific element selectors
class TwitterSelectors {
  static const String followButton = 'follow';
  static const String unfollowButton = 'unfollow';
  static const String messageButton = 'sendDMFromProfile';
  static const String dmInput = 'dmComposerTextInput';
  static const String dmSendButton = 'dmComposerSendButton';
  static const String userCell = 'UserCell';
  static const String tweetButton = 'tweetButton';
  static const String searchBox = 'SearchBox_Search_Input';

  /// Find follow button
  static SnapshotElement? findFollowButton(ElementSelector selector) {
    return selector.byTestId(followButton) ?? selector.button('Follow');
  }

  /// Find message button
  static SnapshotElement? findMessageButton(ElementSelector selector) {
    return selector.byTestId(messageButton) ?? selector.button('Message');
  }

  /// Find DM input field
  static SnapshotElement? findDMInput(ElementSelector selector) {
    return selector.byTestId(dmInput) ??
        selector.input(placeholder: 'Start a message');
  }

  /// Find DM send button
  static SnapshotElement? findDMSendButton(ElementSelector selector) {
    return selector.byTestId(dmSendButton) ?? selector.button('Send');
  }

  /// Find user profile cards in search results
  static List<SnapshotElement> findUserCells(ElementSelector selector) {
    final cells = <SnapshotElement>[];
    final elements = selector.whereAll((e) => e.testId == userCell);
    cells.addAll(elements);
    return cells;
  }

  /// Extract profile data from user cell
  static Map<String, String?> extractProfileData(SnapshotElement userCell) {
    final selector = ElementSelector(userCell);

    // Find name (usually in a heading or strong text)
    final nameElement =
        selector.where((e) => e.role == 'heading' || e.role == 'strong');

    // Find handle (starts with @)
    final handleElement = selector.where((e) {
      final text = e.name ?? e.value ?? '';
      return text.startsWith('@');
    });

    // Find bio/description
    final bioElement = selector
        .where((e) => e.role == 'paragraph' && (e.name?.length ?? 0) > 20);

    // Find profile link
    final linkElement = selector.link('');

    return {
      'name': nameElement?.name,
      'handle': handleElement?.name ?? handleElement?.value,
      'bio': bioElement?.name,
      'profileUrl': linkElement?.getAttribute('href'),
    };
  }
}

/// LinkedIn-specific element selectors
class LinkedInSelectors {
  static const String connectButton = 'connect-button';
  static const String messageButton = 'message-button';
  static const String searchBox = 'search-global-typeahead';

  /// Find connect button
  static SnapshotElement? findConnectButton(ElementSelector selector) {
    return selector.byTestId(connectButton) ?? selector.button('Connect');
  }

  /// Find message button
  static SnapshotElement? findMessageButton(ElementSelector selector) {
    return selector.byTestId(messageButton) ?? selector.button('Message');
  }
}
