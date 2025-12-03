import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:growerp_models/growerp_models.dart';
import 'social_post_event.dart';
import 'social_post_state.dart';

/// BLoC for managing Social Posts
class SocialPostBloc extends Bloc<SocialPostEvent, SocialPostState> {
  final RestClient restClient;

  SocialPostBloc(this.restClient) : super(const SocialPostState()) {
    on<SocialPostFetch>(_onSocialPostFetch);
    on<SocialPostCreate>(_onSocialPostCreate);
    on<SocialPostUpdate>(_onSocialPostUpdate);
    on<SocialPostDelete>(_onSocialPostDelete);
    on<SocialPostDraftWithAI>(_onSocialPostDraftWithAI);
    on<SocialPostSearchRequested>(_onSocialPostSearchRequested);
  }

  Future<void> _onSocialPostFetch(
    SocialPostFetch event,
    Emitter<SocialPostState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh) return;

    try {
      if (event.refresh || state.status == SocialPostStatus.initial) {
        emit(state.copyWith(status: SocialPostStatus.loading));

        final result = await restClient.getSocialPosts(
          start: event.start,
          limit: event.limit,
          searchString: event.searchString,
          planId: event.planId,
        );

        final socialPosts = result.socialPosts;

        emit(state.copyWith(
          status: SocialPostStatus.success,
          socialPosts: socialPosts,
          hasReachedMax: socialPosts.length < event.limit,
        ));
      } else {
        final result = await restClient.getSocialPosts(
          start: state.socialPosts.length,
          limit: event.limit,
          searchString: event.searchString,
          planId: event.planId,
        );

        final socialPosts = result.socialPosts;

        emit(state.copyWith(
          status: SocialPostStatus.success,
          socialPosts: List.of(state.socialPosts)..addAll(socialPosts),
          hasReachedMax: socialPosts.length < event.limit,
        ));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
        status: SocialPostStatus.failure,
        message: await getDioError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SocialPostStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onSocialPostCreate(
    SocialPostCreate event,
    Emitter<SocialPostState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SocialPostStatus.loading));

      final newSocialPost = await restClient.createSocialPost(
        pseudoId: event.socialPost.pseudoId,
        planId: event.socialPost.planId,
        type: event.socialPost.type,
        platform: event.socialPost.platform,
        headline: event.socialPost.headline,
        draftContent: event.socialPost.draftContent,
        finalContent: event.socialPost.finalContent,
        status: event.socialPost.status,
        scheduledDate: event.socialPost.scheduledDate?.millisecondsSinceEpoch,
      );

      final updatedSocialPosts = List<SocialPost>.from(state.socialPosts)
        ..insert(0, newSocialPost);

      emit(state.copyWith(
        status: SocialPostStatus.success,
        socialPosts: updatedSocialPosts,
        message: 'Social post created successfully',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: SocialPostStatus.failure,
        message: await getDioError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SocialPostStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onSocialPostUpdate(
    SocialPostUpdate event,
    Emitter<SocialPostState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SocialPostStatus.loading));

      final updatedSocialPost = await restClient.updateSocialPost(
        postId: event.socialPost.postId!,
        pseudoId: event.socialPost.pseudoId,
        planId: event.socialPost.planId,
        type: event.socialPost.type,
        platform: event.socialPost.platform,
        headline: event.socialPost.headline,
        draftContent: event.socialPost.draftContent,
        finalContent: event.socialPost.finalContent,
        status: event.socialPost.status,
        scheduledDate: event.socialPost.scheduledDate?.millisecondsSinceEpoch,
      );

      final updatedSocialPosts = state.socialPosts
          .map((p) =>
              p.postId == event.socialPost.postId ? updatedSocialPost : p)
          .toList();

      emit(state.copyWith(
        status: SocialPostStatus.success,
        socialPosts: updatedSocialPosts,
        message: 'Social post updated successfully',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: SocialPostStatus.failure,
        message: await getDioError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SocialPostStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onSocialPostDelete(
    SocialPostDelete event,
    Emitter<SocialPostState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SocialPostStatus.loading));

      await restClient.deleteSocialPost(postId: event.socialPost.postId!);

      final updatedSocialPosts = state.socialPosts
          .where((p) => p.postId != event.socialPost.postId)
          .toList();

      emit(state.copyWith(
        status: SocialPostStatus.success,
        socialPosts: updatedSocialPosts,
        message: 'Social post deleted successfully',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: SocialPostStatus.failure,
        message: await getDioError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SocialPostStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onSocialPostDraftWithAI(
    SocialPostDraftWithAI event,
    Emitter<SocialPostState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SocialPostStatus.loading));

      final updatedPost = await restClient.draftSocialPostWithAI(
        postId: event.postId,
      );

      // Update the post in the list with the AI-generated draft
      final updatedSocialPosts = state.socialPosts.map((p) {
        if (p.postId == event.postId) {
          return updatedPost;
        }
        return p;
      }).toList();

      emit(state.copyWith(
        status: SocialPostStatus.success,
        socialPosts: updatedSocialPosts,
        message: 'AI draft generated successfully',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: SocialPostStatus.failure,
        message: await getDioError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SocialPostStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onSocialPostSearchRequested(
    SocialPostSearchRequested event,
    Emitter<SocialPostState> emit,
  ) async {
    try {
      emit(state.copyWith(searchStatus: SocialPostStatus.loading));

      final result = await restClient.getSocialPosts(
        searchString: event.searchString,
        limit: 10,
      );

      emit(state.copyWith(
        searchStatus: SocialPostStatus.success,
        searchResults: result.socialPosts,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        searchStatus: SocialPostStatus.failure,
        searchError: await getDioError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        searchStatus: SocialPostStatus.failure,
        searchError: e.toString(),
      ));
    }
  }
}
