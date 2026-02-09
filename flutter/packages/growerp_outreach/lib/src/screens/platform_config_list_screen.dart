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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/platform_config_bloc.dart';
import 'platform_config_detail_screen.dart';
import 'platform_config_list_styled_data.dart';

/// List screen for Platform Configurations
class PlatformConfigListScreen extends StatefulWidget {
  const PlatformConfigListScreen({super.key});

  @override
  State<PlatformConfigListScreen> createState() =>
      _PlatformConfigListScreenState();
}

class _PlatformConfigListScreenState extends State<PlatformConfigListScreen> {
  final _scrollController = ScrollController();
  late PlatformConfigBloc _platformConfigBloc;
  List<PlatformConfigData> platformData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _platformConfigBloc = context.read<PlatformConfigBloc>()
      ..add(const PlatformConfigFetch());
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = platformData.map((data) {
        final index = platformData.indexOf(data);
        return getPlatformConfigListRow(
          context: context,
          data: data,
          index: index,
          bloc: _platformConfigBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getPlatformConfigListColumns(context),
        rows: rows,
        isLoading: _isLoading && platformData.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) async {
          final data = platformData[index];
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
        },
      );
    }

    return Scaffold(
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
          // Update loading state
          _isLoading = state.status == PlatformConfigStatus.loading;

          // Build platform data list
          platformData = OutreachPlatform.values.map((platform) {
            final config =
                state.configs.cast<PlatformConfiguration?>().firstWhere(
                      (c) => c?.platform == platform.name,
                      orElse: () => null,
                    );
            return PlatformConfigData(platform: platform, config: config);
          }).toList();

          return Column(
            children: [
              // Header bar
              const ListFilterBar(
                searchHint: 'Platform configurations',
                showSearch: false,
              ),
              // Main content area with StyledDataTable
              Expanded(
                child: tableView(),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
