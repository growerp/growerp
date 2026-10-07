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

import '../../growerp_activity.dart';

/// Comments on an activity. On a task assigned to the AI agent (task loop)
/// these are the conversation with the agent: a new comment is the reply the
/// agent picks up on its next check.
class ActivityNotesDialog extends StatelessWidget {
  final String activityId;
  const ActivityNotesDialog(this.activityId, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DataFetchBloc<ActivityNotes>()
        ..add(
          GetDataEvent(
            () => context.read<RestClient>().getActivityNotes(
              activityId: activityId,
            ),
          ),
        ),
      child: _ActivityNotes(activityId),
    );
  }
}

class _ActivityNotes extends StatefulWidget {
  final String activityId;
  const _ActivityNotes(this.activityId);
  @override
  State<_ActivityNotes> createState() => _ActivityNotesState();
}

class _ActivityNotesState extends State<_ActivityNotes> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = ActivityLocalizations.of(context)!;
    return Dialog(
      key: const Key('ActivityNotesDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: localizations.activity_comments,
        height: 500,
        width: 400,
        child: Column(
          children: [
            Expanded(
              child:
                  BlocBuilder<
                    DataFetchBloc<ActivityNotes>,
                    DataFetchState<ActivityNotes>
                  >(
                    builder: (context, state) {
                      switch (state.status) {
                        case DataFetchStatus.failure:
                          return FatalErrorForm(
                            message: localizations.activity_serverError,
                          );
                        case DataFetchStatus.success:
                          final notes =
                              (state.data as ActivityNotes).activityNotes;
                          if (notes.isEmpty) {
                            return Center(
                              child: Text(localizations.activity_noComments),
                            );
                          }
                          return ListView.builder(
                            key: const Key('activityNoteList'),
                            itemCount: notes.length,
                            itemBuilder: (context, index) =>
                                _noteTile(notes[index], index, localizations),
                          );
                        default:
                          return const Center(child: LoadingIndicator());
                      }
                    },
                  ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('activityNoteText'),
                    controller: _noteController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: localizations.activity_addComment,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('activityNoteAdd'),
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final text = _noteController.text.trim();
                    if (text.isEmpty) return;
                    _noteController.clear();
                    context.read<DataFetchBloc<ActivityNotes>>().add(
                      GetDataEvent(
                        () => context.read<RestClient>().createActivityNote(
                          activityId: widget.activityId,
                          noteText: text,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteTile(
    ActivityNote note,
    int index,
    ActivityLocalizations localizations,
  ) {
    final when = note.noteDate?.toLocal().toString().substring(0, 16) ?? '';
    return ListTile(
      key: Key('activityNote$index'),
      dense: true,
      leading: Icon(note.isAgent ? Icons.smart_toy_outlined : Icons.person),
      title: Text(
        '${note.isAgent ? localizations.activity_aiAgent : note.userFullName ?? ''}  $when',
        style: Theme.of(context).textTheme.labelSmall,
      ),
      subtitle: Text(note.noteText ?? ''),
    );
  }
}
