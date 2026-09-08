import 'package:growerp_models/growerp_models.dart';

enum PageSectionStatus { initial, loading, success, failure }

class PageSectionState {
  final PageSectionStatus status;
  final List<LandingPageSection> sections;
  final LandingPageSection? selectedSection;
  final String? message;
  final String? pageId;

  const PageSectionState({
    this.status = PageSectionStatus.initial,
    this.sections = const [],
    this.selectedSection,
    this.message,
    this.pageId,
  });

  PageSectionState copyWith({
    PageSectionStatus? status,
    List<LandingPageSection>? sections,
    LandingPageSection? selectedSection,
    String? message,
    String? pageId,
    bool clearSelectedSection = false,
  }) {
    return PageSectionState(
      status: status ?? this.status,
      sections: sections ?? this.sections,
      selectedSection:
          clearSelectedSection ? null : selectedSection ?? this.selectedSection,
      message: message,
      pageId: pageId ?? this.pageId,
    );
  }

  @override
  String toString() {
    return 'PageSectionState('
        'status: $status, '
        'sections: ${sections.length}, '
        'selectedSection: $selectedSection, '
        'message: $message, '
        'pageId: $pageId'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageSectionState &&
        other.status == status &&
        other.sections == sections &&
        other.selectedSection == selectedSection &&
        other.message == message &&
        other.pageId == pageId;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        sections.hashCode ^
        selectedSection.hashCode ^
        message.hashCode ^
        pageId.hashCode;
  }
}
