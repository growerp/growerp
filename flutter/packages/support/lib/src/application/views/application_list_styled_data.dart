/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../blocs/application_bloc.dart';

List<StyledColumn> getApplicationListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);
  return [
    StyledColumn(header: 'ID', flex: isPhone ? 2 : 1),
    const StyledColumn(header: 'Version', flex: 1),
    const StyledColumn(header: 'Backend URL', flex: 2),
    const StyledColumn(header: '', flex: 1),
  ];
}

List<Widget> getApplicationListRow({
  required BuildContext context,
  required Application application,
  required int index,
  required ApplicationBloc bloc,
}) {
  return [
    Text(application.applicationId, key: Key("id$index")),
    Text(application.version ?? '', key: Key("version$index")),
    Text(application.backendUrl ?? '', key: Key("backendUrl$index")),
    IconButton(
      key: Key('delete$index'),
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.delete_forever),
      onPressed: () {
        bloc.add(ApplicationDelete(application));
      },
    ),
  ];
}
