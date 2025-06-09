/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
      ActivityStatus? currentStatus) {
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
