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

import '../bloc/page_section_bloc.dart';
import '../bloc/page_section_event.dart';
import '../bloc/page_section_state.dart';
import 'page_section_detail_screen.dart';
import 'package:growerp_marketing/l10n/generated/marketing_localizations.dart';

class PageSectionList extends StatefulWidget {
  final String landingPageId;
  final String? landingPagePseudoId;

  const PageSectionList({
    super.key,
    required this.landingPageId,
    this.landingPagePseudoId,
  });

  @override
  PageSectionListState createState() => PageSectionListState();
}

class PageSectionListState extends State<PageSectionList> {
  late PageSectionBloc _sectionBloc;

  @override
  void initState() {
    super.initState();
    _sectionBloc = context.read<PageSectionBloc>()
      ..add(PageSectionLoad(widget.landingPageId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        key: const Key('addSection'),
        onPressed: () async {
          await showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return BlocProvider.value(
                value: _sectionBloc,
                child: PageSectionDetailScreen(
                  landingPageId: widget.landingPageId,
                  section: const LandingPageSection(),
                ),
              );
            },
          );
        },
        tooltip: 'Add Section',
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<PageSectionBloc, PageSectionState>(
        listener: (context, state) {
          if (state.status == PageSectionStatus.failure) {
            HelperFunctions.showMessage(
              context,
              state.message ?? 'Error loading sections',
              Colors.red,
            );
          }
          if (state.status == PageSectionStatus.success &&
              (state.message ?? '').isNotEmpty) {
            HelperFunctions.showMessage(context, state.message!, Colors.green);
          }
        },
        builder: (context, state) {
          if (state.status == PageSectionStatus.loading) {
            return const LoadingIndicator();
          }

          if (state.sections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.view_list, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No sections yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add a section',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.sections.length,
            itemBuilder: (context, index) {
              final section = state.sections[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: InkWell(
                  key: Key('section${section.sectionSequence ?? index}'),
                  onTap: () async {
                    await showDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (BuildContext context) {
                        return BlocProvider.value(
                          value: _sectionBloc,
                          child: PageSectionDetailScreen(
                            landingPageId: widget.landingPageId,
                            section: section,
                          ),
                        );
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          child: Text(
                            '${section.sectionSequence ?? index + 1}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                section.sectionTitle ?? 'Untitled Section',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if ((section.sectionDescription ?? '').isNotEmpty)
                                Text(
                                  section.sectionDescription!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Move up
                                  if (index > 0)
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.arrow_upward),
                                      onPressed: () {
                                        final prev = state.sections[index - 1];
                                        _sectionBloc.add(
                                          PageSectionUpdate(
                                            pageSectionId:
                                                section.landingPageSectionId ??
                                                '',
                                            sectionTitle: section.sectionTitle,
                                            sectionDescription:
                                                section.sectionDescription,
                                            sectionImageUrl:
                                                section.sectionImageUrl,
                                            sectionSequence:
                                                prev.sectionSequence ?? index,
                                          ),
                                        );
                                        _sectionBloc.add(
                                          PageSectionUpdate(
                                            pageSectionId:
                                                prev.landingPageSectionId ?? '',
                                            sectionTitle: prev.sectionTitle,
                                            sectionDescription:
                                                prev.sectionDescription,
                                            sectionImageUrl:
                                                prev.sectionImageUrl,
                                            sectionSequence:
                                                section.sectionSequence ??
                                                index + 1,
                                          ),
                                        );
                                      },
                                    ),
                                  // Move down
                                  if (index < state.sections.length - 1)
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.arrow_downward),
                                      onPressed: () {
                                        final next = state.sections[index + 1];
                                        _sectionBloc.add(
                                          PageSectionUpdate(
                                            pageSectionId:
                                                section.landingPageSectionId ??
                                                '',
                                            sectionTitle: section.sectionTitle,
                                            sectionDescription:
                                                section.sectionDescription,
                                            sectionImageUrl:
                                                section.sectionImageUrl,
                                            sectionSequence:
                                                next.sectionSequence ??
                                                index + 2,
                                          ),
                                        );
                                        _sectionBloc.add(
                                          PageSectionUpdate(
                                            pageSectionId:
                                                next.landingPageSectionId ?? '',
                                            sectionTitle: next.sectionTitle,
                                            sectionDescription:
                                                next.sectionDescription,
                                            sectionImageUrl:
                                                next.sectionImageUrl,
                                            sectionSequence:
                                                section.sectionSequence ??
                                                index + 1,
                                          ),
                                        );
                                      },
                                    ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text(MarketingLocalizations.of(context)!.deleteSection),
                                            content: const Text(
                                              'Are you sure you want to delete this section?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                                child: Text(MarketingLocalizations.of(context)!.cancel),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                                child: Text(MarketingLocalizations.of(context)!.delete),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (confirmed == true) {
                                        _sectionBloc.add(
                                          PageSectionDelete(
                                            section.landingPageSectionId ?? '',
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
