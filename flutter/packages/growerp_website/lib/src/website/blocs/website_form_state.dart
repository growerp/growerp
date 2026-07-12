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

part of 'website_form_bloc.dart';

enum WebsiteFormStatus { initial, loading, success, failure }

class WebsiteFormState extends Equatable {
  const WebsiteFormState({
    this.status = WebsiteFormStatus.initial,
    this.webForms = const <WebsiteForm>[],
    this.message,
  });

  final WebsiteFormStatus status;
  final List<WebsiteForm> webForms;
  final String? message;

  WebsiteFormState copyWith({
    WebsiteFormStatus? status,
    List<WebsiteForm>? webForms,
    String? message,
  }) {
    return WebsiteFormState(
      status: status ?? this.status,
      webForms: webForms ?? this.webForms,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, message, webForms];
}
