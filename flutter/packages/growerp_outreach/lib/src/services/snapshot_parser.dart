import 'package:flutter/foundation.dart';

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
    debugPrint(
        '$prefix${element.role}: ${element.name ?? element.value ?? "(no text)"}');
    if (element.testId != null) {
      debugPrint('$prefix  [data-testid="${element.testId}"]');
    }
    for (final child in element.children) {
      printTree(child, indent: indent + 1);
    }
  }

  /// Parse Playwright MCP text snapshot format
  /// The snapshot is embedded in markdown with YAML format:
  /// ```yaml
  /// - generic [ref=e2]:
  ///   - heading "Example Domain" [level=1] [ref=e3]
  ///   - paragraph [ref=e4]: This domain is for...
  /// ```
  static SnapshotElement? parseText(String text) {
    // Extract YAML block from markdown
    final yamlMatch = RegExp(r'```yaml\n([\s\S]*?)```').firstMatch(text);
    final yamlContent = yamlMatch?.group(1) ?? text;
    
    final lines = yamlContent.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return null;

    // Parse the tree recursively starting at indent -2 (so first level at 0 works)
    final children = _parseChildren(lines, 0, -2);
    
    if (children.isEmpty) return null;
    
    // Return the first element as root, or wrap in a document
    if (children.length == 1) {
      return children.first;
    }
    
    return SnapshotElement(
      ref: 'root',
      role: 'document',
      name: 'page',
      children: children,
    );
  }

  /// Parse children at a given indent level
  /// parentIndent is the indent of the parent, children are at parentIndent + 2
  static List<SnapshotElement> _parseChildren(
      List<String> lines, int startIndex, int parentIndent) {
    final elements = <SnapshotElement>[];
    final expectedIndent = parentIndent + 2;
    int i = startIndex;

    while (i < lines.length) {
      final line = lines[i];
      final indent = _getIndent(line);

      // If we've gone back to parent level or above, stop
      if (indent < expectedIndent && i > startIndex) {
        break;
      }

      // Skip lines that aren't at our expected level or are metadata (like /url:)
      if (indent != expectedIndent || line.trim().startsWith('- /')) {
        i++;
        continue;
      }

      final element = _parseTextLine(line);
      if (element != null) {
        // Find children (lines with greater indent)
        final childStart = i + 1;
        final children = _parseChildren(lines, childStart, indent);
        
        // Count how many lines the children consumed
        int childLines = 0;
        int j = childStart;
        while (j < lines.length && _getIndent(lines[j]) > indent) {
          j++;
          childLines++;
        }

        elements.add(SnapshotElement(
          ref: element.ref,
          role: element.role,
          name: element.name,
          value: element.value,
          attributes: element.attributes,
          children: children,
        ));
        
        i = childStart + childLines;
      } else {
        i++;
      }
    }

    return elements;
  }

  static int _getIndent(String line) {
    int indent = 0;
    for (final char in line.split('')) {
      if (char == ' ') {
        indent++;
      } else {
        break;
      }
    }
    return indent;
  }

  /// Parse a single line like: 
  /// "- link \"Example\" [ref=s1e2]"
  /// "- heading \"Title\" [level=1] [ref=e3]"
  /// "- paragraph [ref=e4]: This is text content"
  /// "- generic [ref=e2]:"
  static SnapshotElement? _parseTextLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('-')) return null;
    // Skip metadata lines like "- /url: ..."
    if (trimmed.startsWith('- /')) return null;

    // Remove leading "- "
    final content = trimmed.substring(1).trim();

    // Extract all bracketed attributes [key=value]
    final attributes = <String, dynamic>{};
    String? ref;
    var remaining = content;
    
    final attrMatches = RegExp(r'\[([^\]]+)\]').allMatches(content);
    for (final match in attrMatches) {
      final attr = match.group(1)!;
      if (attr.startsWith('ref=')) {
        ref = attr.substring(4);
      } else if (attr.contains('=')) {
        final parts = attr.split('=');
        attributes[parts[0]] = parts.sublist(1).join('=');
      } else {
        attributes[attr] = true;
      }
      remaining = remaining.replaceFirst(match.group(0)!, '');
    }
    remaining = remaining.trim();

    // Extract role and name/value
    // Formats:
    // role "name"
    // role "name":
    // role: value text
    // role:
    String role = 'generic';
    String? name;
    String? value;

    // Check if there's quoted text: role "name"
    final quotedMatch = RegExp(r'^(\w+)\s+"([^"]*)"').firstMatch(remaining);
    if (quotedMatch != null) {
      role = quotedMatch.group(1)!;
      name = quotedMatch.group(2);
      // Check for trailing value after colon
      final afterQuote = remaining.substring(quotedMatch.end).trim();
      if (afterQuote.startsWith(':')) {
        value = afterQuote.substring(1).trim();
        if (value.isEmpty) value = null;
      }
    } else {
      // Format: role: value or role:
      final colonMatch = RegExp(r'^(\w+):(.*)$').firstMatch(remaining);
      if (colonMatch != null) {
        role = colonMatch.group(1)!;
        value = colonMatch.group(2)!.trim();
        if (value.isEmpty) value = null;
      } else {
        // Just the role
        final wordMatch = RegExp(r'^(\w+)').firstMatch(remaining);
        if (wordMatch != null) {
          role = wordMatch.group(1)!;
        }
      }
    }

    return SnapshotElement(
      ref: ref ?? 'ref_${line.hashCode}',
      role: role,
      name: name,
      value: value,
      attributes: attributes,
    );
  }
}
