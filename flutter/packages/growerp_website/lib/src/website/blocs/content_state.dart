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

part of 'content_bloc.dart';

enum ContentStatus { initial, loading, updating, success, failure }

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
  List<Object?> get props => [status, content, message];

  @override
  String toString() => "$status { content: ${content?.path}";
}
