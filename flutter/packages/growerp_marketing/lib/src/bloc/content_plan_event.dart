import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

/// Base class for all ContentPlan events
abstract class ContentPlanEvent extends Equatable {
  const ContentPlanEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch content plans (with optional refresh and search)
class ContentPlanFetch extends ContentPlanEvent {
  final bool refresh;
  final int limit;
  final int start;
  final String searchString;

  const ContentPlanFetch({
    this.refresh = false,
    this.limit = 20,
    this.start = 0,
    this.searchString = '',
  });

  @override
  List<Object?> get props => [refresh, limit, start, searchString];
}

/// Event to create a new content plan
class ContentPlanCreate extends ContentPlanEvent {
  final ContentPlan contentPlan;

  const ContentPlanCreate(this.contentPlan);

  @override
  List<Object?> get props => [contentPlan];
}

/// Event to update an existing content plan
class ContentPlanUpdate extends ContentPlanEvent {
  final ContentPlan contentPlan;

  const ContentPlanUpdate(this.contentPlan);

  @override
  List<Object?> get props => [contentPlan];
}

/// Event to delete a content plan
class ContentPlanDelete extends ContentPlanEvent {
  final ContentPlan contentPlan;

  const ContentPlanDelete(this.contentPlan);

  @override
  List<Object?> get props => [contentPlan];
}

/// Event to generate a content plan using AI
class ContentPlanGenerateWithAI extends ContentPlanEvent {
  final String personaId;
  final DateTime? weekStartDate;

  const ContentPlanGenerateWithAI({
    required this.personaId,
    this.weekStartDate,
  });

  @override
  List<Object?> get props => [personaId, weekStartDate];
}

/// Event to search content plans
class ContentPlanSearchRequested extends ContentPlanEvent {
  final String searchString;

  const ContentPlanSearchRequested({required this.searchString});

  @override
  List<Object?> get props => [searchString];
}
