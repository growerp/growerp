import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

enum CredibilityStatus {
  initial,
  loading,
  success,
  failure,
}

class CredibilityState extends Equatable {
  const CredibilityState({
    this.status = CredibilityStatus.initial,
    this.credibilityElements = const [],
    this.credibilityStatistics = const [],
    this.message,
  });

  final CredibilityStatus status;
  final List<CredibilityInfo> credibilityElements;
  final List<Map<String, dynamic>> credibilityStatistics;
  final String? message;

  CredibilityState copyWith({
    CredibilityStatus? status,
    List<CredibilityInfo>? credibilityElements,
    List<Map<String, dynamic>>? credibilityStatistics,
    String? message,
  }) {
    return CredibilityState(
      status: status ?? this.status,
      credibilityElements: credibilityElements ?? this.credibilityElements,
      credibilityStatistics:
          credibilityStatistics ?? this.credibilityStatistics,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        credibilityElements,
        credibilityStatistics,
        message,
      ];
}
