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

import '../bloc/page_section_bloc.dart';
import '../bloc/page_section_event.dart';
import '../bloc/page_section_state.dart';
import 'page_section_detail_screen.dart';

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
            HelperFunctions.showMessage(
              context,
              state.message!,
              Colors.green,
            );
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
                key: Key('section${section.sectionSequence ?? index}'),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${section.sectionSequence ?? index + 1}'),
                  ),
                  title: Text(section.sectionTitle ?? 'Untitled Section'),
                  subtitle: Text(
                    section.sectionDescription ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Move up
                      if (index > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_upward),
                          onPressed: () {
                            final prev = state.sections[index - 1];
                            _sectionBloc.add(PageSectionUpdate(
                              pageSectionId:
                                  section.landingPageSectionId ?? '',
                              sectionTitle: section.sectionTitle,
                              sectionDescription: section.sectionDescription,
                              sectionImageUrl: section.sectionImageUrl,
                              sectionSequence:
                                  prev.sectionSequence ?? index,
                            ));
                            _sectionBloc.add(PageSectionUpdate(
                              pageSectionId:
                                  prev.landingPageSectionId ?? '',
                              sectionTitle: prev.sectionTitle,
                              sectionDescription: prev.sectionDescription,
                              sectionImageUrl: prev.sectionImageUrl,
                              sectionSequence:
                                  section.sectionSequence ?? index + 1,
                            ));
                          },
                        ),
                      // Move down
                      if (index < state.sections.length - 1)
                        IconButton(
                          icon: const Icon(Icons.arrow_downward),
                          onPressed: () {
                            final next = state.sections[index + 1];
                            _sectionBloc.add(PageSectionUpdate(
                              pageSectionId:
                                  section.landingPageSectionId ?? '',
                              sectionTitle: section.sectionTitle,
                              sectionDescription: section.sectionDescription,
                              sectionImageUrl: section.sectionImageUrl,
                              sectionSequence:
                                  next.sectionSequence ?? index + 2,
                            ));
                            _sectionBloc.add(PageSectionUpdate(
                              pageSectionId:
                                  next.landingPageSectionId ?? '',
                              sectionTitle: next.sectionTitle,
                              sectionDescription: next.sectionDescription,
                              sectionImageUrl: next.sectionImageUrl,
                              sectionSequence:
                                  section.sectionSequence ?? index + 1,
                            ));
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete Section'),
                                content: const Text(
                                  'Are you sure you want to delete this section?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
