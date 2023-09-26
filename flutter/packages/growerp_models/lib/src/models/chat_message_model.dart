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

import 'package:freezed_annotation/freezed_annotation.dart';
import '../json_converters.dart';

part 'chat_message_model.freezed.dart';
part 'chat_message_model.g.dart';

// backend relation: product -> chatMessage -> chatMessageReservation -> orderItem

@freezed
class ChatMessage with _$ChatMessage {
  ChatMessage._();
  factory ChatMessage({
    String? fromUserId,
    String? chatMessageId,
    String? content,
    @DateTimeConverter() DateTime? creationDate,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
