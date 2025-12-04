/// Snapshot element from browsermcp accessibility tree
class SnapshotElement {
  final String ref;
  final String role;
  final String? name;
  final String? value;
  final Map<String, dynamic> attributes;
  final List<SnapshotElement> children;

  const SnapshotElement({
    required this.ref,
    required this.role,
    this.name,
    this.value,
    this.attributes = const {},
    this.children = const [],
  });

  factory SnapshotElement.fromJson(Map<String, dynamic> json) {
    return SnapshotElement(
      ref: json['ref'] as String,
      role: json['role'] as String? ?? 'generic',
      name: json['name'] as String?,
      value: json['value'] as String?,
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
      children: (json['children'] as List?)
              ?.map((e) => SnapshotElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Get attribute value
  String? getAttribute(String key) => attributes[key] as String?;

  /// Check if element has attribute
  bool hasAttribute(String key) => attributes.containsKey(key);

  /// Get data-testid attribute
  String? get testId => getAttribute('data-testid');

  /// Check if element matches criteria
  bool matches({
    String? role,
    String? name,
    String? testId,
    String? value,
  }) {
    if (role != null && this.role != role) return false;
    if (name != null && this.name != name) return false;
    if (testId != null && this.testId != testId) return false;
    if (value != null && this.value != value) return false;
    return true;
  }

  @override
  String toString() => 'Element(ref=$ref, role=$role, name=$name)';
}

/// Snapshot parser for browsermcp accessibility tree
class SnapshotParser {
  /// Parse snapshot JSON into element tree
  static SnapshotElement? parse(Map<String, dynamic> snapshot) {
    final root = snapshot['root'] as Map<String, dynamic>?;
    if (root == null) return null;

    return SnapshotElement.fromJson(root);
  }

  /// Find all elements matching criteria
  static List<SnapshotElement> findAll(
    SnapshotElement root, {
    String? role,
    String? name,
    String? testId,
    String? value,
    bool Function(SnapshotElement)? predicate,
  }) {
    final results = <SnapshotElement>[];

    void search(SnapshotElement element) {
      // Check if element matches
      final matchesCriteria = element.matches(
        role: role,
        name: name,
        testId: testId,
        value: value,
      );

      final matchesPredicate = predicate?.call(element) ?? true;

      if (matchesCriteria && matchesPredicate) {
        results.add(element);
      }

      // Search children
      for (final child in element.children) {
        search(child);
      }
    }

    search(root);
    return results;
  }

  /// Find first element matching criteria
  static SnapshotElement? findFirst(
    SnapshotElement root, {
    String? role,
    String? name,
    String? testId,
    String? value,
    bool Function(SnapshotElement)? predicate,
  }) {
    final results = findAll(
      root,
      role: role,
      name: name,
      testId: testId,
      value: value,
      predicate: predicate,
    );

    return results.isNotEmpty ? results.first : null;
  }

  /// Find element by text content (case-insensitive partial match)
  static SnapshotElement? findByText(
    SnapshotElement root,
    String text, {
    bool exact = false,
  }) {
    return findFirst(
      root,
      predicate: (element) {
        final elementText = element.name ?? element.value ?? '';
        if (exact) {
          return elementText.toLowerCase() == text.toLowerCase();
        } else {
          return elementText.toLowerCase().contains(text.toLowerCase());
        }
      },
    );
  }

  /// Find button by text
  static SnapshotElement? findButton(SnapshotElement root, String text) {
    return findFirst(
      root,
      role: 'button',
      predicate: (element) {
        final elementText = element.name ?? '';
        return elementText.toLowerCase().contains(text.toLowerCase());
      },
    );
  }

  /// Find input field by label or placeholder
  static SnapshotElement? findInput(
    SnapshotElement root, {
    String? label,
    String? placeholder,
  }) {
    return findFirst(
      root,
      role: 'textbox',
      predicate: (element) {
        if (label != null) {
          final elementLabel = element.name ?? '';
          if (elementLabel.toLowerCase().contains(label.toLowerCase())) {
            return true;
          }
        }
        if (placeholder != null) {
          final elementPlaceholder = element.getAttribute('placeholder') ?? '';
          if (elementPlaceholder
              .toLowerCase()
              .contains(placeholder.toLowerCase())) {
            return true;
          }
        }
        return label == null && placeholder == null;
      },
    );
  }

  /// Find link by text
  static SnapshotElement? findLink(SnapshotElement root, String text) {
    return findFirst(
      root,
      role: 'link',
      predicate: (element) {
        final elementText = element.name ?? '';
        return elementText.toLowerCase().contains(text.toLowerCase());
      },
    );
  }

  /// Get all elements of a specific role
  static List<SnapshotElement> getElementsByRole(
    SnapshotElement root,
    String role,
  ) {
    return findAll(root, role: role);
  }

  /// Debug: Print element tree
  static void printTree(SnapshotElement element, {int indent = 0}) {
    final prefix = '  ' * indent;
    print(
        '$prefix${element.role}: ${element.name ?? element.value ?? "(no text)"}');
    if (element.testId != null) {
      print('$prefix  [data-testid="${element.testId}"]');
    }
    for (final child in element.children) {
      printTree(child, indent: indent + 1);
    }
  }
}
