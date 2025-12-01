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
