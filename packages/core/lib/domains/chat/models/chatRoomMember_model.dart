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

import 'package:core/domains/domains.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chatRoomMember_model.freezed.dart';
part 'chatRoomMember_model.g.dart';

@freezed
class ChatRoomMember with _$ChatRoomMember {
  ChatRoomMember._();
  factory ChatRoomMember({
    User? member,
    bool? hasRead,
    bool? isActive,
  }) = _ChatRoomMember;

  factory ChatRoomMember.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomMemberFromJson(json);

  String toString() =>
      'ChatRoom Member: ${member?.firstName} ${member?.lastName} '
      'userId: ${member?.userId} partyId: ${member?.partyId}';
}
