import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

/// Base class for all MasterContent events
abstract class MasterContentEvent extends Equatable {
  const MasterContentEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch master content (with optional refresh and search)
class MasterContentFetch extends MasterContentEvent {
  final bool refresh;
  final int limit;
  final int start;
  final String searchString;
  final String? planId;

  const MasterContentFetch({
    this.refresh = false,
    this.limit = 20,
    this.start = 0,
    this.searchString = '',
    this.planId,
  });

  @override
  List<Object?> get props => [refresh, limit, start, searchString, planId];
}

/// Event to create a new master content piece
class MasterContentCreate extends MasterContentEvent {
  final MasterContent masterContent;

  const MasterContentCreate(this.masterContent);

  @override
  List<Object?> get props => [masterContent];
}

/// Event to update an existing master content piece
class MasterContentUpdate extends MasterContentEvent {
  final MasterContent masterContent;

  const MasterContentUpdate(this.masterContent);

  @override
  List<Object?> get props => [masterContent];
}

/// Event to delete a master content piece
class MasterContentDelete extends MasterContentEvent {
  final MasterContent masterContent;

  const MasterContentDelete(this.masterContent);

  @override
  List<Object?> get props => [masterContent];
}

/// Event to author a platform-neutral piece using AI
class MasterContentGenerateWithAI extends MasterContentEvent {
  final String? personaId;
  final String? planId;
  final String contentType;
  final String pnpType;
  final String? title;
  final String? brief;
  final String? targetUrl;

  const MasterContentGenerateWithAI({
    this.personaId,
    this.planId,
    this.contentType = 'POSTING',
    this.pnpType = 'OTHER',
    this.title,
    this.brief,
    this.targetUrl,
  });

  @override
  List<Object?> get props =>
      [personaId, planId, contentType, pnpType, title, brief, targetUrl];
}

/// Event to fan a master piece out to per-platform children
class MasterContentAdaptForPlatform extends MasterContentEvent {
  final String masterContentId;
  final List<String>? platforms;
  final String? campaignId;
  final DateTime? scheduledDate;

  const MasterContentAdaptForPlatform({
    required this.masterContentId,
    this.platforms,
    this.campaignId,
    this.scheduledDate,
  });

  @override
  List<Object?> get props =>
      [masterContentId, platforms, campaignId, scheduledDate];
}

/// Event to approve (or revoke approval of) a master content piece.
/// Approving lets the scheduler auto-publish every SocialPost adapted
/// from this piece; revoking stops future auto-publishes.
class MasterContentApprove extends MasterContentEvent {
  final String masterContentId;
  final bool approve;

  const MasterContentApprove({
    required this.masterContentId,
    this.approve = true,
  });

  @override
  List<Object?> get props => [masterContentId, approve];
}

class MasterContentSearchRequested extends MasterContentEvent {
  final String searchString;

  const MasterContentSearchRequested({required this.searchString});

  @override
  List<Object> get props => [searchString];
}
