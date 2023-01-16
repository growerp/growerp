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
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';

import '../../api_repository.dart';
import '../location.dart';
import '../widgets/widgets.dart';

class LocationListForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RepositoryProvider(
      create: (context) => InventoryAPIRepository(
          context.read<AuthBloc>().state.authenticate!.apiKey!),
      child: BlocProvider<LocationBloc>(
          create: (BuildContext context) => LocationBloc(InventoryAPIRepository(
              context.read<AuthBloc>().state.authenticate!.apiKey!))
            ..add(const LocationFetch()),
          child: LocationList()));
}

class LocationList extends StatefulWidget {
  @override
  LocationListState createState() => LocationListState();
}

class LocationListState extends State<LocationList> {
  final _scrollController = ScrollController();
  late LocationBloc _locationBloc;
  Authenticate authenticate = Authenticate();
  int limit = 20;
  String? searchString;

  @override
  void initState() {
    super.initState();
    _locationBloc = context.read<LocationBloc>();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        switch (state.status) {
          case LocationStatus.failure:
            return Center(
                child: Text('failed to fetch locations: ${state.message}'));
          case LocationStatus.success:
            return Scaffold(
                floatingActionButton: FloatingActionButton(
                    key: Key("addNew"),
                    onPressed: () async {
                      await showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return BlocProvider.value(
                                value: _locationBloc,
                                child: LocationDialog(Location()));
                          });
                    },
                    tooltip: 'Add New',
                    child: Icon(Icons.add)),
                body: RefreshIndicator(
                    onRefresh: (() async =>
                        _locationBloc.add(LocationFetch(refresh: true))),
                    child: ListView.builder(
                      key: Key('listView'),
                      physics: AlwaysScrollableScrollPhysics(),
                      itemCount: state.hasReachedMax
                          ? state.locations.length + 1
                          : state.locations.length + 2,
                      controller: _scrollController,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return Column(children: [
                            LocationListHeader(locationBloc: _locationBloc),
                            Divider(color: Colors.black),
                            Visibility(
                                visible: state.locations.isEmpty,
                                child: Center(
                                    heightFactor: 20,
                                    child: Text("No locations found",
                                        textAlign: TextAlign.center)))
                          ]);
                        }
                        index--;
                        return index >= state.locations.length
                            ? BottomLoader()
                            : Dismissible(
                                key: Key('locationItem'),
                                direction: DismissDirection.startToEnd,
                                child: LocationListItem(
                                    location: state.locations[index],
                                    index: index,
                                    isPhone: isPhone));
                      },
                    )));
          default:
            return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) context.read<LocationBloc>().add(LocationFetch());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
