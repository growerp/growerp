/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';

part 'website_conversion_event.dart';
part 'website_conversion_state.dart';

EventTransformer<E> websiteConversionDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// Website generator conversions. A conversion runs in the background on the
/// server, so while any row is still working this bloc polls for progress.
class WebsiteConversionBloc
    extends Bloc<WebsiteConversionEvent, WebsiteConversionState> {
  WebsiteConversionBloc(this.restClient)
    : super(const WebsiteConversionState()) {
    on<WebsiteConversionFetch>(
      _onFetch,
      transformer: websiteConversionDroppable(const Duration(milliseconds: 100)),
    );
    on<WebsiteConversionCreate>(_onCreate);
    on<WebsiteConversionDelete>(_onDelete);
    on<WebsiteConversionGetOne>(_onGetOne);
    on<WebsiteConversionExport>(_onExport);
    on<WebsiteConversionImportFile>(_onImportFile);
  }

  final RestClient restClient;
  static const int _pollSeconds = 5;
  Timer? _pollTimer;

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  /// Keep polling only while something is actually running, so an idle page is quiet.
  void _schedulePoll(List<WebsiteConversion> conversions) {
    _pollTimer?.cancel();
    if (conversions.any((c) => c.inProgress) && !isClosed) {
      _pollTimer = Timer(const Duration(seconds: _pollSeconds), () {
        if (!isClosed) {
          add(const WebsiteConversionFetch(refresh: true, background: true));
        }
      });
    }
  }

  Future<void> _onFetch(
    WebsiteConversionFetch event,
    Emitter<WebsiteConversionState> emit,
  ) async {
    if (state.status == WebsiteConversionStatus.initial && !event.background) {
      emit(state.copyWith(status: WebsiteConversionStatus.loading));
    }
    try {
      final result = await restClient.getWebsiteConversion(
        start: 0,
        limit: event.limit,
        search: event.searchString.isEmpty ? null : event.searchString,
      );
      // tell the user when a conversion finished while they were doing something else
      String? finishedMessage;
      if (event.background) {
        for (final fresh in result.websiteConversions) {
          final was = state.conversions.where(
            (c) => c.conversionId == fresh.conversionId,
          );
          if (was.isNotEmpty && was.first.inProgress && !fresh.inProgress) {
            finishedMessage = fresh.isCompleted
                ? 'Website for ${fresh.companyName} is ready'
                : 'Conversion of ${fresh.sourceUrl} failed';
          }
        }
      }

      // an open dialog reads `selected`, so it has to follow the poll too, or it
      // shows the status the conversion had when the dialog was opened forever
      WebsiteConversion? selected = state.selected;
      if (selected != null) {
        final matches = result.websiteConversions.where(
          (c) => c.conversionId == selected!.conversionId,
        );
        if (matches.isNotEmpty) {
          // the list never carries the password, keep the one we already have
          final fresh = matches.first;
          selected = fresh.generatedPassword.isEmpty
              ? fresh.copyWith(generatedPassword: selected.generatedPassword)
              : fresh;
        }
      }
      emit(
        state.copyWith(
          // a background poll must not look like a user action: an open dialog
          // closes itself on a plain success
          status: event.background
              ? WebsiteConversionStatus.pollSuccess
              : WebsiteConversionStatus.success,
          conversions: result.websiteConversions,
          selected: selected,
          message: finishedMessage,
          searchString: event.searchString,
        ),
      );
      _schedulePoll(result.websiteConversions);
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      // anything else, a json parse error above all: without this the screen
      // would sit on the loading spinner for ever with no clue why
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.failure,
          message: '$e',
        ),
      );
    }
  }

  /// Single row, the only call that returns the generated password.
  Future<void> _onGetOne(
    WebsiteConversionGetOne event,
    Emitter<WebsiteConversionState> emit,
  ) async {
    try {
      final result = await restClient.getWebsiteConversion(
        conversionId: event.conversionId,
      );
      if (result.websiteConversions.isNotEmpty) {
        emit(
          state.copyWith(
            status: WebsiteConversionStatus.pollSuccess,
            selected: result.websiteConversions.first,
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      // anything else, a json parse error above all: without this the screen
      // would sit on the loading spinner for ever with no clue why
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.failure,
          message: '$e',
        ),
      );
    }
  }

  Future<void> _onCreate(
    WebsiteConversionCreate event,
    Emitter<WebsiteConversionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: WebsiteConversionStatus.loading));
      final created = await restClient.createWebsiteConversion(
        sourceUrl: event.sourceUrl,
        companyName: event.companyName,
        adminEmail: event.adminEmail,
        adminFirstName: event.adminFirstName,
        adminLastName: event.adminLastName,
        currencyId: event.currencyId,
        applicationId: event.applicationId,
        hostNames: event.hostNames,
        maxPages: event.maxPages,
      );
      final conversions = List<WebsiteConversion>.from(state.conversions)
        ..insert(0, created);
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.success,
          conversions: conversions,
          message:
              'Conversion of ${event.sourceUrl} started in the background, '
              'the list updates when it is done...',
        ),
      );
      _schedulePoll(conversions);
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      // anything else, a json parse error above all: without this the screen
      // would sit on the loading spinner for ever with no clue why
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.failure,
          message: '$e',
        ),
      );
    }
  }

  /// Rebuild the owner-import XML so the view can save it to a file.
  Future<void> _onExport(
    WebsiteConversionExport event,
    Emitter<WebsiteConversionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: WebsiteConversionStatus.loading));
      final export = await restClient.exportWebsiteOwner(
        conversionId: event.conversion.conversionId,
      );
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.exportReady,
          export: export,
          message:
              'Exported ${export.pageCount ?? 0} pages and '
              '${export.imageCount ?? 0} images',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.failure,
          message: '$e',
        ),
      );
    }
  }

  /// Install an owner-import XML file, ours or one the /convert-website skill made.
  Future<void> _onImportFile(
    WebsiteConversionImportFile event,
    Emitter<WebsiteConversionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: WebsiteConversionStatus.loading));
      final imported = await restClient.importWebsiteFile(
        data: {'xmlText': event.xmlText, 'fileName': event.fileName},
      );
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.success,
          conversions: List<WebsiteConversion>.from(state.conversions)
            ..insert(0, imported),
          message: 'Website ${imported.companyName} installed from '
              '${event.fileName}',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.failure,
          message: '$e',
        ),
      );
    }
  }

  Future<void> _onDelete(
    WebsiteConversionDelete event,
    Emitter<WebsiteConversionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: WebsiteConversionStatus.loading));
      await restClient.deleteWebsiteConversion(
        conversionId: event.conversion.conversionId,
      );
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.success,
          conversions: List<WebsiteConversion>.from(state.conversions)
            ..removeWhere(
              (c) => c.conversionId == event.conversion.conversionId,
            ),
          message: 'Conversion removed from the list',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      // anything else, a json parse error above all: without this the screen
      // would sit on the loading spinner for ever with no clue why
      emit(
        state.copyWith(
          status: WebsiteConversionStatus.failure,
          message: '$e',
        ),
      );
    }
  }
}
