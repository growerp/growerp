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

part of 'website_bloc.dart';

enum WebsiteStatus { initial, loading, success, failure }

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
  List<Object?> get props => [status, website, message];

  @override
  String toString() => "$status website: ${website?.id}";
}
