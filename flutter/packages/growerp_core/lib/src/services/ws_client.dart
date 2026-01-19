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

class WsClient {
  WebSocketChannel? _channel;
  late String wsUrl;
  StreamController? _streamController;

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
    if (kReleaseMode) {
      wsUrl = GlobalConfiguration().get("chatUrl");
    } else {
      wsUrl = GlobalConfiguration().get("chatUrlDebug");
      if (wsUrl.isEmpty) {
        if (kIsWeb || Platform.isIOS || Platform.isMacOS || Platform.isLinux) {
          wsUrl = 'ws://localhost:$_backendPort/$path';
        } else if (Platform.isAndroid) {
          wsUrl = 'ws://10.0.2.2:$_backendPort/$path';
        }
      }
    }
    logger.i('Using base websocket backend url: $wsUrl with path: $path');
  }

  Future<void> connect(String apiKey, String userId) async {
    try {
      logger.i("WS connect $wsUrl");
      _channel = WebSocketChannel.connect(
        Uri.parse("$wsUrl?apiKey=$apiKey&userId=$userId"),
      );

      //await channel.ready;
    } catch (error) {
      if (error is WebSocketChannelException) {
        if (error.inner != null) {
          final err = error.inner as dynamic;
          logger.e('Websocket inner error: ${err.message.toString()}');
        }
        logger.e('Websocket error: ${error.message}');
      }
    }
    _streamController = StreamController.broadcast()
      ..addStream(_channel!.stream);
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
    return _streamController!.stream;
  }

  void close() {
    _channel?.sink.close(status.normalClosure);
    _streamController?.close();
  }
}
