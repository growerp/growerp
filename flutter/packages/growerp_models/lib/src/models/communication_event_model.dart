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

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../growerp_models.dart';

part 'communication_event_model.freezed.dart';
part 'communication_event_model.g.dart';

/// Backend CommunicationEventType ids. autoEmail = sent by the system,
/// logged automatically and read only.
enum CommunicationEventType {
  @JsonValue('Phone')
  phone,
  @JsonValue('Email')
  email,
  @JsonValue('FaceToFace')
  faceToFace,
  @JsonValue('Letter')
  letter,
  @JsonValue('Comment')
  comment,
  @JsonValue('Message')
  message,
  @JsonValue('AutoEmail')
  autoEmail,
}

/// Relative to the own company: outgoing = from us to the party.
enum CommunicationDirection { outgoing, incoming }

/// A logged communication with a person or company.
@freezed
abstract class CommunicationEvent with _$CommunicationEvent {
  CommunicationEvent._();
  factory CommunicationEvent({
    String? communicationEventId,
    CommunicationEventType? type,
    CommunicationDirection? direction,
    @DateTimeConverter() DateTime? entryDate,
    String? subject,
    String? body,
    String? contentType,
    String? note,
    bool? isAuto,
    String? fromPartyPseudoId,
    String? fromPartyName,
    String? toPartyPseudoId,
    String? toPartyName,
    // create only: the person or company the communication is with
    String? partyPseudoId,
  }) = _CommunicationEvent;

  factory CommunicationEvent.fromJson(Map<String, dynamic> json) =>
      _$CommunicationEventFromJson(json['communicationEvent'] ?? json);
}
