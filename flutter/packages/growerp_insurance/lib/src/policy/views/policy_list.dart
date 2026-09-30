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

/// What a [PolicyList] shows: all policies, the policies to renew, or the
/// commission of each policy.
enum PolicyListMode { all, renewals, commissions }

/// Policies expiring within this many days are listed for renewal.
const renewalWindowDays = 60;

class PolicyList extends StatefulWidget {
  const PolicyList({super.key, this.mode = PolicyListMode.all});
  final PolicyListMode mode;

  @override
  PolicyListState createState() => PolicyListState();
}

/// Policies expiring soon which are not renewed yet.
class PolicyRenewalList extends StatelessWidget {
  const PolicyRenewalList({super.key});
  @override
  Widget build(BuildContext context) =>
      const PolicyList(mode: PolicyListMode.renewals);
}

/// Expected and received commission per policy.
class CommissionList extends StatelessWidget {
  const CommissionList({super.key});
  @override
  Widget build(BuildContext context) =>
      const PolicyList(mode: PolicyListMode.commissions);
}

class PolicyListState extends State<PolicyList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late PolicyBloc _policyBloc;
  late int limit;
  late double bottom;
  double? right;
  bool _isLoading = true;

  int get _expiringWithinDays =>
      widget.mode == PolicyListMode.renewals ? renewalWindowDays : 0;

  @override
  void initState() {
    super.initState();
    _policyBloc = context.read<PolicyBloc>()
      ..add(
        PoliciesFetch(refresh: true, expiringWithinDays: _expiringWithinDays),
      );
    _scrollController.addListener(_onScroll);
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = InsuranceLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    limit = (MediaQuery.of(context).size.height / 100).round();

    return BlocConsumer<PolicyBloc, PolicyState>(
      listener: (context, state) {
        if (state.status == PolicyStatusBloc.failure) {
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
        if (state.status == PolicyStatusBloc.success) _isLoading = false;
      },
      builder: (context, state) {
        // a renewed, lapsed or cancelled policy needs no renewal anymore
        final policies = widget.mode == PolicyListMode.renewals
            ? state.policies
                  .where(
                    (p) =>
                        p.status == PolicyStatus.active ||
                        p.status == PolicyStatus.renewalDue,
                  )
                  .toList()
            : state.policies;
        return Column(
          children: [
            ListFilterBar(
              searchHint: localizations.searchHint,
              searchController: _searchController,
              onSearchChanged: (value) =>
                  _policyBloc.add(PolicySearchChanged(searchString: value)),
            ),
            Expanded(
              child: Stack(
                children: [
                  StyledDataTable(
                    columns: getPolicyListColumns(context, widget.mode),
                    rows: policies
                        .map(
                          (policy) => getPolicyListRow(
                            context: context,
                            policy: policy,
                            index: policies.indexOf(policy),
                            mode: widget.mode,
                          ),
                        )
                        .toList(),
                    isLoading: _isLoading && policies.isEmpty,
                    scrollController: _scrollController,
                    rowHeight: isPhone ? 72 : 56,
                    onRowTap: (index) => _showDialog(policies[index]),
                  ),
                  if (widget.mode == PolicyListMode.all)
                    Positioned(
                      bottom: bottom,
                      right: right,
                      child: FloatingActionButton(
                        heroTag: 'insurancePolicyAdd',
                        key: const Key('addNew'),
                        onPressed: () => _showDialog(Policy()),
                        tooltip: localizations.newPolicy,
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

  void _showDialog(Policy policy) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) => BlocProvider.value(
        value: _policyBloc,
        child: widget.mode == PolicyListMode.commissions
            ? ReceiveCommissionDialog(policy)
            : PolicyDialog(policy),
      ),
    );
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    return _scrollController.offset >= (maxScroll * 0.9);
  }

  void _onScroll() {
    if (_isBottom) {
      _policyBloc.add(
        PoliciesFetch(
          limit: limit,
          searchString: _policyBloc.state.searchString,
          expiringWithinDays: _expiringWithinDays,
        ),
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
