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

enum ActivityStatus {
  planning('In Planning'),
  progress('In progress'),
  completed('Completed'),
  onHold('On Hold'),
  closed('Closed'),
  unkwown('UnKnown');

  const ActivityStatus(this.status);
  final String status;

  static ActivityStatus tryParse(String val) {
    switch (val) {
      case 'In Planning':
        return planning;
      case 'In progress':
        return progress;
      case 'Completed':
        return completed;
      case 'On Hold':
        return onHold;
      case 'Closed':
        return closed;
    }
    return unkwown;
  }

  @override
  String toString() {
    return status;
  }

  static List<ActivityStatus> validActivityStatusList(
    ActivityStatus? currentStatus,
  ) {
    currentStatus ??= planning;
    switch (currentStatus) {
      case planning:
        return [planning, progress];
      case progress:
        return [progress, completed, onHold, closed];
      case completed:
        return [completed, progress];
      case onHold:
        return [onHold, progress, closed];
      case closed:
        return [closed, progress];
      default:
        return [];
    }
  }
}
