import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

enum CTAStatus {
  initial,
  loading,
  success,
  failure,
}

class CTAState extends Equatable {
  const CTAState({
    this.status = CTAStatus.initial,
    this.callToAction,
    this.message,
  });

  final CTAStatus status;
  final CallToAction? callToAction;
  final String? message;

  CTAState copyWith({
    CTAStatus? status,
    CallToAction? callToAction,
    String? message,
  }) {
    return CTAState(
      status: status ?? this.status,
      callToAction: callToAction ?? this.callToAction,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        callToAction,
        message,
      ];
}
