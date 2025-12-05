/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../bloc/platform_config_bloc.dart';
import 'platform_config_detail_screen.dart';
import 'platform_config_list_table_def.dart';

// Table padding and background decoration
const platformConfigPadding = SpanPadding(trailing: 5, leading: 5);

SpanDecoration? getPlatformConfigBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}

class PlatformConfigListScreen extends StatefulWidget {
  const PlatformConfigListScreen({super.key});

  @override
  State<PlatformConfigListScreen> createState() =>
      _PlatformConfigListScreenState();
}

class _PlatformConfigListScreenState extends State<PlatformConfigListScreen> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  late PlatformConfigBloc _platformConfigBloc;
  List<PlatformConfigData> platformData = [];

  @override
  void initState() {
    super.initState();
    _platformConfigBloc = context.read<PlatformConfigBloc>()
      ..add(const PlatformConfigFetch());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('PlatformConfigListScreen'),
      body: BlocConsumer<PlatformConfigBloc, PlatformConfigState>(
        listener: (context, state) {
          if (state.status == PlatformConfigStatus.failure) {
            HelperFunctions.showMessage(
              context,
              state.message ?? 'An error occurred',
              Colors.red,
            );
          }
          if (state.status == PlatformConfigStatus.success &&
              (state.message ?? '').isNotEmpty) {
            HelperFunctions.showMessage(
              context,
              state.message!,
              Colors.green,
            );
          }
        },
        builder: (context, state) {
          if (state.status == PlatformConfigStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Build platform data list
          platformData = OutreachPlatform.values.map((platform) {
            final config =
                state.configs.cast<PlatformConfiguration?>().firstWhere(
                      (c) => c?.platform == platform.name,
                      orElse: () => null,
                    );
            return PlatformConfigData(platform: platform, config: config);
          }).toList();

          return _buildTableView(context);
        },
      ),
    );
  }

  Widget _buildTableView(BuildContext context) {
    if (platformData.isEmpty) {
      return const Center(
        child: Text(
          'No platforms found',
          style: TextStyle(fontSize: 20.0),
        ),
      );
    }

    // Get table data formatted for tableView
    var (
      List<List<TableViewCell>> tableViewCells,
      List<double> fieldWidths,
      double? rowHeight,
    ) = get2dTableData<PlatformConfigData>(
      getPlatformConfigListTableData,
      bloc: _platformConfigBloc,
      classificationId: 'AppAdmin',
      context: context,
      items: platformData,
    );

    return TableView.builder(
      diagonalDragBehavior: DiagonalDragBehavior.free,
      verticalDetails: ScrollableDetails.vertical(
        controller: _scrollController,
      ),
      horizontalDetails: ScrollableDetails.horizontal(
        controller: _horizontalController,
      ),
      cellBuilder: (context, vicinity) =>
          tableViewCells[vicinity.row][vicinity.column],
      columnBuilder: (index) => index >= tableViewCells[0].length
          ? null
          : TableSpan(
              padding: platformConfigPadding,
              backgroundDecoration: getPlatformConfigBackGround(
                context,
                index,
              ),
              extent: FixedTableSpanExtent(fieldWidths[index]),
            ),
      pinnedColumnCount: 1,
      rowBuilder: (index) => index >= tableViewCells.length
          ? null
          : TableSpan(
              padding: platformConfigPadding,
              backgroundDecoration: getPlatformConfigBackGround(
                context,
                index,
              ),
              extent: FixedTableSpanExtent(rowHeight!),
              recognizerFactories: <Type, GestureRecognizerFactory>{
                TapGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                  () => TapGestureRecognizer(),
                  (TapGestureRecognizer t) => t.onTap = () async {
                    if (index > 0 && index <= platformData.length) {
                      final data = platformData[index - 1];
                      await showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return BlocProvider.value(
                            value: _platformConfigBloc,
                            child: PlatformConfigDetailScreen(
                              platform: data.platform,
                              config: data.config,
                            ),
                          );
                        },
                      );
                      if (mounted) {
                        _platformConfigBloc.add(const PlatformConfigFetch());
                      }
                    }
                  },
                ),
              },
            ),
      pinnedRowCount: 1,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }
}
