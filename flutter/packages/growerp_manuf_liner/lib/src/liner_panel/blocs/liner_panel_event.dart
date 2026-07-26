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

part of 'liner_panel_bloc.dart';

abstract class LinerPanelEvent extends Equatable {
  const LinerPanelEvent();
  @override
  List<Object?> get props => [];
}

class LinerPanelsFetch extends LinerPanelEvent {
  const LinerPanelsFetch({
    this.workEffortId,
    this.salesOrderId,
    this.refresh = false,
    this.limit = 100,
  });
  final String? workEffortId;
  final String? salesOrderId;
  final bool refresh;
  final int limit;
  @override
  List<Object?> get props => [workEffortId, salesOrderId, refresh];
}

class LinerPanelUpdate extends LinerPanelEvent {
  const LinerPanelUpdate(this.linerPanel);
  final LinerPanel linerPanel;
}

class LinerPanelDelete extends LinerPanelEvent {
  const LinerPanelDelete(this.linerPanel);
  final LinerPanel linerPanel;
}
