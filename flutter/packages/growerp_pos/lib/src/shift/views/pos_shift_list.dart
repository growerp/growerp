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
import 'package:growerp_core/growerp_core.dart';

import '../../../l10n/generated/pos_localizations.dart';
import '../blocs/pos_shift_bloc.dart';
import 'pos_z_report_dialog.dart';

/// All shifts of the company, the last first. A row opens its report.
class PosShiftList extends StatefulWidget {
  const PosShiftList({super.key});

  @override
  PosShiftListState createState() => PosShiftListState();
}

class PosShiftListState extends State<PosShiftList> {
  final _scrollController = ScrollController();
  late PosShiftBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<PosShiftBloc>()
      ..add(const PosShiftListFetch(refresh: true));
    _scrollController.addListener(() {
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 100) {
        _bloc.add(const PosShiftListFetch());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    final currencyId =
        context
            .read<AuthBloc>()
            .state
            .authenticate
            ?.company
            ?.currency
            ?.currencyId ??
        'USD';
    return BlocConsumer<PosShiftBloc, PosShiftState>(
      listener: (context, state) {
        if (state.status == PosShiftStatus.failure) {
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
        if (state.status == PosShiftStatus.reported) {
          showDialog(
            context: context,
            builder: (_) =>
                PosZReportDialog(state.report!, currencyId: currencyId),
          );
        }
      },
      builder: (context, state) {
        return StyledDataTable(
          key: const Key('PosShiftList'),
          columns: [
            StyledColumn(header: localizations.till, flex: 3),
            StyledColumn(header: localizations.opened, flex: 3),
            StyledColumn(header: localizations.closed, flex: 3),
            StyledColumn(header: localizations.variance, flex: 2),
          ],
          rows: state.shifts.indexed
              .map(
                (entry) => [
                  SizedBox(
                    key: Key('item${entry.$1}'),
                    child: Text(
                      entry.$2.terminalName ?? '',
                      key: Key('name${entry.$1}'),
                    ),
                  ),
                  Text(_date(entry.$2.openedDate)),
                  Text(_date(entry.$2.closedDate)),
                  Text(
                    entry.$2.variance.currency(currencyId: currencyId),
                    key: Key('variance${entry.$1}'),
                  ),
                ],
              )
              .toList(),
          isLoading:
              state.status == PosShiftStatus.loading && state.shifts.isEmpty,
          scrollController: _scrollController,
          rowHeight: isAPhone(context) ? 64 : 56,
          onRowTap: (index) =>
              _bloc.add(PosZReportFetch(state.shifts[index].shiftId!)),
        );
      },
    );
  }

  String _date(DateTime? date) =>
      date == null ? '' : date.toLocal().toString().substring(0, 16);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
