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

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../services/build_dio_client.dart';
import '../../../services/get_dio_error.dart';

part 'security_event.dart';
part 'security_state.dart';

/// Screen access per user group, for this organization.
///
/// Deliberately separate from MenuConfigBloc: that one holds the live, filtered
/// menu driving the drawer, nav rail and dashboard. Loading the unfiltered
/// `includeAllGroups` view into it would replace the admin's own navigation
/// with the editing view.
class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  SecurityBloc(this.restClient, this.appId) : super(const SecurityState()) {
    on<SecurityFetch>(_onSecurityFetch);
    on<SecurityUpdate>(_onSecurityUpdate);
  }

  final RestClient restClient;
  final String appId;

  Future<void> _onSecurityFetch(
    SecurityFetch event,
    Emitter<SecurityState> emit,
  ) async {
    emit(state.copyWith(status: SecurityStatus.loading));
    try {
      final config = await restClient.getMenuConfiguration(
        appId: appId,
        userVersion: true,
        includeAllGroups: true,
      );
      emit(
        state.copyWith(
          status: SecurityStatus.success,
          menuItems: _flatten(config.menuItems, event.searchString),
          searchString: event.searchString,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: SecurityStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SecurityStatus.failure, message: '$e'));
    }
  }

  Future<void> _onSecurityUpdate(
    SecurityUpdate event,
    Emitter<SecurityState> emit,
  ) async {
    emit(state.copyWith(status: SecurityStatus.loading));
    try {
      await restClient.setMenuItemGroups(
        menuItemId: event.menuItemId,
        userGroups: event.userGroups.map((g) => g.value).toList(),
        updateGroups: event.updateGroups.map((g) => g.value).toList(),
      );
      // The first save clones the seed menu for the organization, so item ids
      // change; re-read rather than patching the list in place.
      await clearRestCache();
      final config = await restClient.getMenuConfiguration(
        appId: appId,
        userVersion: true,
        includeAllGroups: true,
      );
      emit(
        state.copyWith(
          status: SecurityStatus.success,
          menuItems: _flatten(config.menuItems, state.searchString),
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: SecurityStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      // Never let an unexpected error escape the handler: an uncaught throw here
      // leaves the dialog open with no way back.
      emit(state.copyWith(status: SecurityStatus.failure, message: '$e'));
    }
  }

  /// Depth-first walk so a tab always follows the screen it belongs to. A
  /// search keeps a parent whenever one of its tabs matches, otherwise the
  /// matching tab would have nothing to sit under.
  List<SecurityRow> _flatten(List<MenuItem> items, String search) {
    final term = search.trim().toLowerCase();
    bool matches(MenuItem item) =>
        term.isEmpty ||
        item.title.toLowerCase().contains(term) ||
        (item.route ?? '').toLowerCase().contains(term);

    final rows = <SecurityRow>[];
    for (final item in items) {
      final children = (item.children ?? const <MenuItem>[])
          .where(matches)
          .toList();
      if (!matches(item) && children.isEmpty) continue;
      rows.add(SecurityRow(item, 0));
      for (final child in children) {
        rows.add(SecurityRow(child, 1));
      }
    }
    return rows;
  }
}
