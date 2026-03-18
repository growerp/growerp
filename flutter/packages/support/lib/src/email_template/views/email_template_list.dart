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

import '../email_template.dart';

class EmailTemplateList extends StatefulWidget {
  const EmailTemplateList({super.key});

  @override
  EmailTemplateListState createState() => EmailTemplateListState();
}

class EmailTemplateListState extends State<EmailTemplateList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late EmailTemplateBloc _emailTemplateBloc;
  late List<EmailTemplate> emailTemplates;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _emailTemplateBloc = context.read<EmailTemplateBloc>()
      ..add(const EmailTemplateFetch(refresh: true));
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _tableView() {
    final isPhone = isAPhone(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            key: const Key('search'),
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _emailTemplateBloc.add(
                          const EmailTemplateFetch(
                              refresh: true, searchString: ''),
                        );
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              _emailTemplateBloc.add(
                EmailTemplateFetch(refresh: true, searchString: value),
              );
            },
          ),
        ),
        Expanded(
          child: StyledDataTable(
            columns: [
              StyledColumn(header: 'ID', flex: isPhone ? 2 : 1),
              const StyledColumn(header: 'Description', flex: 2),
              const StyledColumn(header: 'From Address', flex: 2),
              const StyledColumn(header: 'Subject', flex: 3),
            ],
            rows: emailTemplates.asMap().entries.map((entry) {
              final index = entry.key;
              final t = entry.value;
              return [
                Text(t.emailTemplateId, key: Key('id$index')),
                Text(t.description ?? '', key: Key('description$index')),
                Text(t.fromAddress ?? '', key: Key('fromAddress$index')),
                Text(t.subject ?? '', key: Key('subject$index')),
              ];
            }).toList(),
            isLoading: _isLoading && emailTemplates.isEmpty,
            scrollController: _scrollController,
            rowHeight: isPhone ? 72 : 56,
            onRowTap: (index) {
              showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return Dismissible(
                    key: const Key('dummy'),
                    direction: DismissDirection.startToEnd,
                    child: BlocProvider.value(
                      value: _emailTemplateBloc,
                      child: EmailTemplateDialog(emailTemplates[index]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmailTemplateBloc, EmailTemplateState>(
      listenWhen: (previous, current) =>
          previous.status == EmailTemplateStatus.loading,
      listener: (context, state) {
        if (state.status == EmailTemplateStatus.failure) {
          HelperFunctions.showMessage(
              context, '${state.message}', Colors.red);
        }
        if (state.status == EmailTemplateStatus.success) {
          if (state.message != null && state.message!.isNotEmpty) {
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.green);
          }
        }
      },
      builder: (context, state) {
        _isLoading = state.status == EmailTemplateStatus.loading;
        switch (state.status) {
          case EmailTemplateStatus.failure:
            return Center(
              child: Text(
                  'Failed to fetch email templates: ${state.message}'),
            );
          case EmailTemplateStatus.success:
            emailTemplates = state.emailTemplates;
            return Scaffold(
              floatingActionButton: FloatingActionButton(
                key: const Key('addNew'),
                onPressed: () {
                  showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return Dismissible(
                        key: const Key('dummy'),
                        direction: DismissDirection.startToEnd,
                        child: BlocProvider.value(
                          value: _emailTemplateBloc,
                          child: const EmailTemplateDialog(null),
                        ),
                      );
                    },
                  );
                },
                child: const Icon(Icons.add),
              ),
              body: _tableView(),
            );
          default:
            return const Center(child: LoadingIndicator());
        }
      },
    );
  }

  void _onScroll() {
    if (_isBottom) {
      _emailTemplateBloc.add(EmailTemplateFetch(
        searchString: _searchController.text,
      ));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
