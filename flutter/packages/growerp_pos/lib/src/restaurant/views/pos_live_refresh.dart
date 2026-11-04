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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';

/// Keeps a kitchen or floor screen current: a fetch on every signal from the
/// backend, and a poll because a signal can get lost.
mixin PosLiveRefresh<T extends StatefulWidget> on State<T> {
  static const _poll = Duration(seconds: 15);
  StreamSubscription? _signals;
  Timer? _timer;

  void onRefresh();

  void startRefresh() {
    _timer = Timer.periodic(_poll, (_) => onRefresh());
    _signals = _signalStream()?.listen((data) {
      try {
        if (jsonDecode(data)['topic'] == 'posKitchen') onRefresh();
      } on FormatException {
        // not a notification
      }
    });
  }

  Stream<dynamic>? _signalStream() {
    try {
      return context.read<NotificationBloc>().notificationClient.stream();
    } on ProviderNotFoundException {
      return null;
    }
  }

  void stopRefresh() {
    _timer?.cancel();
    _signals?.cancel();
  }
}
