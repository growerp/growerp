abstract class PageSectionEvent {
  const PageSectionEvent();
}

class PageSectionLoad extends PageSectionEvent {
  final String pageId;

  const PageSectionLoad(this.pageId);

  @override
  String toString() => 'PageSectionLoad(pageId: $pageId)';
}

class PageSectionCreate extends PageSectionEvent {
  final String pageId;
  final String sectionTitle;
  final String? sectionDescription;
  final String? sectionImageUrl;
  final int? sectionSequence;

  const PageSectionCreate({
    required this.pageId,
    required this.sectionTitle,
    this.sectionDescription,
    this.sectionImageUrl,
    this.sectionSequence,
  });

  @override
  String toString() =>
      'PageSectionCreate(pageId: $pageId, sectionTitle: $sectionTitle)';
}

class PageSectionUpdate extends PageSectionEvent {
  final String sectionId;
  final String? sectionTitle;
  final String? sectionDescription;
  final String? sectionImageUrl;
  final int? sectionSequence;

  const PageSectionUpdate({
    required this.sectionId,
    this.sectionTitle,
    this.sectionDescription,
    this.sectionImageUrl,
    this.sectionSequence,
  });

  @override
  String toString() => 'PageSectionUpdate(sectionId: $sectionId)';
}

class PageSectionDelete extends PageSectionEvent {
  final String sectionId;

  const PageSectionDelete(this.sectionId);

  @override
  String toString() => 'PageSectionDelete(sectionId: $sectionId)';
}

class PageSectionClear extends PageSectionEvent {
  const PageSectionClear();

  @override
  String toString() => 'PageSectionClear()';
}
