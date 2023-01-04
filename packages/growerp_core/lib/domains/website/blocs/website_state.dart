/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the websiteor(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

part of 'website_bloc.dart';

enum WebsiteStatus {
  initial,
  loading,
  success,
  failure,
}

class WebsiteState extends Equatable {
  const WebsiteState({
    this.status = WebsiteStatus.initial,
    this.website,
    this.content,
    this.message,
  });

  final WebsiteStatus status;
  final Website? website;
  final Content? content;
  final String? message;

  WebsiteState copyWith({
    WebsiteStatus? status,
    Website? website,
    Content? content,
    String? message,
  }) {
    return WebsiteState(
      status: status ?? this.status,
      website: website ?? this.website,
      content: content ?? this.content,
      message: message, // message not kept over state changes
    );
  }

  @override
  List<Object?> get props => [status, website, content, message];

  @override
  String toString() => "$status { website: ${website?.id}";
}
