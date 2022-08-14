/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the contentor(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

part of 'content_bloc.dart';

enum ContentStatus {
  initial,
  loading,
  success,
  failure,
}

class ContentState extends Equatable {
  const ContentState({
    this.status = ContentStatus.initial,
    this.content,
    this.message,
  });

  final ContentStatus status;
  final Content? content;
  final String? message;

  ContentState copyWith({
    ContentStatus? status,
    Content? content,
    String? message,
  }) {
    return ContentState(
      status: status ?? this.status,
      content: content ?? this.content,
      message: message, // message not kept over state changes
    );
  }

  @override
  List<Object?> get props => [content, message];

  @override
  String toString() => "$status { content: ${content?.path}";
}
