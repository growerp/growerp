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

part of 'pos_tab_bloc.dart';

enum PosTabStatus { initial, loading, success, split, closed, failure }

class PosTabState extends Equatable {
  const PosTabState({
    this.status = PosTabStatus.initial,
    this.tab,
    this.shares = const <PosShare>[],
    this.message,
  });

  final PosTabStatus status;
  final PosTab? tab;
  final List<PosShare> shares;
  final String? message;

  PosTabState copyWith({
    PosTabStatus? status,
    PosTab? tab,
    List<PosShare>? shares,
    String? message,
  }) {
    return PosTabState(
      status: status ?? this.status,
      tab: tab ?? this.tab,
      shares: shares ?? this.shares,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, tab, shares, message];

  @override
  String toString() => '$status { tab: ${tab?.tabId}, message: $message }';
}
