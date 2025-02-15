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
import 'dart:io' show Platform;

class WsServer {
  late WebSocketChannel channel;
  late String chatUrl;
  late StreamController streamController;

  var logger = Logger(
    filter: null, // Use the default LogFilter (-> only log in debug mode)
    printer: PrettyPrinter(
        lineLength: 133,
        methodCount: 0), // Use the PrettyPrinter to format and print log
    output: null, // Use the default LogOutput (-> send everything to console)
  );

  WsServer(String path) {
    if (kReleaseMode) {
      chatUrl = GlobalConfiguration().get("chatUrl");
    } else {
      chatUrl = GlobalConfiguration().get("chatUrlDebug");
      if (chatUrl.isEmpty) {
        if (kIsWeb || Platform.isIOS || Platform.isLinux) {
          chatUrl = 'ws://localhost:8080/$path';
        } else if (Platform.isAndroid) {
          chatUrl = 'ws://10.0.2.2:8080/$path';
        }
      }
    }
    logger.i('Using base websocket backend url: $chatUrl/$path');
  }

  connect(String apiKey, String userId) async {
    logger.i("WS connect $chatUrl");
    channel = WebSocketChannel.connect(
        Uri.parse("$chatUrl?apiKey=$apiKey&userId=$userId"));
    await channel.ready;
    streamController = StreamController.broadcast()..addStream(channel.stream);
  }

  send(ChatMessage message) {
    debugPrint("Send message: $message");
    const JsonEncoder encoder = JsonEncoder();
    channel.sink.add(encoder.convert(message.toJson()));
  }

  stream() {
    return streamController.stream;
  }

  close() {
    channel.sink.close();
    streamController.close();
  }
}
