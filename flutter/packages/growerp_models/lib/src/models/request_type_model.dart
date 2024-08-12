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

/// financial document (Request) types
enum RequestType {
  information('Information'),
  consultation('Consultation'),
  other('Other');

  const RequestType(this.name);
  final String name;

  static RequestType tryParse(String val) {
    switch (val) {
      case 'Information':
        return information;
      case 'Consultation':
        return consultation;
    }
    return other;
  }

  @override
  String toString() {
    return name;
  }
}
