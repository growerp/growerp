import 'package:growerp_models/growerp_models.dart';

abstract class LandingPageEvent {
  const LandingPageEvent();
}

class LandingPageLoad extends LandingPageEvent {
  final int start;
  final int limit;
  final String? search;

  const LandingPageLoad({
    this.start = 0,
    this.limit = 20,
    this.search,
  });

  @override
  String toString() =>
      'LandingPageLoad(start: $start, limit: $limit, search: $search)';
}

class LandingPageFetch extends LandingPageEvent {
  final String? landingPageId;
  final String? pseudoId;
  final String? ownerPartyId;

  const LandingPageFetch({
    this.landingPageId,
    this.pseudoId,
    this.ownerPartyId,
  });

  @override
  String toString() =>
      'LandingPageFetch(landingPageId: $landingPageId, pseudoId: $pseudoId, ownerPartyId: $ownerPartyId)';
}

class LandingPageCreate extends LandingPageEvent {
  final LandingPage landingPage;

  const LandingPageCreate(this.landingPage);

  @override
  String toString() => 'LandingPageCreate(landingPage: $landingPage)';
}

class LandingPageUpdate extends LandingPageEvent {
  final LandingPage landingPage;

  const LandingPageUpdate(this.landingPage);

  @override
  String toString() => 'LandingPageUpdate(landingPage: $landingPage)';
}

class LandingPageDelete extends LandingPageEvent {
  final String landingPageId;

  const LandingPageDelete(this.landingPageId);

  @override
  String toString() => 'LandingPageDelete(landingPageId: $landingPageId)';
}

class LandingPageClear extends LandingPageEvent {
  const LandingPageClear();

  @override
  String toString() => 'LandingPageClear()';
}
