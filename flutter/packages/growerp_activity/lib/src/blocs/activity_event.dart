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

part of 'activity_bloc.dart';

abstract class ActivityEvent extends Equatable {
  const ActivityEvent();
  @override
  List<Object> get props => [];
}

class ActivityFetch extends ActivityEvent {
  const ActivityFetch({
    this.limit = 20,
    this.my = true,
    this.searchString = '',
    this.refresh = false,
    this.isForDropDown = false,
    this.activityId = '',
    this.activityType = ActivityType.unkwown,
    this.companyUser,
  });
  final bool my;
  final String searchString;
  final bool refresh;
  final int limit;
  final bool isForDropDown;
  final String activityId;
  final ActivityType activityType;
  final CompanyUser? companyUser;
  @override
  List<Object> get props => [searchString, refresh, activityId, isForDropDown];
}

class ActivityUpdate extends ActivityEvent {
  const ActivityUpdate(this.activity);
  final Activity activity;
}

class ActivityTimeEntryUpdate extends ActivityEvent {
  const ActivityTimeEntryUpdate(this.timeEntry);
  final TimeEntry timeEntry;
}

class ActivityTimeEntryDelete extends ActivityEvent {
  const ActivityTimeEntryDelete(this.timeEntry);
  final TimeEntry timeEntry;
}
