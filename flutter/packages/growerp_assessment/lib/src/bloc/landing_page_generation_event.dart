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
