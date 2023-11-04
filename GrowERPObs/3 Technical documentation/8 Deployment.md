# General

## Docker environment

The initial installation can be done by installing docker on your server and using the docker-compose.yaml  in the docker directory.

However the GrowERP three images will be created locally and are better stored in https://dockerhub.com or adjusted so that they use the [growerp images](https://hub.docker.com/search?q=growerp)

You can request the ssl certificates from letsencrypt and needs to be stored in the certs directory in the form of:

the file privkey.pem need to be renamed to domainname.key
the file fullchain.pem need to be renamed to domainname.crt

wild cards are working fine.

## IOS Appstore

please check https://github.com/moqui/moqui/flutter/packages/admin/ios/README.md

## Android Playstore.

please check https://github.com/moqui/moqui/flutter/packages/admin/android/README.md

## Conversion of existing data.

To start using the system you have to initialize some data:
1. import your ledger organization if the default format does not suite you.
2. Set the starting values of the ledger accounts if you have history.
3. Importing your company information, customers, suppliers and contacts.
4. Importing your sales and purchase products, services and inventory assets.
5. Configuring your website with content, products and domain.

From this point on you can receive orders from the website, enter orders, invoices and payments and see the results in the ledger.

If you still want to continue to use your existing accounting system, you can export accounting transactions and import them into your current system.

## Convert existing data
If you have existing data, we created some example programs used in an actual conversion. You can use these as a starting point to create your conversion.

The conversion consists out of 3 steps:
1. Export the data in CSV (comma separated values) format from your existing system.
2. Create your own csvToCsv program using the example program in the  [Github repository](https://github.com/growerp/growerp/blob/development/flutter/packages/growerp/bin/csvToCsv.dart) to convert your CSV format into the GrowERP CSV format.
3. Import the generated files with the 'growerp import' command into GrowERP.

## Use the csvToCsv example program
This program shows you an example in Dart how to convert your exported CSV files into the CSV that GrowERP expects. The program should be started from the terminal and supports the following file types:
1. glAccount to convert you ledger organization with posted totals.
2. companies to import your suppliers and customers
3. products to import the product information you either buy or sell.

there are 3 parts you have to define for your conversion of every file type:
1. The actual original filenames from your current system
2. Global file content conversion in the convertFile function
3. Column remapping and column conversion in the convertRow function.
4. You can also add specific conversions by file name.


