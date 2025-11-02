import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'page_section_event.dart';
import 'page_section_state.dart';

class PageSectionBloc extends Bloc<PageSectionEvent, PageSectionState> {
  final RestClient restClient;

  PageSectionBloc({
    required this.restClient,
  }) : super(const PageSectionState()) {
    on<PageSectionLoad>(_onPageSectionLoad);
    on<PageSectionCreate>(_onPageSectionCreate);
    on<PageSectionUpdate>(_onPageSectionUpdate);
    on<PageSectionDelete>(_onPageSectionDelete);
    on<PageSectionClear>(_onPageSectionClear);
  }

  Future<void> _onPageSectionLoad(
    PageSectionLoad event,
    Emitter<PageSectionState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: PageSectionStatus.loading,
        pageId: event.pageId,
      ));

      final sections = await restClient.getPageSections(pageId: event.pageId);

      emit(state.copyWith(
        status: PageSectionStatus.success,
        sections: sections,
        pageId: event.pageId,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: PageSectionStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onPageSectionCreate(
    PageSectionCreate event,
    Emitter<PageSectionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PageSectionStatus.loading));

      final newSection = await restClient.createPageSection(
        pageId: event.pageId,
        sectionTitle: event.sectionTitle,
        sectionDescription: event.sectionDescription,
        sectionImageUrl: event.sectionImageUrl,
        sectionSequence: event.sectionSequence,
      );

      final updatedSections = List<LandingPageSection>.from(state.sections)
        ..add(newSection)
        ..sort((a, b) =>
            (a.sectionSequence ?? 0).compareTo(b.sectionSequence ?? 0));

      emit(state.copyWith(
        status: PageSectionStatus.success,
        sections: updatedSections,
        selectedSection: newSection,
        message: 'Section created successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: PageSectionStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onPageSectionUpdate(
    PageSectionUpdate event,
    Emitter<PageSectionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PageSectionStatus.loading));

      final updatedSection = await restClient.updatePageSection(
        pageId: state.pageId!,
        sectionId: event.sectionId,
        sectionTitle: event.sectionTitle,
        sectionDescription: event.sectionDescription,
        sectionImageUrl: event.sectionImageUrl,
        sectionSequence: event.sectionSequence,
      );

      final updatedSections = state.sections
          .map((section) => section.sectionId == updatedSection.sectionId
              ? updatedSection
              : section)
          .toList()
        ..sort((a, b) =>
            (a.sectionSequence ?? 0).compareTo(b.sectionSequence ?? 0));

      emit(state.copyWith(
        status: PageSectionStatus.success,
        sections: updatedSections,
        selectedSection: updatedSection,
        message: 'Section updated successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: PageSectionStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onPageSectionDelete(
    PageSectionDelete event,
    Emitter<PageSectionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PageSectionStatus.loading));

      await restClient.deletePageSection(
        pageId: state.pageId!,
        sectionId: event.sectionId,
      );

      final updatedSections = state.sections
          .where((section) => section.sectionId != event.sectionId)
          .toList();

      emit(state.copyWith(
        status: PageSectionStatus.success,
        sections: updatedSections,
        message: 'Section deleted successfully',
        clearSelectedSection: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: PageSectionStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onPageSectionClear(
    PageSectionClear event,
    Emitter<PageSectionState> emit,
  ) async {
    emit(state.copyWith(clearSelectedSection: true));
  }
}
