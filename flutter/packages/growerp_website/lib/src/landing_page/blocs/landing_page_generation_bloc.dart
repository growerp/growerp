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

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';

part 'landing_page_generation_event.dart';
part 'landing_page_generation_state.dart';

class LandingPageGenerationBloc
    extends Bloc<LandingPageGenerationEvent, LandingPageGenerationState> {
  final RestClient restClient;
  final String applicationId;

  LandingPageGenerationBloc({
    required this.restClient,
    required this.applicationId,
  }) : super(const LandingPageGenerationState()) {
    on<GenerateLandingPageRequested>(_onGenerateLandingPage);
    on<GenerationCancelled>(_onGenerationCancelled);
  }

  Future<void> _onGenerateLandingPage(
    GenerateLandingPageRequested event,
    Emitter<LandingPageGenerationState> emit,
  ) async {
    emit(state.copyWith(
      status: GenerationStatus.loading,
      message: 'Starting generation...',
      progressPercent: 0,
    ));

    try {
      // Call backend to generate content with AI and create landing page directly
      emit(state.copyWith(
        status: GenerationStatus.researchingBusiness,
        message: 'Researching your business and generating content with AI...',
        progressPercent: 20,
      ));

      // Single API call that generates content and creates landing page
      final result = await restClient.generateLandingPageWithAI(
        businessDescription: event.businessDescription,
        targetAudience: event.targetAudience,
        industry: event.industry,
        tone: event.tone ?? 'professional',
        numSections: event.numSections ?? 5,
      );

      emit(state.copyWith(
        status: GenerationStatus.success,
        message: 'Landing page created successfully!',
        progressPercent: 100,
        generatedLandingPage: result.landingPage,
      ));
    } catch (e, stackTrace) {
      debugPrint('=== ERROR in generation: $e');
      debugPrint('=== Stack trace: $stackTrace');

      // Get user-friendly error message
      final errorMessage = await getDioError(e);

      emit(state.copyWith(
        status: GenerationStatus.failure,
        message: errorMessage,
        progressPercent: 0,
      ));
    }
  }

  Future<void> _onGenerationCancelled(
    GenerationCancelled event,
    Emitter<LandingPageGenerationState> emit,
  ) async {
    emit(const LandingPageGenerationState(
      status: GenerationStatus.initial,
    ));
  }
}
