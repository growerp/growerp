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

part of 'landing_page_generation_bloc.dart';

abstract class LandingPageGenerationEvent extends Equatable {
  const LandingPageGenerationEvent();
}

class GenerateLandingPageRequested extends LandingPageGenerationEvent {
  final String businessDescription;
  final String? targetAudience;
  final String? industry;
  final String? tone; // 'professional', 'casual', 'inspirational'
  final int? numSections; // 3-7

  const GenerateLandingPageRequested({
    required this.businessDescription,
    this.targetAudience,
    this.industry,
    this.tone = 'professional',
    this.numSections = 5,
  });

  @override
  List<Object?> get props => [
        businessDescription,
        targetAudience,
        industry,
        tone,
        numSections,
      ];
}

class GenerationCancelled extends LandingPageGenerationEvent {
  const GenerationCancelled();

  @override
  List<Object?> get props => [];
}
