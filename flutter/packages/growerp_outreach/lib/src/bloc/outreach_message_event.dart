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

import 'package:equatable/equatable.dart';

abstract class OutreachMessageEvent extends Equatable {
  const OutreachMessageEvent();
  @override
  List<Object?> get props => [];
}

/// Load outreach messages with pagination
class OutreachMessageLoad extends OutreachMessageEvent {
  final int start;
  final int limit;
  final String? campaignId;
  final String? status;

  const OutreachMessageLoad({
    this.start = 0,
    this.limit = 20,
    this.campaignId,
    this.status,
  });

  @override
  List<Object?> get props => [start, limit, campaignId, status];
}

/// Create a new outreach message
class OutreachMessageCreate extends OutreachMessageEvent {
  final String? campaignId;
  final String platform;
  final String? recipientName;
  final String? recipientProfileUrl;
  final String? recipientHandle;
  final String? recipientEmail;
  final String messageContent;

  const OutreachMessageCreate({
    this.campaignId,
    required this.platform,
    this.recipientName,
    this.recipientProfileUrl,
    this.recipientHandle,
    this.recipientEmail,
    required this.messageContent,
  });

  @override
  List<Object?> get props => [
        campaignId,
        platform,
        recipientName,
        recipientProfileUrl,
        recipientHandle,
        recipientEmail,
        messageContent,
      ];
}

/// Update outreach message status
class OutreachMessageUpdateStatus extends OutreachMessageEvent {
  final String messageId;
  final String status;
  final String? errorMessage;

  const OutreachMessageUpdateStatus({
    required this.messageId,
    required this.status,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [messageId, status, errorMessage];
}

/// Delete an outreach message
class OutreachMessageDelete extends OutreachMessageEvent {
  final String messageId;

  const OutreachMessageDelete(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

/// Search outreach messages
class OutreachMessageSearchRequested extends OutreachMessageEvent {
  final String query;

  const OutreachMessageSearchRequested({required this.query});

  @override
  List<Object?> get props => [query];
}
