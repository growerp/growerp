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

part of 'communication_bloc.dart';

abstract class CommunicationBlocEvent extends Equatable {
  const CommunicationBlocEvent();
  @override
  List<Object?> get props => [];
}

class CommunicationFetch extends CommunicationBlocEvent {
  const CommunicationFetch({this.refresh = false, this.searchString = ''});
  final bool refresh;
  final String searchString;
  @override
  List<Object?> get props => [refresh, searchString];
}

/// create when communicationEventId is null, otherwise update
class CommunicationUpdate extends CommunicationBlocEvent {
  const CommunicationUpdate(this.communicationEvent);
  final CommunicationEvent communicationEvent;
  @override
  List<Object?> get props => [communicationEvent];
}

class CommunicationDelete extends CommunicationBlocEvent {
  const CommunicationDelete(this.communicationEvent);
  final CommunicationEvent communicationEvent;
  @override
  List<Object?> get props => [communicationEvent];
}
