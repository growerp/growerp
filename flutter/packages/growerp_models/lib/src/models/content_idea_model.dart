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

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:growerp_models/growerp_models.dart';

part 'content_idea_model.freezed.dart';
part 'content_idea_model.g.dart';

/// Raw material for a website article: pasted text or notes, the URL of an
/// article, or both. Writing it produces a ~500 word article (a MasterContent
/// ARTICLE in teaser mode) that goes on the website when approved; the idea
/// itself is deleted then.
@freezed
abstract class ContentIdea with _$ContentIdea {
  ContentIdea._();
  factory ContentIdea({
    String? ideaId,
    String? pseudoId,
    String? title,
    String? rawText,
    String? sourceUrl,

    /// position in the list: the weekly agent uses the ideas top first
    int? sequenceNum,
    @NullableTimestampConverter() DateTime? createdDate,
  }) = _ContentIdea;

  factory ContentIdea.fromJson(Map<String, dynamic> json) =>
      _$ContentIdeaFromJson(json['contentIdea'] ?? json);
}

@freezed
abstract class ContentIdeas with _$ContentIdeas {
  ContentIdeas._();
  factory ContentIdeas({@Default([]) List<ContentIdea> contentIdeas}) =
      _ContentIdeas;

  factory ContentIdeas.fromJson(Map<String, dynamic> json) =>
      _$ContentIdeasFromJson(json);
}
