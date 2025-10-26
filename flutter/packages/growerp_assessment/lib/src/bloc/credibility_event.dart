import 'package:equatable/equatable.dart';

abstract class CredibilityEvent extends Equatable {
  const CredibilityEvent();

  @override
  List<Object?> get props => [];
}

class CredibilityLoad extends CredibilityEvent {
  final String pageId;

  const CredibilityLoad({required this.pageId});

  @override
  List<Object?> get props => [pageId];
}

class CredibilityInfoCreate extends CredibilityEvent {
  final String pageId;
  final String infoTitle;
  final String? infoDescription;
  final String? infoIconName;
  final int? infoSequence;

  const CredibilityInfoCreate({
    required this.pageId,
    required this.infoTitle,
    this.infoDescription,
    this.infoIconName,
    this.infoSequence,
  });

  @override
  List<Object?> get props =>
      [pageId, infoTitle, infoDescription, infoIconName, infoSequence];
}

class CredibilityInfoUpdate extends CredibilityEvent {
  final String pageId;
  final String infoId;
  final String infoTitle;
  final String? infoDescription;
  final String? infoIconName;
  final int? infoSequence;

  const CredibilityInfoUpdate({
    required this.pageId,
    required this.infoId,
    required this.infoTitle,
    this.infoDescription,
    this.infoIconName,
    this.infoSequence,
  });

  @override
  List<Object?> get props =>
      [pageId, infoId, infoTitle, infoDescription, infoIconName, infoSequence];
}

class CredibilityInfoDelete extends CredibilityEvent {
  final String pageId;
  final String infoId;

  const CredibilityInfoDelete({
    required this.pageId,
    required this.infoId,
  });

  @override
  List<Object?> get props => [pageId, infoId];
}

class CredibilityStatisticCreate extends CredibilityEvent {
  final String pageId;
  final String statLabel;
  final String statValue;
  final String? statIcon;

  const CredibilityStatisticCreate({
    required this.pageId,
    required this.statLabel,
    required this.statValue,
    this.statIcon,
  });

  @override
  List<Object?> get props => [pageId, statLabel, statValue, statIcon];
}

class CredibilityStatisticUpdate extends CredibilityEvent {
  final String statisticId;
  final String statLabel;
  final String statValue;
  final String? statIcon;

  const CredibilityStatisticUpdate({
    required this.statisticId,
    required this.statLabel,
    required this.statValue,
    this.statIcon,
  });

  @override
  List<Object?> get props => [statisticId, statLabel, statValue, statIcon];
}

class CredibilityStatisticDelete extends CredibilityEvent {
  final String statisticId;

  const CredibilityStatisticDelete({required this.statisticId});

  @override
  List<Object?> get props => [statisticId];
}

class CredibilityReorder extends CredibilityEvent {
  final List<String> newInfoOrder;

  const CredibilityReorder({required this.newInfoOrder});

  @override
  List<Object?> get props => [newInfoOrder];
}
