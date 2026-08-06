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

import '../blocs/activity_bloc.dart';
import 'package:growerp_activity/l10n/generated/activity_localizations.dart';

class TimeEntryListHeader extends StatelessWidget {
  const TimeEntryListHeader({super.key, required this.activityBloc});
  final ActivityBloc activityBloc;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(
        children: [
          Row(
            children: <Widget>[
              const Expanded(child: Text("Date")),
              const Text("Hours"),
              const Expanded(
                child: Text("Status", textAlign: TextAlign.center),
              ),
              if (isPhone(context))
                Expanded(
                  child: Text(ActivityLocalizations.of(context)!.activity_fromToParty, textAlign: TextAlign.center),
                ),
              if (isPhone(context))
                const Expanded(
                  child: Text("Comments", textAlign: TextAlign.center),
                ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}
