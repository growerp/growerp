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

import '../../../growerp_hr.dart';

/// Leave requests; with [myRequests] only the requests of the logged in user
/// are shown (the backend limits a non admin user to its own requests anyway).
class LeaveRequestList extends StatefulWidget {
  const LeaveRequestList({super.key, this.myRequests = false});
  final bool myRequests;

  @override
  LeaveRequestListState createState() => LeaveRequestListState();
}

class LeaveRequestListState extends State<LeaveRequestList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late LeaveRequestBloc _leaveRequestBloc;
  List<LeaveRequest> leaveRequests = const <LeaveRequest>[];
  String? _myPartyId;
  late int limit;
  late double bottom;
  double? right;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _myPartyId = context.read<AuthBloc>().state.authenticate?.user?.partyId;
    _leaveRequestBloc = context.read<LeaveRequestBloc>()
      ..add(
        LeaveRequestsFetch(
          refresh: true,
          partyId: widget.myRequests ? _myPartyId : null,
        ),
      );
    if (!widget.myRequests) {
      context.read<EmployeeBloc>().add(const EmployeesFetch(refresh: true));
    }
    _scrollController.addListener(_onScroll);
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = HrLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    limit = (MediaQuery.of(context).size.height / 100).round();

    return BlocConsumer<LeaveRequestBloc, LeaveRequestState>(
      listener: (context, state) {
        if (state.status == LeaveRequestStatus.failure) {
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
        if (state.status == LeaveRequestStatus.success) _isLoading = false;
      },
      builder: (context, state) {
        leaveRequests = state.leaveRequests;
        return Column(
          children: [
            ListFilterBar(
              searchHint: localizations.searchHint,
              searchController: _searchController,
              onSearchChanged: (value) => _leaveRequestBloc.add(
                LeaveRequestSearchChanged(
                  searchString: value,
                  partyId: widget.myRequests ? _myPartyId : null,
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  StyledDataTable(
                    columns: getLeaveRequestListColumns(
                      context,
                      myRequests: widget.myRequests,
                    ),
                    rows: leaveRequests
                        .map(
                          (leaveRequest) => getLeaveRequestListRow(
                            context: context,
                            leaveRequest: leaveRequest,
                            index: leaveRequests.indexOf(leaveRequest),
                            myRequests: widget.myRequests,
                          ),
                        )
                        .toList(),
                    isLoading: _isLoading && leaveRequests.isEmpty,
                    scrollController: _scrollController,
                    rowHeight: isPhone ? 72 : 56,
                    onRowTap: (index) => _showDialog(leaveRequests[index]),
                  ),
                  Positioned(
                    bottom: bottom,
                    right: right,
                    child: FloatingActionButton(
                      heroTag: widget.myRequests
                          ? 'hrMyLeaveRequestAdd'
                          : 'hrLeaveRequestAdd',
                      key: const Key('addNew'),
                      onPressed: () =>
                          _showDialog(LeaveRequest(partyId: _myPartyId ?? '')),
                      tooltip: localizations.newLeaveRequest,
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

  void _showDialog(LeaveRequest leaveRequest) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) => BlocProvider.value(
        value: _leaveRequestBloc,
        child: LeaveRequestDialog(leaveRequest, myRequests: widget.myRequests),
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
      _leaveRequestBloc.add(
        LeaveRequestsFetch(
          limit: limit,
          partyId: widget.myRequests ? _myPartyId : null,
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
