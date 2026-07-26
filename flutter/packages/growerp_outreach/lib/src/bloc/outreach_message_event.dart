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

/// Convert a PENDING/RESPONDED outreach message into a GrowERP lead.
///
/// The BLoC handler will:
///   1. Call `POST /User` with `role = Role.lead` using the prospect's details.
///   2. Call `PATCH /OutreachMessage` with `status = CONVERTED` and
///      `convertedPartyId` set to the newly created user's partyId.
///
/// After conversion the returned [OutreachMessage] carries [convertedPartyId]
/// so the UI can navigate directly to the CRM lead record.
class OutreachMessageConvertToLead extends OutreachMessageEvent {
  /// ID of the OutreachMessage staging row to promote.
  final String messageId;

  /// Prospect's first name (required by User model).
  final String firstName;

  /// Prospect's last name.
  final String? lastName;

  /// Prospect's email address.
  final String? email;

  /// Prospect's company name (creates / links a Company party).
  final String? companyName;

  /// Prospect's job title (stored on the User record).
  final String? title;

  const OutreachMessageConvertToLead({
    required this.messageId,
    required this.firstName,
    this.lastName,
    this.email,
    this.companyName,
    this.title,
  });

  @override
  List<Object?> get props => [
    messageId,
    firstName,
    lastName,
    email,
    companyName,
    title,
  ];
}
