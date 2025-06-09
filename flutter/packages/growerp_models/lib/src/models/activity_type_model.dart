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

enum ActivityType {
  todo('To Do'),
  event('Event'),
  unkwown('UnKnown');

  const ActivityType(this._name);
  final String _name;

  static ActivityType tryParse(String val) {
    switch (val.toLowerCase()) {
      case 'to do':
        return todo;
      case 'event':
        return event;
    }
    return unkwown;
  }

  @override
  String toString() {
    return _name;
  }
}
