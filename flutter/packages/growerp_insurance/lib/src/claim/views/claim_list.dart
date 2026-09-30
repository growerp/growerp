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
import 'package:responsive_framework/responsive_framework.dart';

import '../../../growerp_insurance.dart';

/// Claims of the agency; in the client [portal] the claims of the client,
/// which the backend enforces.
class ClaimList extends StatefulWidget {
  const ClaimList({super.key, this.portal = false});
  final bool portal;

  @override
  ClaimListState createState() => ClaimListState();
}

class ClaimListState extends State<ClaimList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late ClaimBloc _claimBloc;
  late int limit;
  late double bottom;
  double? right;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _claimBloc = context.read<ClaimBloc>()
      ..add(const ClaimsFetch(refresh: true));
    _scrollController.addListener(_onScroll);
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = InsuranceLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    limit = (MediaQuery.of(context).size.height / 100).round();

    return BlocConsumer<ClaimBloc, ClaimState>(
      listener: (context, state) {
        if (state.status == ClaimStatusBloc.failure) {
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
        if (state.status == ClaimStatusBloc.success) _isLoading = false;
      },
      builder: (context, state) {
        final claims = state.claims;
        return Column(
          children: [
            ListFilterBar(
              searchHint: localizations.searchHint,
              searchController: _searchController,
              onSearchChanged: (value) =>
                  _claimBloc.add(ClaimSearchChanged(searchString: value)),
            ),
            Expanded(
              child: Stack(
                children: [
                  StyledDataTable(
                    columns: getClaimListColumns(
                      context,
                      portal: widget.portal,
                    ),
                    rows: claims
                        .map(
                          (claim) => getClaimListRow(
                            context: context,
                            claim: claim,
                            index: claims.indexOf(claim),
                            portal: widget.portal,
                          ),
                        )
                        .toList(),
                    isLoading: _isLoading && claims.isEmpty,
                    scrollController: _scrollController,
                    rowHeight: isPhone ? 72 : 56,
                    onRowTap: (index) => _showDialog(claims[index]),
                  ),
                  Positioned(
                    bottom: bottom,
                    right: right,
                    child: FloatingActionButton(
                      heroTag: widget.portal
                          ? 'insuranceMyClaimAdd'
                          : 'insuranceClaimAdd',
                      key: const Key('addNew'),
                      onPressed: () => _showDialog(Claim()),
                      tooltip: localizations.reportClaim,
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDialog(Claim claim) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) =>
          BlocProvider.value(value: _claimBloc, child: ClaimDialog(claim)),
    );
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    return _scrollController.offset >= (maxScroll * 0.9);
  }

  void _onScroll() {
    if (_isBottom) {
      _claimBloc.add(
        ClaimsFetch(limit: limit, searchString: _claimBloc.state.searchString),
      );
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }
}
