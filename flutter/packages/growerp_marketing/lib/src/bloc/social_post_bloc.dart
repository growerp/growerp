import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';
import 'social_post_event.dart';
import 'social_post_state.dart';

const _socialPostSearchDebounceDuration = Duration(milliseconds: 300);
EventTransformer<SocialPostSearchRequested> socialPostSearchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.length >= 3)
        .debounce(_socialPostSearchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

/// BLoC for managing Social Posts
class SocialPostBloc extends Bloc<SocialPostEvent, SocialPostState> {
  final RestClient restClient;

  SocialPostBloc(this.restClient) : super(const SocialPostState()) {
    on<SocialPostFetch>(_onSocialPostFetch);
    on<SocialPostCreate>(_onSocialPostCreate);
    on<SocialPostUpdate>(_onSocialPostUpdate);
    on<SocialPostDelete>(_onSocialPostDelete);
    on<SocialPostDraftWithAI>(_onSocialPostDraftWithAI);
    on<SocialPostSearchRequested>(
      _onSocialPostSearchRequested,
      transformer: socialPostSearchDebounce(),
    );
    on<SocialPostPublish>(_onSocialPostPublish);
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

        emit(
          state.copyWith(
            status: SocialPostStatus.success,
            socialPosts: socialPosts,
            hasReachedMax: socialPosts.length < event.limit,
          ),
        );
      } else {
        final result = await restClient.getSocialPosts(
          start: state.socialPosts.length,
          limit: event.limit,
          searchString: event.searchString,
          planId: event.planId,
        );

        final socialPosts = result.socialPosts;

        emit(
          state.copyWith(
            status: SocialPostStatus.success,
            socialPosts: List.of(state.socialPosts)..addAll(socialPosts),
            hasReachedMax: socialPosts.length < event.limit,
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: SocialPostStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: SocialPostStatus.failure, message: e.toString()),
      );
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

      emit(
        state.copyWith(
          status: SocialPostStatus.success,
          socialPosts: updatedSocialPosts,
          message: 'Social post created successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: SocialPostStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: SocialPostStatus.failure, message: e.toString()),
      );
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
          .map(
            (p) => p.postId == event.socialPost.postId ? updatedSocialPost : p,
          )
          .toList();

      emit(
        state.copyWith(
          status: SocialPostStatus.success,
          socialPosts: updatedSocialPosts,
          message: 'Social post updated successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: SocialPostStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: SocialPostStatus.failure, message: e.toString()),
      );
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

      emit(
        state.copyWith(
          status: SocialPostStatus.success,
          socialPosts: updatedSocialPosts,
          message: 'Social post deleted successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: SocialPostStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: SocialPostStatus.failure, message: e.toString()),
      );
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

      emit(
        state.copyWith(
          status: SocialPostStatus.success,
          socialPosts: updatedSocialPosts,
          message: 'AI draft generated successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: SocialPostStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: SocialPostStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onSocialPostSearchRequested(
    SocialPostSearchRequested event,
    Emitter<SocialPostState> emit,
  ) async {
    return _onSocialPostFetch(
      SocialPostFetch(refresh: true, searchString: event.searchString),
      emit,
    );
  }

  Future<void> _onSocialPostPublish(
    SocialPostPublish event,
    Emitter<SocialPostState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SocialPostStatus.loading));

      final publishedPost = await restClient.publishSocialPost(
        postId: event.postId,
      );

      final updatedSocialPosts = state.socialPosts.map((p) {
        if (p.postId == event.postId) return publishedPost;
        return p;
      }).toList();

      emit(
        state.copyWith(
          status: SocialPostStatus.success,
          socialPosts: updatedSocialPosts,
          message: 'Post published successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: SocialPostStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: SocialPostStatus.failure, message: e.toString()),
      );
    }
  }
}
