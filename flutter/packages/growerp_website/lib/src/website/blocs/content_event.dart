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

abstract class ContentEvent extends Equatable {
  const ContentEvent();
  @override
  List<Object> get props => [];
}

class ContentFetch extends ContentEvent {
  final String websiteId;
  final Content content;
  const ContentFetch(this.websiteId, this.content);
  @override
  List<Object> get props => [websiteId, content];
}

class ContentUpdate extends ContentEvent {
  final String websiteId;
  final Content content;
  const ContentUpdate(this.websiteId, this.content);
}
