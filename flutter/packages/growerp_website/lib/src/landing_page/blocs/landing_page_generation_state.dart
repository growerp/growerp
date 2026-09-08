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

enum GenerationStatus {
  initial,
  loading,
  researchingBusiness,
  generatingContent,
  creatingXml,
  importing,
  success,
  failure,
}

class LandingPageGenerationState extends Equatable {
  final GenerationStatus status;
  final String? message;
  final int? progressPercent;
  final String? generatedXmlPath;
  final LandingPage? generatedLandingPage;

  const LandingPageGenerationState({
    this.status = GenerationStatus.initial,
    this.message,
    this.progressPercent = 0,
    this.generatedXmlPath,
    this.generatedLandingPage,
  });

  LandingPageGenerationState copyWith({
    GenerationStatus? status,
    String? message,
    int? progressPercent,
    String? generatedXmlPath,
    LandingPage? generatedLandingPage,
  }) {
    return LandingPageGenerationState(
      status: status ?? this.status,
      message: message ?? this.message,
      progressPercent: progressPercent ?? this.progressPercent,
      generatedXmlPath: generatedXmlPath ?? this.generatedXmlPath,
      generatedLandingPage: generatedLandingPage ?? this.generatedLandingPage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        message,
        progressPercent,
        generatedXmlPath,
        generatedLandingPage,
      ];
}
