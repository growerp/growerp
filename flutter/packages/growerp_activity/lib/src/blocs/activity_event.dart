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
    this.activityType = ActivityType.unknown,
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

/// Create an invoice from approved time entries: a sales invoice for a
/// client (sales=true) or a purchase (self-billing) invoice for an
/// assistant (sales=false, hourlyRate required).
class ActivityInvoiceFromTimeEntries extends ActivityEvent {
  const ActivityInvoiceFromTimeEntries({
    required this.sales,
    required this.partyId,
    this.hourlyRate,
  });
  final bool sales;
  final String partyId;
  final String? hourlyRate;
}
