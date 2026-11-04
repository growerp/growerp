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

part of 'pos_refund_bloc.dart';

abstract class PosRefundEvent extends Equatable {
  const PosRefundEvent();
  @override
  List<Object?> get props => [];
}

class PosRefundLookup extends PosRefundEvent {
  const PosRefundLookup(this.search);
  final String search;
  @override
  List<Object?> get props => [search];
}

class PosRefundSubmit extends PosRefundEvent {
  const PosRefundSubmit({
    required this.lines,
    required this.restock,
    required this.terminalName,
  });
  final List<PosRefundLine> lines;
  final bool restock;
  final String terminalName;
  @override
  List<Object?> get props => [lines, restock, terminalName];
}

class PosRefundReset extends PosRefundEvent {
  const PosRefundReset();
}
