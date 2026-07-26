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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../blocs/application_bloc.dart';

List<StyledColumn> getApplicationListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);
  return [
    StyledColumn(header: 'ID', flex: isPhone ? 2 : 1),
    const StyledColumn(header: 'Version', flex: 1),
    const StyledColumn(header: 'Backend URL', flex: 2),
    const StyledColumn(header: 'Assessment ID', flex: 1),
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
    Text(application.assessmentId ?? '', key: Key("assessmentId$index")),
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
