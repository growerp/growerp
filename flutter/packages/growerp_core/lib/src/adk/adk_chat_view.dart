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
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_models/growerp_models.dart';
import '../domains/authenticate/blocs/auth_bloc.dart';
import '../domains/common/bloc/menu_config_bloc.dart';
import '../services/build_dio_client.dart';

/// A single navigable menu entry passed to [AdkChatView].
class ChatMenuEntry {
  final String title;
  final String route;
  /// When set, navigating jumps to this tab index (appended as `?tab=N`).
  final int? tabIndex;
  /// When set, tapping the chip shows this widget in a dialog instead of navigating.
  final WidgetBuilder? dialogBuilder;
  const ChatMenuEntry({
    required this.title,
    required this.route,
    this.tabIndex,
    this.dialogBuilder,
  });
}

/// Chat interface for interacting with the ADK agent backend.
///
/// Communicates with the moqui-adk component's REST API:
///   POST /adk/apps/{app}/users/{uid}/sessions  → create session
///   POST /adk/run_sse                           → streaming agent execution
///   POST /adk/run                               → synchronous agent execution
///
/// Pass [menuItems] so the chat can navigate directly to known app screens.
class AdkChatView extends StatefulWidget {
  final List<ChatMenuEntry> menuItems;
  const AdkChatView({super.key, this.menuItems = const []});

  @override
  State<AdkChatView> createState() => _AdkChatViewState();
}

class _AdkChatViewState extends State<AdkChatView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Msg> _messages = [];

  static const _adkAppName = 'moqui-adk';

  Dio? _dio;
  String _adkUserId = 'anonymous';
  bool _ready = false;
  bool _busy = false;
  String? _sessionId;

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

  // ── Connection / Session ──────────────────────────────────────────────────

  Future<void> _connect() async {
    setState(() => _busy = true);
    _adkUserId = context.read<AuthBloc>().state.authenticate?.user?.userId ?? 'anonymous';
    _dio = await buildDioClient();
    final baseUrl = _dio!.options.baseUrl.replaceAll(RegExp(r'/$'), '');
    _addMsg(_Msg.system('Connecting to ADK agent at $baseUrl/adk …'));

    try {
      // Create a new ADK session
      final response = await _dio!.post<String>(
        '/adk/apps/$_adkAppName/users/$_adkUserId/sessions',
        options: Options(
          contentType: 'application/json',
          responseType: ResponseType.plain,
        ),
      );
      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      _sessionId = data['id']?.toString();

      if (_sessionId == null || _sessionId!.isEmpty) {
        _addMsg(_Msg.error('Failed to create ADK session — no session ID returned.'));
        setState(() => _busy = false);
        return;
      }

      setState(() {
        _ready = true;
        _busy = false;
      });
      _addMsg(
        _Msg.system(
          'Connected to ADK agent — session: $_sessionId\n\n'
          'Type a message to chat with the AI agent.\n'
          'You can also type a screen name to navigate the app.',
        ),
      );
    } on DioException catch (e) {
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      _addMsg(_Msg.error('Connection failed — HTTP ${e.response?.statusCode}: $body'));
      setState(() => _busy = false);
    } catch (e) {
      _addMsg(_Msg.error('Connection failed: $e'));
      setState(() => _busy = false);
    }
  }

  // ── Menu navigation ───────────────────────────────────────────────────────

  /// Flatten MenuItem hierarchy (including children) into ChatMenuEntry list.
  /// Children without a route inherit their parent's route and get a tabIndex.
  List<ChatMenuEntry> _flattenMenuItems(
    List<MenuItem> items,
    String? parentRoute,
  ) {
    final result = <ChatMenuEntry>[];
    for (final item in items) {
      if (!item.isActive) continue;
      final route = item.route ?? parentRoute;
      if (route != null && item.title.isNotEmpty) {
        result.add(ChatMenuEntry(title: item.title, route: route));
      }
      if (item.children != null && item.children!.isNotEmpty) {
        final children = item.children!;
        for (int i = 0; i < children.length; i++) {
          final child = children[i];
          if (!child.isActive) continue;
          if (route != null && child.title.isNotEmpty) {
            result.add(ChatMenuEntry(title: child.title, route: route, tabIndex: i));
          }
        }
      }
    }
    return result;
  }

  /// Effective menu entries: live menu from MenuConfigBloc if available,
  /// else fall back to the static list passed via constructor.
  List<ChatMenuEntry> get _effectiveMenuItems {
    final bloc = context.read<MenuConfigBloc?>();
    final config = bloc?.state.menuConfiguration;
    if (config != null && config.menuItems.isNotEmpty) {
      return _flattenMenuItems(config.menuItems, null);
    }
    return widget.menuItems;
  }

  List<ChatMenuEntry> _matchMenuItems(String query) {
    final q = query.toLowerCase();
    return _effectiveMenuItems
        .where(
          (e) =>
              e.title.toLowerCase().contains(q) ||
              e.route.toLowerCase().contains(q),
        )
        .toList();
  }

  // ── Sending messages ──────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || !_ready || _busy) return;

    _inputController.clear();
    _addMsg(_Msg.user(text));

    // Menu navigation: plain text → check menu items first
    final matches = _matchMenuItems(text);
    if (matches.isNotEmpty) {
      _addMsg(_Msg.nav(matches));
      return;
    }

    setState(() => _busy = true);

    try {
      await _sendSse(text);
    } catch (e) {
      // Fallback to synchronous /run if SSE fails
      try {
        await _sendSync(text);
      } catch (e2) {
        _addMsg(_Msg.error('Error: $e2'));
      }
    }

    setState(() => _busy = false);
  }

  /// Send message via SSE streaming endpoint /adk/run_sse.
  Future<void> _sendSse(String text) async {
    final body = jsonEncode({
      'appName': _adkAppName,
      'userId': _adkUserId,
      'sessionId': _sessionId,
      'newMessage': {
        'role': 'user',
        'parts': [{'text': text}],
      },
    });

    final response = await _dio!.post<ResponseBody>(
      '/adk/run_sse',
      data: body,
      options: Options(
        contentType: 'application/json',
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
    );

    final stream = response.data!.stream;
    final buffer = StringBuffer();
    String agentReply = '';

    // Add a placeholder message for the streaming response
    final msgIndex = _messages.length;
    _addMsg(_Msg.adk('…'));

    await for (final chunk in stream) {
      buffer.write(utf8.decode(chunk));
      final lines = buffer.toString().split('\n');
      buffer.clear();
      // Keep the last incomplete line in the buffer
      if (!buffer.toString().endsWith('\n') && lines.isNotEmpty) {
        buffer.write(lines.removeLast());
      }

      for (final line in lines) {
        if (!line.startsWith('data: ')) continue;
        final payload = line.substring(6).trim();
        if (payload == '[DONE]' || payload.isEmpty) continue;

        try {
          final event = jsonDecode(payload) as Map<String, dynamic>;
          if (event.containsKey('error')) {
            agentReply = '[Error: ${event['error']}]';
            continue;
          }
          final content = event['content'] as Map<String, dynamic>?;
          if (content != null) {
            final parts = content['parts'] as List?;
            if (parts != null) {
              for (final part in parts) {
                if (part is Map && part['text'] != null) {
                  agentReply = part['text'] as String;
                }
              }
            }
          }
        } catch (_) {
          // Skip malformed SSE data
        }
      }

      // Update the streaming message in-place
      if (agentReply.isNotEmpty && msgIndex < _messages.length) {
        setState(() {
          _messages[msgIndex] = _Msg.adk(agentReply);
        });
        _scrollToBottom();
      }
    }

    // Final update
    if (agentReply.isEmpty) {
      setState(() {
        _messages[msgIndex] = _Msg.adk('[No response from agent]');
      });
    }
  }

  /// Fallback: send message via synchronous /adk/run endpoint.
  Future<void> _sendSync(String text) async {
    final body = jsonEncode({
      'appName': _adkAppName,
      'userId': _adkUserId,
      'sessionId': _sessionId,
      'newMessage': {
        'role': 'user',
        'parts': [{'text': text}],
      },
    });

    final response = await _dio!.post<String>(
      '/adk/run',
      data: body,
      options: Options(
        contentType: 'application/json',
        responseType: ResponseType.plain,
      ),
    );

    final events = jsonDecode(response.data!) as List;
    // Find the last event with text content from the agent
    String reply = '';
    for (final event in events.reversed) {
      if (event is Map<String, dynamic>) {
        final content = event['content'] as Map<String, dynamic>?;
        if (content != null) {
          final parts = content['parts'] as List?;
          if (parts != null) {
            for (final part in parts) {
              if (part is Map && part['text'] != null) {
                reply = part['text'] as String;
                break;
              }
            }
          }
          if (reply.isNotEmpty) break;
        }
      }
    }
    _addMsg(_Msg.adk(reply.isEmpty ? '[No response from agent]' : reply));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _addMsg(_Msg msg) {
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

enum _MsgKind { user, adk, system, error, nav }

class _Msg {
  const _Msg.user(this.text) : kind = _MsgKind.user, navItems = null;
  const _Msg.adk(this.text) : kind = _MsgKind.adk, navItems = null;
  const _Msg.system(this.text) : kind = _MsgKind.system, navItems = null;
  const _Msg.error(this.text) : kind = _MsgKind.error, navItems = null;
  const _Msg.nav(List<ChatMenuEntry> items)
    : kind = _MsgKind.nav,
      text = '',
      navItems = items;

  final _MsgKind kind;
  final String text;
  final List<ChatMenuEntry>? navItems;
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
      case _MsgKind.adk:
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
                      ? 'Ask the AI agent anything…'
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
