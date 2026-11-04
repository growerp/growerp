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

part of 'pos_sale_bloc.dart';

abstract class PosSaleEvent extends Equatable {
  const PosSaleEvent();
  @override
  List<Object?> get props => [];
}

class PosSaleSubmit extends PosSaleEvent {
  const PosSaleSubmit({
    required this.lines,
    required this.tenders,
    this.terminalName,
  });
  final List<PosLine> lines;
  final List<PosTender> tenders;
  final String? terminalName;
  @override
  List<Object?> get props => [lines, tenders, terminalName];
}

/// pay a restaurant tab
class PosSaleSettle extends PosSaleEvent {
  const PosSaleSettle({
    required this.tabId,
    required this.tenders,
    required this.terminalName,
  });
  final String tabId;
  final List<PosTender> tenders;
  final String terminalName;
  @override
  List<Object?> get props => [tabId, tenders, terminalName];
}

/// the sale is finished, the next one gets a new id
class PosSaleReset extends PosSaleEvent {
  const PosSaleReset();
}
