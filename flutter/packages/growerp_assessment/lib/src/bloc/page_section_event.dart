abstract class PageSectionEvent {
  const PageSectionEvent();
}

class PageSectionLoad extends PageSectionEvent {
  final String landingPageId;

  const PageSectionLoad(this.landingPageId);

  @override
  String toString() => 'PageSectionLoad(landingPageId: $landingPageId)';
}

class PageSectionCreate extends PageSectionEvent {
  final String landingPageId;
  final String sectionTitle;
  final String? sectionDescription;
  final String? sectionImageUrl;
  final int? sectionSequence;

  const PageSectionCreate({
    required this.landingPageId,
    required this.sectionTitle,
    this.sectionDescription,
    this.sectionImageUrl,
    this.sectionSequence,
  });

  @override
  String toString() =>
      'PageSectionCreate(landingPageId: $landingPageId, sectionTitle: $sectionTitle)';
}

class PageSectionUpdate extends PageSectionEvent {
  final String pageSectionId;
  final String? sectionTitle;
  final String? sectionDescription;
  final String? sectionImageUrl;
  final int? sectionSequence;

  const PageSectionUpdate({
    required this.pageSectionId,
    this.sectionTitle,
    this.sectionDescription,
    this.sectionImageUrl,
    this.sectionSequence,
  });

  @override
  String toString() => 'PageSectionUpdate(pageSectionId: $pageSectionId)';
}

class PageSectionDelete extends PageSectionEvent {
  final String pageSectionId;

  const PageSectionDelete(this.pageSectionId);

  @override
  String toString() => 'PageSectionDelete(pageSectionId: $pageSectionId)';
}

class PageSectionClear extends PageSectionEvent {
  const PageSectionClear();

  @override
  String toString() => 'PageSectionClear()';
}
