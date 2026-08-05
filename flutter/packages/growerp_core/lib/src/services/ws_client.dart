/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:io' show Platform;

/// Backend port can be overridden at compile time using:
/// --dart-define=BACKEND_PORT=8080
const String _backendPort = String.fromEnvironment(
  'BACKEND_PORT',
  defaultValue: '8080',
);

/// Full chat/WebSocket URL override at compile time. When set, this takes
/// highest priority over all other URL resolution logic.
/// Usage: --dart-define=CHAT_URL=ws://moqui
const String _chatUrlDefine = String.fromEnvironment('CHAT_URL');

class WsClient {
  WebSocketChannel? _channel;
  late String wsUrl;
  // one controller for the life of the client: subscribers keep working over a
  // reconnect, so a backend restart does not silently kill chat notifications
  final StreamController _streamController = StreamController.broadcast();
  String? _apiKey;
  String? _userId;
  bool _closedByUser = false;
  Timer? _reconnectTimer;

  bool get isConnected => _channel != null;

  var logger = Logger(
    filter: null, // Use the default LogFilter (-> only log in debug mode)
    printer: PrettyPrinter(
      lineLength: 133,
      methodCount: 0,
    ), // Use the PrettyPrinter to format and print log
    output: null, // Use the default LogOutput (-> send everything to console)
  );

  WsClient(String path) {
    String? baseUrl;
    if (_chatUrlDefine.isNotEmpty) {
      // Compile-time --dart-define=CHAT_URL takes highest priority.
      baseUrl = _chatUrlDefine;
    } else if (kReleaseMode) {
      baseUrl = GlobalConfiguration().get("chatUrl");
    } else {
      baseUrl = GlobalConfiguration().get("chatUrlDebug");
      if (baseUrl == null || baseUrl.isEmpty) {
        if (kIsWeb || Platform.isIOS || Platform.isMacOS || Platform.isLinux) {
          baseUrl = 'ws://localhost:$_backendPort';
        } else if (Platform.isAndroid) {
          baseUrl = 'ws://10.0.2.2:$_backendPort';
        }
      } else if (Platform.isAndroid) {
        // On Android emulators, 'localhost' refers to the emulator's own
        // loopback. Translate it to 10.0.2.2 to reach the host machine.
        baseUrl = baseUrl.replaceAll('localhost', '10.0.2.2');
      }
    }
    // Fallback if still empty or null
    if (baseUrl == null || baseUrl.isEmpty) {
      baseUrl = 'wss://backend.growerp.com';
    }
    // Ensure no double slashes and add path
    if (baseUrl.endsWith('/')) {
      wsUrl = "$baseUrl$path";
    } else {
      wsUrl = "$baseUrl/$path";
    }
    logger.i('Using base websocket backend url: $wsUrl with path: $path');
  }

  Future<void> connect(String apiKey, String userId) async {
    _apiKey = apiKey;
    _userId = userId;
    _closedByUser = false;
    _reconnectTimer?.cancel();
    // Close previous connection gracefully; ignore errors (connection may already be dead).
    try { _channel?.sink.close(status.normalClosure); } catch (_) {}
    _channel = null;

    try {
      logger.i("WS connect $wsUrl");
      _channel = WebSocketChannel.connect(
        Uri.parse("$wsUrl?api_key=$apiKey&userId=$userId"),
      );
      await _channel!.ready;
    } catch (error) {
      if (error is WebSocketChannelException) {
        if (error.inner != null) {
          final err = error.inner as dynamic;
          logger.e('Websocket inner error: ${err.message.toString()}');
        }
        logger.e('Websocket error: ${error.message}');
      } else {
        logger.e('Websocket connect error: $error');
      }
      _channel = null;
      _scheduleReconnect();
      return;
    }
    _channel!.stream.listen(
      (data) => _streamController.add(data),
      onError: (e) {
        logger.w('Websocket stream error: $e');
        _scheduleReconnect();
      },
      onDone: () {
        logger.i('Websocket closed, reconnecting');
        _scheduleReconnect();
      },
      cancelOnError: true,
    );
  }

  /// Reconnect after a backend restart or a dropped connection; without this the
  /// app keeps a dead socket and never receives chat messages again.
  void _scheduleReconnect() {
    _channel = null;
    if (_closedByUser || _apiKey == null || _userId == null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect(_apiKey!, _userId!);
    });
  }

  void send(Object message) {
    if (_channel == null) {
      logger.w("Cannot send message - WebSocket not connected yet: $message");
      return;
    }

    String out;
    debugPrint("Send message: $message");
    if (message is ChatMessage) {
      const JsonEncoder encoder = JsonEncoder();
      out = encoder.convert(message.toJson());
    } else {
      out = message as String;
    }
    _channel!.sink.add(out);
  }

  Stream<dynamic> stream() {
    return _streamController.stream;
  }

  void close() {
    _closedByUser = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.normalClosure);
    _channel = null;
  }
}
