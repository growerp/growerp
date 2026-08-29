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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../../growerp_core.dart';

/// Organization -> Security: which user group may see and change which screen.
///
/// Rows are menu items rather than records, so there is no add button: a screen
/// exists because the menu has it, this grid only decides who reaches it.
class SecurityList extends StatefulWidget {
  const SecurityList({super.key});

  @override
  State<SecurityList> createState() => _SecurityListState();
}

class _SecurityListState extends State<SecurityList> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late SecurityBloc _securityBloc;

  @override
  void initState() {
    super.initState();
    _securityBloc = context.read<SecurityBloc>()..add(const SecurityFetch());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoreLocalizations.of(context)!;
    return BlocConsumer<SecurityBloc, SecurityState>(
      listener: (context, state) {
        if (state.status == SecurityStatus.failure) {
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
      },
      builder: (context, state) {
        return Column(
          key: const Key('securityList'),
          children: [
            ListFilterBar(
              searchHint: localizations.searchScreens,
              searchController: _searchController,
              onSearchChanged: (value) =>
                  _securityBloc.add(SecurityFetch(searchString: value)),
            ),
            Expanded(
              child: StyledDataTable(
                isLoading: state.status == SecurityStatus.loading,
                scrollController: _scrollController,
                columns: [
                  StyledColumn(header: localizations.screen, flex: 4),
                  StyledColumn(
                    header: localizations.adminGroup,
                    alignment: TextAlign.center,
                  ),
                  StyledColumn(
                    header: localizations.employeeGroup,
                    alignment: TextAlign.center,
                  ),
                  StyledColumn(
                    header: localizations.otherGroup,
                    alignment: TextAlign.center,
                  ),
                ],
                rows: [
                  for (int i = 0; i < state.menuItems.length; i++)
                    _buildRow(context, state.menuItems[i], i, localizations),
                ],
                onRowTap: (index) => _openDialog(state.menuItems[index].item),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildRow(
    BuildContext context,
    SecurityRow row,
    int index,
    CoreLocalizations localizations,
  ) {
    final item = row.item;
    return [
      Padding(
        key: Key('securityItem$index'),
        padding: EdgeInsets.only(left: row.depth * 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.title,
              key: Key('item$index'),
              overflow: TextOverflow.ellipsis,
            ),
            if (item.route != null)
              Text(
                item.route!,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      for (final group in grantableUserGroups)
        Center(
          child: AccessChip(
            // Index, not menuItemId: the first save clones the menu for the
            // organization and every id changes, so ids are not stable keys.
            key: Key('cell-$index-${group.name}'),
            access: accessOf(item, group),
            label: _accessLabel(accessOf(item, group), localizations),
          ),
        ),
    ];
  }

  String _accessLabel(ScreenAccess access, CoreLocalizations localizations) {
    switch (access) {
      case ScreenAccess.none:
        return localizations.accessNone;
      case ScreenAccess.view:
        return localizations.accessView;
      case ScreenAccess.write:
        return localizations.accessWrite;
    }
  }

  void _openDialog(MenuItem item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: _securityBloc,
        child: SecurityDialog(item),
      ),
    );
    // Deliberately NOT reloading MenuConfigBloc here. That bloc drives the
    // drawer, nav rail and tab bar, so reloading it rebuilds the menu shell,
    // resets the tab index and unmounts this grid - the admin gets thrown out
    // of the Security tab after every save. Changes to the editing admin's own
    // menu appear on the next menu load instead.
  }
}
