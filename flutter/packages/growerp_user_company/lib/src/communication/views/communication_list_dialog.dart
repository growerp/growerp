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
import 'package:growerp_user_company/l10n/generated/user_company_localizations.dart';

import '../communication.dart';

/// Opens the communications of a person, or of a company plus all its
/// employees. [partyPseudoId] is the party a new communication is logged for.
Future<void> showCommunicationListDialog(
  BuildContext context, {
  String? userPseudoId,
  String? companyPseudoId,
  required String partyPseudoId,
  required String title,
}) {
  return showDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext context) => BlocProvider(
      create: (context) => CommunicationBloc(
        context.read<RestClient>(),
        userPseudoId: userPseudoId,
        companyPseudoId: companyPseudoId,
      )..add(const CommunicationFetch(refresh: true)),
      child: CommunicationListDialog(
        partyPseudoId: partyPseudoId,
        title: title,
        showParty: companyPseudoId != null,
      ),
    ),
  );
}

class CommunicationListDialog extends StatefulWidget {
  const CommunicationListDialog({
    super.key,
    required this.partyPseudoId,
    required this.title,
    this.showParty = false,
  });
  final String partyPseudoId;
  final String title;

  /// company list: show which employee the communication was with
  final bool showParty;

  @override
  CommunicationListDialogState createState() => CommunicationListDialogState();
}

class CommunicationListDialogState extends State<CommunicationListDialog> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late CommunicationBloc _bloc;
  late UserCompanyLocalizations _localizations;
  String _searchString = '';
  late double bottom;
  double? right;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<CommunicationBloc>();
    _scrollController.addListener(_onScroll);
    bottom = 50;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_bloc.state.hasReachedMax &&
        _bloc.state.status != CommunicationStatus.loading) {
      _bloc.add(CommunicationFetch(searchString: _searchString));
    }
  }

  Future<void> _openDetail(CommunicationEvent event) async {
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) =>
          BlocProvider.value(value: _bloc, child: CommunicationDialog(event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _localizations = UserCompanyLocalizations.of(context)!;
    right = right ?? (isAPhone(context) ? 20 : 50);
    return Dialog(
      key: const Key('CommunicationListDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: widget.title,
        height: isAPhone(context) ? 700 : 600,
        width: isAPhone(context) ? 400 : 900,
        child: BlocConsumer<CommunicationBloc, CommunicationState>(
          listener: (context, state) {
            if (state.status == CommunicationStatus.failure) {
              HelperFunctions.showMessage(
                context,
                '${state.message}',
                Colors.red,
              );
            }
            if (state.status == CommunicationStatus.success &&
                state.action != null) {
              HelperFunctions.showMessage(context, switch (state.action!) {
                CommunicationAction.added => _localizations.commAddSuccess,
                CommunicationAction.updated => _localizations.commUpdateSuccess,
                CommunicationAction.deleted => _localizations.commDeleteSuccess,
              }, Colors.green);
            }
          },
          builder: (context, state) {
            final events = state.communicationEvents;
            return Column(
              children: [
                ListFilterBar(
                  searchHint: _localizations.searchHintNoun(
                    _localizations.communications,
                  ),
                  searchController: _searchController,
                  onSearchChanged: (value) {
                    _searchString = value;
                    _bloc.add(
                      CommunicationFetch(refresh: true, searchString: value),
                    );
                  },
                ),
                Expanded(
                  child: Stack(
                    children: [
                      if (events.isEmpty &&
                          state.status != CommunicationStatus.loading)
                        Center(
                          child: Text(
                            _localizations.commNotFound,
                            key: const Key('empty'),
                          ),
                        )
                      else
                        StyledDataTable(
                          columns: _columns(context),
                          rows: [
                            for (int i = 0; i < events.length; i++)
                              _row(context, events[i], i),
                          ],
                          isLoading:
                              state.status == CommunicationStatus.loading &&
                              events.isEmpty,
                          scrollController: _scrollController,
                          rowHeight: isAPhone(context) ? 64 : 48,
                          onRowTap: (index) => _openDetail(events[index]),
                        ),
                      Positioned(
                        right: right,
                        bottom: bottom,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              right = right! - details.delta.dx;
                              bottom -= details.delta.dy;
                            });
                          },
                          child: FloatingActionButton(
                            key: const Key('addNewCommunication'),
                            heroTag: 'communicationAdd',
                            tooltip: _localizations.addNew,
                            onPressed: () => _openDetail(
                              CommunicationEvent(
                                partyPseudoId: widget.partyPseudoId,
                                type: CommunicationEventType.phone,
                                direction: CommunicationDirection.outgoing,
                              ),
                            ),
                            child: const Icon(Icons.add),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<StyledColumn> _columns(BuildContext context) {
    if (isAPhone(context)) {
      return [
        const StyledColumn(header: '', flex: 1),
        StyledColumn(header: _localizations.commSubject, flex: 5),
        StyledColumn(header: _localizations.commDate, flex: 3),
      ];
    }
    return [
      StyledColumn(header: _localizations.commDate, flex: 2),
      StyledColumn(header: _localizations.commType, flex: 2),
      StyledColumn(header: _localizations.commDirection, flex: 2),
      StyledColumn(header: _localizations.commSubject, flex: 4),
      if (widget.showParty)
        StyledColumn(header: _localizations.commWith, flex: 3),
    ];
  }

  List<Widget> _row(BuildContext context, CommunicationEvent event, int i) {
    final date = event.entryDate == null
        ? ''
        : event.entryDate!.toLocal().toString().substring(0, 16);
    final incoming = event.direction == CommunicationDirection.incoming;
    final party = incoming ? event.fromPartyName : event.toPartyName;
    if (isAPhone(context)) {
      return [
        Icon(
          communicationTypeIcon(event.type),
          key: Key('type$i'),
          color: incoming ? Colors.green : null,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              event.subject ?? '',
              key: Key('subject$i'),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.showParty)
              Text(party ?? '', overflow: TextOverflow.ellipsis),
          ],
        ),
        Text(date, key: Key('date$i')),
      ];
    }
    return [
      Text(date, key: Key('date$i')),
      Row(
        children: [
          Icon(communicationTypeIcon(event.type), size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              communicationTypeLabel(_localizations, event.type),
              key: Key('type$i'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      Text(
        incoming ? _localizations.commIncoming : _localizations.commOutgoing,
        key: Key('direction$i'),
      ),
      Text(
        event.subject ?? '',
        key: Key('subject$i'),
        overflow: TextOverflow.ellipsis,
      ),
      if (widget.showParty)
        Text(party ?? '', key: Key('party$i'), overflow: TextOverflow.ellipsis),
    ];
  }
}

IconData communicationTypeIcon(CommunicationEventType? type) {
  return switch (type) {
    CommunicationEventType.phone => Icons.phone,
    CommunicationEventType.email => Icons.email_outlined,
    CommunicationEventType.autoEmail => Icons.mark_email_read_outlined,
    CommunicationEventType.faceToFace => Icons.groups_outlined,
    CommunicationEventType.letter => Icons.local_post_office_outlined,
    CommunicationEventType.comment => Icons.comment_outlined,
    CommunicationEventType.message => Icons.message_outlined,
    CommunicationEventType.videoCall => Icons.videocam_outlined,
    null => Icons.help_outline,
  };
}

String communicationTypeLabel(
  UserCompanyLocalizations localizations,
  CommunicationEventType? type,
) {
  return switch (type) {
    CommunicationEventType.phone => localizations.commTypePhone,
    CommunicationEventType.email => localizations.commTypeEmail,
    CommunicationEventType.autoEmail => localizations.commTypeAutoEmail,
    CommunicationEventType.faceToFace => localizations.commTypeFaceToFace,
    CommunicationEventType.letter => localizations.commTypeLetter,
    CommunicationEventType.comment => localizations.commTypeComment,
    CommunicationEventType.message => localizations.commTypeMessage,
    CommunicationEventType.videoCall => localizations.commTypeVideoCall,
    null => '',
  };
}
