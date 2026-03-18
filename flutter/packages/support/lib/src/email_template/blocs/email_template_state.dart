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

part of 'email_template_bloc.dart';

enum EmailTemplateStatus { initial, loading, success, failure }

class EmailTemplateState extends Equatable {
  const EmailTemplateState({
    this.status = EmailTemplateStatus.initial,
    this.emailTemplates = const <EmailTemplate>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final EmailTemplateStatus status;
  final String? message;
  final List<EmailTemplate> emailTemplates;
  final bool hasReachedMax;
  final String searchString;

  EmailTemplateState copyWith({
    EmailTemplateStatus? status,
    String? message,
    List<EmailTemplate>? emailTemplates,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return EmailTemplateState(
      status: status ?? this.status,
      emailTemplates: emailTemplates ?? this.emailTemplates,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props =>
      [status, message, emailTemplates, hasReachedMax];

  @override
  String toString() =>
      '$status { #emailTemplates: ${emailTemplates.length}, '
      'hasReachedMax: $hasReachedMax message: $message}';
}
