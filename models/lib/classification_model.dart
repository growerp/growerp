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
  String defaultData;

  Classification(
      {this.classificationId, this.description, this.active, this.defaultData});

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
      active: true,
      defaultData: defaultCatalogEcommerce),
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
      description: 'Hotel, Bed & Breakfast',
      active: true),
  Classification(
      classificationId: 'AppRealtor',
      description: 'Realtor/Property management',
      active: false),
];

final String defaultCatalogEcommerce = '''
    { "count": "30", "categories":[   
      {
        "categoryName": "Drinks",
        "description": "this is bar category", 
        "image": "drinks",
        "products":
        [
          { "productName": "This is the first product cola",
            "image": "cola",
            "price": "23.99",
            "description": "This is a dummy description of first product cola"
          }
        ]
      },
      { "categoryName": "food",
        "description": "this is the long description of category food",
        "image": "food",
        "products": 
        [
          { "productName": "This is the second product macaroni",
            "image": "macaroni",
            "price": "17.13",
            "description": "This is a dummy description of second product macaroni"
          }
        ]
      }
    ]}
''';
