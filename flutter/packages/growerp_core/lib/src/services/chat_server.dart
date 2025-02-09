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

import 'package:flutter/foundation.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io' show Platform;

class ChatServer {
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

  ChatServer() {
    if (kReleaseMode) {
      chatUrl = GlobalConfiguration().get("chatUrl");
    } else {
      chatUrl = GlobalConfiguration().get("chatUrlDebug");
      if (chatUrl.isEmpty) {
        if (kIsWeb || Platform.isIOS || Platform.isLinux) {
          chatUrl = 'ws://localhost:8081';
//        chatUrl = 'ws://localhost:8080/notws';
        } else if (Platform.isAndroid) {
          chatUrl = 'ws://10.0.2.2:8081';
//        chatUrl = 'ws://10.0.2.2:8080/notws';
        }
      }
    }
    logger.i('Using base chat backend url: $chatUrl');
  }

  connect(String apiKey, String userId) {
    logger.i("WS connect url/userId/apikey: $chatUrl/$userId/$apiKey");
    channel = WebSocketChannel.connect(Uri.parse('$chatUrl/$userId/$apiKey'));
    streamController = StreamController.broadcast()..addStream(channel.stream);
  }

  send(String message) {
    debugPrint("WS send message: $message");
    channel.sink.add(message);
  }

  stream() {
    return streamController.stream;
  }

  close() {
    channel.sink.close();
    streamController.close();
  }
}
