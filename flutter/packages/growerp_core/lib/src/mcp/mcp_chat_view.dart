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

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_models/growerp_models.dart';
import '../domains/common/bloc/menu_config_bloc.dart';
import '../services/build_dio_client.dart';

/// A single navigable menu entry passed to [McpChatView].
class McpMenuEntry {
  final String title;
  final String route;
  /// When set, navigating jumps to this tab index (appended as `?tab=N`).
  final int? tabIndex;
  /// When set, tapping the chip shows this widget in a dialog instead of navigating.
  final WidgetBuilder? dialogBuilder;
  const McpMenuEntry({
    required this.title,
    required this.route,
    this.tabIndex,
    this.dialogBuilder,
  });
}

/// Chat interface for interacting with the backend MCP server.
///
/// Usage:
///   `svc <query>`    → moqui_search_services tool
///   `svc! <name>`    → moqui_get_service_details tool
///   any other text   → match [menuItems] first, then moqui_search_services
///
/// Pass [menuItems] so the chat can navigate directly to known app screens.
/// Protocol: JSON-RPC 2.0 over POST /mcp (no SSE required).
class McpChatView extends StatefulWidget {
  final List<McpMenuEntry> menuItems;
  const McpChatView({super.key, this.menuItems = const []});

  @override
  State<McpChatView> createState() => _McpChatViewState();
}

class _McpChatViewState extends State<McpChatView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Msg> _messages = [];

  String? _sessionId;
  Dio? _dio;
  bool _ready = false;
  bool _busy = false;
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Options get _mcpOptions => Options(
    headers: {
      'Accept': 'application/json, text/event-stream',
      'Mcp-Session-Id': ?_sessionId,
    },
    contentType: 'application/json',
  );

  void _captureSessionId(Response response) {
    final sid = response.headers['mcp-session-id']?.first;
    if (sid != null && sid.isNotEmpty) _sessionId = sid;
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    _dio = await buildDioClient();
    final baseUrl = _dio!.options.baseUrl.replaceAll(RegExp(r'/$'), '');

    _addMsg(_Msg.system('Connecting to $baseUrl/mcp …'));

    // 1. initialize
    final initResult = await _rpc('initialize', {
      'protocolVersion': '2025-06-18',
      'capabilities': {},
      'clientInfo': {'name': 'GrowERP Flutter MCP Chat', 'version': '1.0'},
    });
    if (initResult == null) {
      setState(() => _busy = false);
      return;
    }

    // 2. notifications/initialized (no id → notification, not request)
    await _notify('notifications/initialized', {});

    setState(() {
      _ready = true;
      _busy = false;
    });
    _addMsg(
      _Msg.system(
        'Connected — session: $_sessionId\n\n'
        'any text              → navigate app screens or search services\n'
        'svc <query>           → search services (e.g. svc product)\n'
        'svc! <name>           → service details (e.g. svc! CatalogServices.get#Product)\n'
        'exec! <name> {json}   → run service (e.g. exec! CatalogServices.get#Product {"pseudoId":"10000"})',
      ),
    );
  }

  /// Send a JSON-RPC request and return its result map (or null on error).
  Future<Map<String, dynamic>?> _rpc(
    String method,
    Map<String, dynamic> params,
  ) async {
    final id = _nextId++;
    try {
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      });
      final response = await _dio!.post<String>(
        '/mcp',
        data: body,
        options: _mcpOptions,
      );
      _captureSessionId(response);

      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      if (data['error'] != null) {
        final err = data['error'] as Map<String, dynamic>;
        _addMsg(_Msg.error(err['message']?.toString() ?? 'RPC error'));
        return null;
      }
      return data['result'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      _addMsg(_Msg.error('HTTP ${e.response?.statusCode}: $body'));
      return null;
    } catch (e) {
      _addMsg(_Msg.error(e.toString()));
      return null;
    }
  }

  /// Send a JSON-RPC notification (no id, no response expected).
  Future<void> _notify(String method, Map<String, dynamic> params) async {
    try {
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'method': method,
        'params': params,
      });
      final response = await _dio!.post<String>(
        '/mcp',
        data: body,
        options: _mcpOptions,
      );
      _captureSessionId(response);
    } catch (_) {}
  }

  /// Flatten MenuItem hierarchy (including children) into McpMenuEntry list.
  /// Children without a route inherit their parent's route and get a tabIndex.
  List<McpMenuEntry> _flattenMenuItems(
    List<MenuItem> items,
    String? parentRoute,
  ) {
    final result = <McpMenuEntry>[];
    for (final item in items) {
      if (!item.isActive) continue;
      final route = item.route ?? parentRoute;
      if (route != null && item.title.isNotEmpty) {
        result.add(McpMenuEntry(title: item.title, route: route));
      }
      if (item.children != null && item.children!.isNotEmpty) {
        final children = item.children!;
        for (int i = 0; i < children.length; i++) {
          final child = children[i];
          if (!child.isActive) continue;
          if (route != null && child.title.isNotEmpty) {
            result.add(McpMenuEntry(title: child.title, route: route, tabIndex: i));
          }
        }
      }
    }
    return result;
  }

  /// Effective menu entries: live menu from MenuConfigBloc if available,
  /// else fall back to the static list passed via constructor.
  List<McpMenuEntry> get _effectiveMenuItems {
    final bloc = context.read<MenuConfigBloc?>();
    final config = bloc?.state.menuConfiguration;
    if (config != null && config.menuItems.isNotEmpty) {
      return _flattenMenuItems(config.menuItems, null);
    }
    return widget.menuItems;
  }

  List<McpMenuEntry> _matchMenuItems(String query) {
    final q = query.toLowerCase();
    return _effectiveMenuItems
        .where(
          (e) =>
              e.title.toLowerCase().contains(q) ||
              e.route.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || !_ready || _busy) return;

    _inputController.clear();
    _addMsg(_Msg.user(text));
    setState(() => _busy = true);

    // Menu navigation: plain text (no prefix) → check menu items first
    if (!text.startsWith('/') && !text.startsWith('svc') && !text.startsWith('exec!')) {
      final matches = _matchMenuItems(text);
      if (matches.isNotEmpty) {
        setState(() => _busy = false);
        _addMsg(_Msg.nav(matches));
        return;
      }
    }

    String toolName;
    Map<String, dynamic> args;

    if (text.startsWith('exec! ')) {
      final rest = text.substring(6).trim();
      // Split on first whitespace: "ServiceName.verb#noun {json}"
      final spaceIdx = rest.indexOf(' ');
      final shortName = spaceIdx > 0 ? rest.substring(0, spaceIdx) : rest;
      final jsonPart = spaceIdx > 0 ? rest.substring(spaceIdx + 1).trim() : '{}';
      Map<String, dynamic> params = {};
      try { params = jsonDecode(jsonPart) as Map<String, dynamic>; } catch (_) {}
      toolName = 'moqui_execute_service';
      args = {'serviceName': _expandServiceName(shortName), 'parameters': params};
    } else if (text.startsWith('svc! ')) {
      toolName = 'moqui_get_service_details';
      args = {'serviceName': _expandServiceName(text.substring(5).trim())};
    } else if (text.startsWith('svc ')) {
      toolName = 'moqui_search_services';
      args = {'query': text.substring(4).trim()};
    } else {
      toolName = 'moqui_search_services';
      args = {'query': text};
    }

    final result = await _rpc('tools/call', {
      'name': toolName,
      'arguments': args,
    });

    setState(() => _busy = false);

    if (result == null) return;

    final content = result['content'];
    String reply;
    if (content is List && content.isNotEmpty) {
      reply = content
          .map(
            (c) => c is Map
                ? _formatMcpText(c['text']?.toString() ?? '')
                : c.toString(),
          )
          .join('\n')
          .trim();
    } else {
      reply = const JsonEncoder.withIndent('  ').convert(result);
    }
    _addMsg(_Msg.mcp(reply.isEmpty ? '(empty response)' : reply));
  }

  /// Expand short service name to full Moqui name.
  /// e.g. "CatalogServices.get#Product" → "growerp.100.CatalogServices100.get#Product"
  /// Already-full names (starting with "growerp.") are returned as-is.
  String _expandServiceName(String name) {
    if (name.startsWith('growerp.')) return name;
    return name.replaceFirstMapped(
      RegExp(r'^([A-Za-z]+)\.'),
      (m) => 'growerp.100.${m[1]}100.',
    );
  }

  /// Strip growerp version prefix from service names for display.
  /// e.g. "growerp.100.PartyServices100.get#Company" → "PartyServices.get#Company"
  String _shortServiceName(String name) {
    // Remove "growerp.NNN." prefix
    final noPrefix = name.replaceFirst(RegExp(r'^growerp\.\d+\.'), '');
    // Remove trailing digits from class part before the verb separator
    // e.g. "PartyServices100.get#X" → "PartyServices.get#X"
    return noPrefix.replaceFirstMapped(
      RegExp(r'^([A-Za-z]+)\d+\.'),
      (m) => '${m[1]}.',
    );
  }

  String _formatMcpText(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        // Screen/service search results
        final matches = decoded['matches'];
        if (matches is List && matches.isNotEmpty) {
          final buf = StringBuffer();
          for (final m in matches) {
            if (m is Map<String, dynamic>) {
              buf.writeln('• ${m['name'] ?? ''}');
              buf.writeln('  Path: ${m['path'] ?? ''}');
              if (m['description'] != null &&
                  (m['description'] as String).isNotEmpty) {
                buf.writeln('  ${m['description']}');
              }
              buf.writeln();
            }
          }
          return buf.toString().trimRight();
        }
        // Service search results
        final services = decoded['services'];
        if (services is List && services.isNotEmpty) {
          final total = decoded['total'];
          final hint = decoded['hint'];
          final buf = StringBuffer();
          if (total != null) buf.writeln('Found $total service(s):\n');
          for (final s in services) {
            if (s is Map<String, dynamic>) {
              buf.writeln('• ${_shortServiceName(s['name'] as String? ?? '')}');
              if (s['description'] != null) {
                buf.writeln('  ${s['description']}');
              }
              if (s['required'] is List && (s['required'] as List).isNotEmpty) {
                buf.writeln(
                  '  Required: ${(s['required'] as List).join(', ')}',
                );
              }
              if (s['optional'] is List && (s['optional'] as List).isNotEmpty) {
                buf.writeln(
                  '  Optional: ${(s['optional'] as List).join(', ')}',
                );
              }
              buf.writeln();
            }
          }
          if (hint != null) buf.writeln(hint);
          return buf.toString().trimRight();
        }
        // Service details result
        if (decoded.containsKey('inParameters')) {
          final buf = StringBuffer();
          if (decoded['service'] != null) {
            buf.writeln('Service: ${_shortServiceName(decoded['service'] as String)}');
          }
          if (decoded['description'] != null) {
            buf.writeln('${decoded['description']}\n');
          }
          final inP = decoded['inParameters'] as Map<String, dynamic>?;
          if (inP != null && inP.isNotEmpty) {
            buf.writeln('Input parameters:');
            inP.forEach((name, info) {
              final i = info as Map<String, dynamic>;
              final req = i['required'] == true ? ' (required)' : '';
              buf.writeln('  $name [${i['type'] ?? 'String'}]$req');
              if (i['description'] != null) {
                buf.writeln('    ${i['description']}');
              }
            });
          }
          final outP = decoded['outParameters'] as Map<String, dynamic>?;
          if (outP != null && outP.isNotEmpty) {
            buf.writeln('\nOutput parameters:');
            outP.forEach((name, info) {
              final i = info as Map<String, dynamic>;
              buf.writeln('  $name [${i['type'] ?? 'String'}]');
              if (i['description'] != null) {
                buf.writeln('    ${i['description']}');
              }
            });
          }
          return buf.toString().trimRight();
        }
        // Generic map — pretty print
        return decoded.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      }
    } catch (_) {}
    return raw;
  }

  void _addMsg(_Msg msg) {
    setState(() => _messages.add(msg));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: _messages.length,
            itemBuilder: (_, i) => _Bubble(msg: _messages[i]),
          ),
        ),
        _InputBar(
          controller: _inputController,
          enabled: _ready && !_busy,
          onSend: _send,
        ),
      ],
    );
  }
}

// ─── Data ────────────────────────────────────────────────────────────────────

enum _MsgKind { user, mcp, system, error, nav }

class _Msg {
  const _Msg.user(this.text) : kind = _MsgKind.user, navItems = null;
  const _Msg.mcp(this.text) : kind = _MsgKind.mcp, navItems = null;
  const _Msg.system(this.text) : kind = _MsgKind.system, navItems = null;
  const _Msg.error(this.text) : kind = _MsgKind.error, navItems = null;
  const _Msg.nav(List<McpMenuEntry> items)
    : kind = _MsgKind.nav,
      text = '',
      navItems = items;

  final _MsgKind kind;
  final String text;
  final List<McpMenuEntry>? navItems;
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = msg.kind == _MsgKind.user;

    // Nav bubbles render as a list of tappable chips — handle separately
    if (msg.kind == _MsgKind.nav) {
      final items = msg.navItems ?? [];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: cs.secondaryContainer,
                  child: Icon(
                    Icons.menu_open,
                    size: 14,
                    color: cs.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Open screen:',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: items
                  .map(
                    (e) => ActionChip(
                      label: Text(e.title),
                      avatar: const Icon(Icons.open_in_new, size: 14),
                      onPressed: () {
                        if (e.dialogBuilder != null) {
                          showDialog(
                            context: context,
                            builder: e.dialogBuilder!,
                          );
                        } else {
                          final route = e.tabIndex != null
                              ? '${e.route}?tab=${e.tabIndex}'
                              : e.route;
                          context.go(route);
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    }

    Color bg;
    Color fg;
    IconData icon;
    switch (msg.kind) {
      case _MsgKind.user:
        bg = cs.primary;
        fg = cs.onPrimary;
        icon = Icons.person;
      case _MsgKind.mcp:
        bg = cs.secondaryContainer;
        fg = cs.onSecondaryContainer;
        icon = Icons.smart_toy;
      case _MsgKind.error:
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        icon = Icons.error_outline;
      case _MsgKind.system:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurfaceVariant;
        icon = Icons.info_outline;
      case _MsgKind.nav:
        // handled above
        bg = cs.secondaryContainer;
        fg = cs.onSecondaryContainer;
        icon = Icons.menu_open;
    }

    final avatar = CircleAvatar(
      radius: 14,
      backgroundColor: bg,
      child: Icon(icon, size: 14, color: fg),
    );

    final bubble = Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 12),
          ),
        ),
        child: SelectableText(
          msg.text,
          style: TextStyle(color: fg, fontSize: 13),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isUser
            ? [bubble, const SizedBox(width: 6), avatar]
            : [avatar, const SizedBox(width: 6), bubble],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: enabled
                      ? 'screen name · svc <query> · svc! <name>'
                      : 'Connecting…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
