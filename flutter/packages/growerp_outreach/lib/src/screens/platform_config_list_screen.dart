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
                      (c) =>
                          c?.platform.toUpperCase() ==
                          platform.name.toUpperCase(),
                      orElse: () => null,
                    );
            return PlatformConfigData(platform: platform, config: config);
          }).toList();

          return Column(
            children: [
              // Header bar
              const ListFilterBar(
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
