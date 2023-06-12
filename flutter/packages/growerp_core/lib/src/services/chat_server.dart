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
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io' show Platform;

class ChatServer {
  late WebSocketChannel channel;
  late String chatUrl;
  late StreamController streamController;

  ChatServer() {
    if (kReleaseMode) {
      chatUrl = GlobalConfiguration().get("chatUrl");
    } else if (kIsWeb || Platform.isIOS || Platform.isLinux) {
      chatUrl = GlobalConfiguration().get("chatUrlDebug");
      if (chatUrl.isEmpty) {
        chatUrl = 'ws://localhost:8081';
      }
    } else if (Platform.isAndroid) {
      chatUrl = 'ws://10.0.2.2:8081';
    }
    debugPrint('Using base chat backend url: $chatUrl');
  }

  connect(String apiKey, String userId) {
    debugPrint("WS connect url/userId/apikey: $chatUrl/$userId/$apiKey");
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
