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
      ..add(GetDataEvent(() => context
          .read<RestClient>()
          .getActivity(limit: 0, activityType: widget.type)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DataFetchBloc<Activities>, DataFetchState<Activities>>(
        listener: (context, state) {
      if (state.status == DataFetchStatus.failure) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
    }, builder: (context, state) {
      if (state.status == DataFetchStatus.failure) {
        return Center(
            child: Text('failed to fetch search items: ${state.message}'));
      }
      if (state.status == DataFetchStatus.success) {
        activities = (state.data as Activities).activities;
      }
      return Stack(
        children: [
          ActivitySearchDialog(
              finDocBloc: _activityBloc,
              widget: widget,
              activities: activities),
          if (state.status == DataFetchStatus.loading) const LoadingIndicator(),
        ],
      );
    });
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: popUp(
            context: context,
            title: 'Activity Search ',
            height: 500,
            width: 350,
            child: Column(children: [
              TextFormField(
                  key: const Key('searchField'),
                  textInputAction: TextInputAction.search,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: "Search input"),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a search value?';
                    }
                    return null;
                  },
                  onFieldSubmitted: (value) => _activityBloc.add(GetDataEvent(
                      () => context.read<RestClient>().getActivity(
                          limit: 5,
                          searchString: value,
                          activityType: widget.type)))),
              const SizedBox(height: 20),
              const Text('Search results'),
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
                              child: const Center(
                                  heightFactor: 20,
                                  child: Text('No search items found (yet)',
                                      key: Key('empty'),
                                      textAlign: TextAlign.center)));
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
                                      key: Key("searchResult$index")),
                                  onTap: () => Navigator.of(context)
                                      .pop(activities[index]),
                                ));
                      }))
            ])));
  }
}
