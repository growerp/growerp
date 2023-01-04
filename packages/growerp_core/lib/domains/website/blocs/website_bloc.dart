/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the websiteor(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'dart:async';
import 'dart:io';
import '../../../api_repository.dart';
import '../../../services/api_result.dart';
import '../../../services/network_exceptions.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domains.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

part 'website_event.dart';
part 'website_state.dart';

/// Websitebloc controls the connection to the backend
///
/// It contains company and user information and signals connection errrors
///
class WebsiteBloc extends Bloc<WebsiteEvent, WebsiteState> {
  WebsiteBloc(this.repos) : super(const WebsiteState()) {
    on<WebsiteFetch>(_onWebsiteFetch);
    on<WebsiteUpdate>(_onWebsiteUpdate);
    on<WebsiteObsUpload>(_onWebsiteObsUpload);
  }

  final APIRepository repos;

  Future<void> _onWebsiteFetch(
    WebsiteFetch event,
    Emitter<WebsiteState> emit,
  ) async {
    emit(state.copyWith(status: WebsiteStatus.loading));
    ApiResult<Website> result = await repos.getWebsite();
    return emit(result.when(
        success: (data) {
          return state.copyWith(
            status: WebsiteStatus.success,
            website: data,
          );
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: WebsiteStatus.failure, message: error.toString())));
  }

  Future<void> _onWebsiteUpdate(
    WebsiteUpdate event,
    Emitter<WebsiteState> emit,
  ) async {
    emit(state.copyWith(status: WebsiteStatus.loading));
    ApiResult<Website> result = await repos.updateWebsite(event.website);
    return emit(result.when(
        success: (data) {
          return state.copyWith(
              status: WebsiteStatus.success,
              website: data,
              message: 'website updated...');
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: WebsiteStatus.failure, message: error.toString())));
  }

  Future<void> _onWebsiteObsUpload(
    WebsiteObsUpload event,
    Emitter<WebsiteState> emit,
  ) async {
    emit(state.copyWith(status: WebsiteStatus.loading));
    Obsidian? input;
    if (event.path != null) {
      Directory appDocDirectory = await getApplicationDocumentsDirectory();
      final zipFile = '${appDocDirectory.path}/out.zip';
      var inputDir = Directory(event.path!);
      var encoder = ZipFileEncoder();
      encoder.create(zipFile);
      for (FileSystemEntity entity
          in inputDir.listSync(recursive: true, followLinks: false)) {
        if (entity is File && !entity.path.contains('.obsidian'))
          encoder.addFile(
              File(entity.path), entity.path.substring(event.path!.length + 1));
      }
      encoder.close();
      input = event.obsidian.copyWith(zip: await File(zipFile).readAsBytes());
    } else
      input = event.obsidian;

    ApiResult<Website> result = await repos.obsUpload(input);
    emit(state.copyWith(status: WebsiteStatus.loading));

    return emit(result.when(
        success: (data) {
          return state.copyWith(
              status: WebsiteStatus.success,
              website: data,
              message: input?.zip != null
                  ? 'obsidian zip file uploaded..'
                  : 'obsidian removed');
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: WebsiteStatus.failure, message: error.toString())));
  }
}
