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
import 'package:growerp_core/growerp_core.dart';

/// A single navigable menu entry passed to [AdkChatView].
class ChatMenuEntry {
  final String title;
  final String route;
  /// When set, navigating jumps to this tab index (appended as `?tab=N`).
  final int? tabIndex;
  /// When set, tapping the chip shows this widget in a dialog instead of navigating.
  final WidgetBuilder? dialogBuilder;

  /// `navigate` (go to [route]) or `dialog` (show [registryWidget] in a dialog).
  /// Plain menu matches use `navigate`.
  final String action;

  /// Registry widget name to render (used by `dialog`, and passed along on
  /// `navigate` so the destination route's widget can act on it).
  final String? registryWidget;

  /// Extra parameters forwarded as the route query string (navigate) or as the
  /// widget args (dialog) — e.g. `{openNew: true}`, `{finDocId: ..., presetStatus: ...}`.
  final Map<String, dynamic>? params;

  const ChatMenuEntry({
    required this.title,
    required this.route,
    this.tabIndex,
    this.dialogBuilder,
    this.action = 'navigate',
    this.registryWidget,
    this.params,
  });

  /// Build a [ChatMenuEntry] from an agent `growerp-action` directive object.
  /// Returns null when the directive is malformed.
  static ChatMenuEntry? fromDirective(Map<String, dynamic> d) {
    final action = (d['action'] as String?)?.toLowerCase() ?? 'navigate';
    final route = d['route'] as String?;
    final widget = d['widget'] as String?;
    final label = (d['label'] as String?) ??
        (d['title'] as String?) ??
        widget ??
        route ??
        'Open';
    final params = (d['params'] is Map)
        ? (d['params'] as Map).map((k, v) => MapEntry(k.toString(), v))
        : null;
    final tab = d['tab'] is int
        ? d['tab'] as int
        : int.tryParse(d['tab']?.toString() ?? '');
    if (action == 'dialog') {
      if (widget == null) return null;
      return ChatMenuEntry(
        title: label,
        route: route ?? '',
        action: 'dialog',
        registryWidget: widget,
        params: params,
      );
    }
    // navigate — route may be omitted; the client resolves it from the widget
    // name via the menu. Require at least one of route/widget.
    if (route == null && widget == null) return null;
    return ChatMenuEntry(
      title: label,
      route: route ?? '',
      tabIndex: tab,
      registryWidget: widget,
      params: params,
    );
  }
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
  final _inputFocus = FocusNode();
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
    // Surface failed record lookups (AsyncRecordDialog) as chat text instead of
    // a popped "not found" screen.
    AsyncRecordDialog.messageSink = (message) {
      if (mounted) _addMsg(_Msg.error(message));
    };
    _connect();
  }

  @override
  void dispose() {
    AsyncRecordDialog.messageSink = null;
    _inputController.dispose();
    _inputFocus.dispose();
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
      // Create a new ADK session, seeding it with the running app's screen
      // catalog so the agent can emit navigation/dialog directives by name.
      final response = await _dio!.post<String>(
        '/adk/apps/$_adkAppName/users/$_adkUserId/sessions',
        data: jsonEncode({
          'state': {
            'screenCatalog': WidgetRegistry.getWidgetCatalog(),
            'currentUserId': _adkUserId,
          },
        }),
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
      // Put the cursor in the input field once the chat is ready.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _inputFocus.requestFocus();
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
      if (_isMissingKeyError(body)) {
        _addSetupNeeded();
      } else {
        _addMsg(_Msg.error('Connection failed — HTTP ${e.response?.statusCode}: $body'));
      }
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
    bool missingKey = false;

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
            final err = event['error']?.toString();
            if (_isMissingKeyError(err)) {
              missingKey = true;
              agentReply = '';
            } else {
              agentReply = '[Error: $err]';
            }
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

      // Update the streaming message in-place (hide any action block while it streams)
      if (agentReply.isNotEmpty && msgIndex < _messages.length) {
        setState(() {
          _messages[msgIndex] = _Msg.adk(_stripActions(agentReply));
        });
        _scrollToBottom();
      }
    }

    // Final update
    if (missingKey) {
      // Drop the streaming placeholder and offer to open System Setup.
      setState(() => _messages.removeAt(msgIndex));
      _addSetupNeeded();
      return;
    }
    if (agentReply.isEmpty) {
      setState(() {
        _messages[msgIndex] = _Msg.adk('[No response from agent]');
      });
      return;
    }
    final cleaned = _stripActions(agentReply);
    final actions = _parseActions(agentReply);
    setState(() {
      _messages[msgIndex] = _Msg.adk(cleaned.isNotEmpty
          ? cleaned
          : (actions.isEmpty ? '[No response from agent]' : 'Opening the requested screen…'));
    });
    _emitActions(cleaned, actions);
  }

  /// Render action chips and, for a single pure-directive reply, auto-run it so
  /// the screen opens without an extra tap.
  void _emitActions(String cleanedText, List<ChatMenuEntry> actions) {
    if (actions.isEmpty) return;
    _addMsg(_Msg.nav(actions));
    if (cleanedText.isEmpty && actions.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runAction(actions.first);
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
        if (event.containsKey('error') &&
            _isMissingKeyError(event['error']?.toString())) {
          _addSetupNeeded();
          return;
        }
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
    if (reply.isEmpty) {
      _addMsg(_Msg.adk('[No response from agent]'));
      return;
    }
    final cleaned = _stripActions(reply);
    final actions = _parseActions(reply);
    _addMsg(_Msg.adk(cleaned.isNotEmpty
        ? cleaned
        : (actions.isEmpty ? '[No response from agent]' : 'Opening the requested screen…')));
    _emitActions(cleaned, actions);
  }

  // ── Action directives ─────────────────────────────────────────────────────

  /// Matches a fenced ```growerp-action … ``` block in an agent reply.
  static final _actionBlock = RegExp(
    r'```growerp-action\s*([\s\S]*?)```',
    multiLine: true,
  );

  /// Strip any `growerp-action` block(s) from text for display.
  String _stripActions(String text) =>
      text.replaceAll(_actionBlock, '').trimRight();

  /// Parse `growerp-action` block(s) into navigable entries. Each block holds a
  /// single JSON object or an array of objects.
  List<ChatMenuEntry> _parseActions(String text) {
    final result = <ChatMenuEntry>[];
    for (final m in _actionBlock.allMatches(text)) {
      final raw = m.group(1)?.trim();
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        final list = decoded is List ? decoded : [decoded];
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final entry = ChatMenuEntry.fromDirective(item);
            if (entry != null) result.add(entry);
          }
        }
      } catch (_) {
        // Ignore malformed directive blocks.
      }
    }
    return result;
  }

  /// Resolve a route (and tab index) for a widget name from the live menu.
  /// Searches top-level items and their children (children map to ?tab=index).
  ({String route, int? tab})? _routeForWidget(String widget) {
    final bloc = context.read<MenuConfigBloc?>();
    final items = bloc?.state.menuConfiguration?.menuItems;
    if (items == null) return null;
    for (final item in items) {
      if (!item.isActive) continue;
      if (item.widgetName == widget && (item.route?.isNotEmpty ?? false)) {
        return (route: item.route!, tab: null);
      }
      final children = item.children;
      if (children != null) {
        for (int i = 0; i < children.length; i++) {
          final c = children[i];
          if (c.isActive && c.widgetName == widget) {
            final route = c.route ?? item.route;
            if (route != null && route.isNotEmpty) return (route: route, tab: i);
          }
        }
      }
    }
    return null;
  }

  /// Execute an agent action entry: navigate to a route or show a widget/dialog.
  ///
  /// Navigation closes the chat overlay first (otherwise it would cover the
  /// target screen). Dialog actions keep the chat open and stack the dialog on
  /// top, so a failed record lookup can fall back to a chat message
  /// (see [AsyncRecordDialog.messageSink]).
  void _runAction(ChatMenuEntry e) {
    final query = <String, String>{};
    e.params?.forEach((k, v) {
      if (v != null) query[k] = v.toString();
    });

    // Resolve navigation target up front (reads MenuConfigBloc from this context).
    String route = e.route;
    int? tab = e.tabIndex;
    if (route.isEmpty && e.registryWidget != null) {
      final resolved = _routeForWidget(e.registryWidget!);
      if (resolved != null) {
        route = resolved.route;
        tab ??= resolved.tab;
      }
    }

    final router = GoRouter.of(context);
    final rootNav = Navigator.of(context, rootNavigator: true);

    void openInDialog(WidgetBuilder builder) {
      showDialog(context: rootNav.context, builder: builder);
    }

    if (e.dialogBuilder != null) {
      openInDialog(e.dialogBuilder!);
      return;
    }

    // Explicit dialog action, or navigate with no resolvable route: open the
    // widget directly in a dialog (kept on top of the chat).
    if ((e.action == 'dialog' || route.isEmpty) && e.registryWidget != null) {
      openInDialog((_) {
        final w = WidgetRegistry.getWidget(e.registryWidget!, e.params);
        // Entity dialogs (and the fetch wrappers ShowXxxDialog / AsyncRecordDialog)
        // render their own Dialog — show as-is. Wrap only bare content (e.g. a list).
        final isDialogLike = w is Dialog ||
            w is AlertDialog ||
            w.runtimeType.toString().endsWith('Dialog');
        return isDialogLike ? w : Dialog(child: w);
      });
      return;
    }

    if (route.isEmpty) return;
    // Navigation: close the chat overlay so the target screen is visible.
    if (rootNav.canPop()) rootNav.pop();
    if (tab != null) query['tab'] = tab.toString();
    final uri = Uri(path: route, queryParameters: query.isEmpty ? null : query);
    router.go(uri.toString());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _addMsg(_Msg msg) {
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  /// True when a backend error means no usable LLM API key is configured
  /// (missing, or rejected by the provider).
  bool _isMissingKeyError(String? t) {
    final s = (t ?? '').toLowerCase();
    return s.contains('not configured') ||
        s.contains('api key') ||
        s.contains('api_key') ||
        s.contains('permission denied') ||
        s.contains('unauthenticated');
  }

  /// Prompt the user to add an LLM key, with a chip that opens System Setup as a
  /// dialog on top of the chat (so they can save a key and retry inline).
  void _addSetupNeeded() {
    _addMsg(_Msg.error(
        'No AI key configured. Add an LLM API key in System Setup, then retry.'));
    _addMsg(_Msg.nav([
      ChatMenuEntry(
        title: 'Open System Setup',
        route: '',
        action: 'dialog',
        dialogBuilder: (_) => const Dialog(child: SystemSetupDialog(inDialog: true)),
      ),
    ]));
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
            itemBuilder: (_, i) => _Bubble(msg: _messages[i], onAction: _runAction),
          ),
        ),
        _InputBar(
          controller: _inputController,
          focusNode: _inputFocus,
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
  const _Bubble({required this.msg, this.onAction});
  final _Msg msg;
  final void Function(ChatMenuEntry)? onAction;

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
                      onPressed: () => onAction?.call(e),
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
    required this.focusNode,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
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
                focusNode: focusNode,
                autofocus: true,
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
