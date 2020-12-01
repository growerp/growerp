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

class Classification {
  String classificationId;
  String description;
  bool active;

  Classification({this.classificationId, this.description, this.active});

  @override
  String toString() => 'Classification name: $description [$classificationId]';
}

List<Classification> classifications = [
  Classification(
      classificationId: 'AppAdmin',
      description:
          'Admin app to maintain backoffice data, products, categories, orders',
      active: false),
  Classification(
      classificationId: 'AppRestaurant',
      description: 'Restaurant,cafe,bar',
      active: false),
  Classification(
      classificationId: 'AppEcommerceShop',
      description: 'Ecommerce and shop',
      active: true),
  Classification(
      classificationId: 'AppHospital',
      description: 'Hospital/Clinic/Dentist/Doctor/Beauty Shop',
      active: false),
  Classification(
      classificationId: 'AppService',
      description: 'Service company, freelancer, WFH',
      active: false),
  Classification(
      classificationId: 'AppHotel',
      description: 'Hotel, Bed & Breakfeast',
      active: false),
  Classification(
      classificationId: 'AppRealtor',
      description: 'Realtor/Property management',
      active: false),
];
