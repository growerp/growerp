import 'package:equatable/equatable.dart';

abstract class CredibilityEvent extends Equatable {
  const CredibilityEvent();

  @override
  List<Object?> get props => [];
}

class CredibilityLoad extends CredibilityEvent {
  final String landingPageId;

  const CredibilityLoad({required this.landingPageId});

  @override
  List<Object?> get props => [landingPageId];
}

class CredibilityInfoCreate extends CredibilityEvent {
  final String landingPageId;
  final String infoTitle;
  final String? infoDescription;
  final String? infoIconName;
  final int? infoSequence;
  final String? statisticsJson;

  const CredibilityInfoCreate({
    required this.landingPageId,
    required this.infoTitle,
    this.infoDescription,
    this.infoIconName,
    this.infoSequence,
    this.statisticsJson,
  });

  @override
  List<Object?> get props => [
        landingPageId,
        infoTitle,
        infoDescription,
        infoIconName,
        infoSequence,
        statisticsJson
      ];
}

class CredibilityInfoUpdate extends CredibilityEvent {
  final String landingPageId;
  final String credibilityInfoId;
  final String? pseudoId;
  final String infoTitle;
  final String? infoDescription;
  final String? infoIconName;
  final int? infoSequence;
  final String? statisticsJson;

  const CredibilityInfoUpdate({
    required this.landingPageId,
    required this.credibilityInfoId,
    this.pseudoId,
    required this.infoTitle,
    this.infoDescription,
    this.infoIconName,
    this.infoSequence,
    this.statisticsJson,
  });

  @override
  List<Object?> get props => [
        landingPageId,
        credibilityInfoId,
        pseudoId,
        infoTitle,
        infoDescription,
        infoIconName,
        infoSequence,
        statisticsJson
      ];
}

class CredibilityInfoDelete extends CredibilityEvent {
  final String landingPageId;
  final String credibilityInfoId;

  const CredibilityInfoDelete({
    required this.landingPageId,
    required this.credibilityInfoId,
  });

  @override
  List<Object?> get props => [landingPageId, credibilityInfoId];
}

class CredibilityStatisticCreate extends CredibilityEvent {
  final String landingPageId;
  final String statLabel;
  final String statValue;
  final String? statIcon;

  const CredibilityStatisticCreate({
    required this.landingPageId,
    required this.statLabel,
    required this.statValue,
    this.statIcon,
  });

  @override
  List<Object?> get props => [landingPageId, statLabel, statValue, statIcon];
}

class CredibilityStatisticUpdate extends CredibilityEvent {
  final String credibilityStatisticId;
  final String statLabel;
  final String statValue;
  final String? statIcon;

  const CredibilityStatisticUpdate({
    required this.credibilityStatisticId,
    required this.statLabel,
    required this.statValue,
    this.statIcon,
  });

  @override
  List<Object?> get props =>
      [credibilityStatisticId, statLabel, statValue, statIcon];
}

class CredibilityReorder extends CredibilityEvent {
  final List<String> newInfoOrder;

  const CredibilityReorder({required this.newInfoOrder});

  @override
  List<Object?> get props => [newInfoOrder];
}
