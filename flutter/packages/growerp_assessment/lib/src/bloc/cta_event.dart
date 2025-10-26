import 'package:equatable/equatable.dart';

abstract class CTAEvent extends Equatable {
  const CTAEvent();

  @override
  List<Object?> get props => [];
}

class CTALoad extends CTAEvent {
  final String pageId;

  const CTALoad({required this.pageId});

  @override
  List<Object?> get props => [pageId];
}

class CTACreate extends CTAEvent {
  final String pageId;
  final String buttonText;
  final String actionType;
  final String? actionTarget;
  final String? buttonStyle;

  const CTACreate({
    required this.pageId,
    required this.buttonText,
    required this.actionType,
    this.actionTarget,
    this.buttonStyle,
  });

  @override
  List<Object?> get props =>
      [pageId, buttonText, actionType, actionTarget, buttonStyle];
}

class CTAUpdate extends CTAEvent {
  final String pageId;
  final String ctaId;
  final String buttonText;
  final String actionType;
  final String? actionTarget;
  final String? buttonStyle;

  const CTAUpdate({
    required this.pageId,
    required this.ctaId,
    required this.buttonText,
    required this.actionType,
    this.actionTarget,
    this.buttonStyle,
  });

  @override
  List<Object?> get props =>
      [pageId, ctaId, buttonText, actionType, actionTarget, buttonStyle];
}

class CTADelete extends CTAEvent {
  final String pageId;
  final String ctaId;

  const CTADelete({
    required this.pageId,
    required this.ctaId,
  });

  @override
  List<Object?> get props => [pageId, ctaId];
}
