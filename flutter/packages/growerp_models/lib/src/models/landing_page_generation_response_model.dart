import 'package:freezed_annotation/freezed_annotation.dart';

import 'landing_page_model.dart';

part 'landing_page_generation_response_model.freezed.dart';
part 'landing_page_generation_response_model.g.dart';

@freezed
abstract class LandingPageGenerationResponse
    with _$LandingPageGenerationResponse {
  factory LandingPageGenerationResponse({
    LandingPage? landingPage,
    @Default(0) int sectionsCreated,
    @Default('') String message,
    @Default('') String status,
  }) = _LandingPageGenerationResponse;

  factory LandingPageGenerationResponse.fromJson(Map<String, dynamic> json) =>
      _$LandingPageGenerationResponseFromJson(
        json['landingPageGenerationResponse'] ?? json,
      );
}
