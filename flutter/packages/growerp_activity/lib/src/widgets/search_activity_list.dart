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
import 'package:growerp_activity/l10n/generated/activity_localizations.dart';

class SearchActivityList extends StatefulWidget {
  const SearchActivityList(this.type, {super.key});
  final ActivityType type;

  @override
  SearchActivityState createState() => SearchActivityState();
}

class SearchActivityState extends State<SearchActivityList> {
  late DataFetchBloc _activityBloc;
  List<Activity> activities = [];

  @override
  void initState() {
    super.initState();
    _activityBloc = context.read<DataFetchBloc<Activities>>()
      ..add(
        GetDataEvent(
          () => context.read<RestClient>().getActivity(
            limit: 0,
            activityType: widget.type,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DataFetchBloc<Activities>, DataFetchState<Activities>>(
      listener: (context, state) {
        if (state.status == DataFetchStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
      },
      builder: (context, state) {
        if (state.status == DataFetchStatus.failure) {
          return Center(
            child: Text(
              ActivityLocalizations.of(
                context,
              )!.activity_failedToFetchSearch(state.message.toString()),
            ),
          );
        }
        if (state.status == DataFetchStatus.success) {
          activities = (state.data as Activities).activities;
        }
        return Stack(
          children: [
            ActivitySearchDialog(
              finDocBloc: _activityBloc,
              widget: widget,
              activities: activities,
            ),
            if (state.status == DataFetchStatus.loading)
              const LoadingIndicator(),
          ],
        );
      },
    );
  }
}

class ActivitySearchDialog extends StatelessWidget {
  const ActivitySearchDialog({
    super.key,
    required DataFetchBloc finDocBloc,
    required this.widget,
    required this.activities,
  }) : _activityBloc = finDocBloc;

  final DataFetchBloc _activityBloc;
  final SearchActivityList widget;
  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    return Dialog(
      key: const Key('SearchDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'Activity Search ',
        height: 500,
        width: 350,
        child: Column(
          children: [
            ListFilterBar(
              searchHint: ActivityLocalizations.of(
                context,
              )!.activity_searchInput,
              onSearchChanged: (value) {
                if (value.isNotEmpty) {
                  _activityBloc.add(
                    GetDataEvent(
                      () => context.read<RestClient>().getActivity(
                        limit: 5,
                        searchString: value,
                        activityType: widget.type,
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Text(ActivityLocalizations.of(context)!.activity_searchResults),
            Expanded(
              child: ListView.builder(
                key: const Key('listView'),
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: activities.length + 2,
                controller: scrollController,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return Visibility(
                      visible: activities.isEmpty,
                      child: Center(
                        heightFactor: 20,
                        child: Text(
                          ActivityLocalizations.of(
                            context,
                          )!.activity_noSearchItemsFound,
                          key: Key('empty'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  index--;
                  return index >= activities.length
                      ? const Text('')
                      : Dismissible(
                          key: const Key('searchItem'),
                          direction: DismissDirection.startToEnd,
                          child: ListTile(
                            title: Text(
                              "ID: ${activities[index].pseudoId}\n"
                              "Name: ${activities[index].activityName}",
                              key: Key("landingPageSearchItem$index"),
                            ),
                            onTap: () =>
                                Navigator.of(context).pop(activities[index]),
                          ),
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
