# Releases

# Completed Essential functionality version 1.8.21

1. Removed separated chat server now part of Moqui backend
2. Backend notification via Websocket now notifies status background jobs
3. First Badge indicator on chat, other indicators to follow
4. Added system support app with general help function in the chat
5. Person and companies in combined selection list
6. You can use your own Stripe key on the HTML website
7. Upgraded generated website and added selenium test
8. Extended reporting with revenue/expense graphic
9. initial camel implementation using Quarkus with REST interface to the moqui backend
10. various refactoring; removed not required scaffolds, chat in own package

## Conversion Framework release October 24 2024 (v1.6.0 for Flutter 3.24.3)
#### General
1. Created a data conversion framework: a 2 step process to import existing data from comma delimited (CSV) or spreadsheet (ODS/XSLS) files.
2. Now use of the flexcolor scheme: https://pub.dev/packages/flex_color_scheme
3. Currency fields now show proper currency
4. Main company can have own domain and startup screen with just customer registration
5. Registration process now in two steps:  email/name  and other data
6. Add mixed person/company customer/supplier lists  
7. Documents(invoice/payment/order/transaction) and  product/category now have sequential or customized numbering.
8. Improved system result/confirmation messages.
9. Refactored BlocProviders and moved blocs into their own package.
10. Background automated integration test using docker.
11. Fully automated installation/upgrade using Docker.
12. Added a health app as a patient front-end to the openMRS system
13. All lists now using tables for better positioning of fields
#### Accounting
1. Accounting documents have automatic numbering or can have a manual id.
2. Accounting now shows related documents
3. Added an accounting setup: Time periods, payment and invoice type for auto posting
4. Added accounting reports: balance sheet and balance summary with period selection.
## Small fix release December 15, 2023(v1.3.0)
1. Fixed the general growerp install command
2. fixed reset password.
3. Upgrade used packages
4. Removed elastic search

## Ledger enhancement release December 8 2023(v1.2.0)
1. Any ledger organization and numbering possible by upload or manual entry.
2. Manual ledger transactions and posting added.
3. Ledger journal function added
4. Relation of order/invoice/payment/shipment documents now shown and clickable.
5. Models now in their own package: growerp_models
6. Replaced custom REST interface with Retrofit usable from flutter and from the terminal
7. GrowERP global command now again fully functional for install, import/export
8. Example programs for conversion of existing data for import into GrowERP.
9. Started a weekly mailing list related to GrowERP and ERP in general. [subscribe here!](https://birdsend.page/forms/6228/3tDTt3BLhY)
10. Added pretty logging
11. created various CSV import/exports at flutter screens

## Fault fix release August 20 2023 (v1.1.0)
1. Separate apps can now be used with the same email address
2. all packages upgraded in pub.dev
3. Admin and Hotel app can now be used again with pub.dev packages
## Release July 20 2023 (V1.0.0)
* Moqui upgraded to V3.0.0
* Monorepo: All GrowERP parts now in a single repository
* Added a Dockerfile for all required images to automatically build on dockerhub.com
* Added docker-compose file and self signed certs to run all images locally.
* Docker Inc. now [sponsors GrowERP](https://hub.docker.com/search?q=growerp) with a free dockerhub account.
* Hotel app now improved and upgraded to the new core system
* Moved often used Blocs into the core component

## Release June 5 2023 (V0.9.5)
1. Use the new [Material Design 3](https://m3.material.io/) with a switch to select dark or light mode.
2. Create account reports: balancesheet, balance posted summary.
3. Added the global command growerp to easy install and maintain the system
4. Language localisations, currently English and Thai, help us translate?
5. Now using [Melos](https://pub.dev/packages/melos) to maintain packages
6. Update the hotel app to latest packages
7. Refactoring removed not required widgets

## Release April 12 2023 (V0.9.2)
1. Now possible to have completely different ledger organizations between companies
2. Better error messages from the backend interface.
3. Payment and invoice now show only itemTypes which can be posted without errors
4. Starting from this release, developments will only be visible outside of the master branch (mostly development) and only merged after all tests are succesful and packages are available at pub.dev.
5. We now started a weekly email list to show our progress, building GrowERP both from a technical and functional point of view. [You can subscribe here](https://birdsend.page/forms/6228/3tDTt3BLhY)

## Release March 22 2023 (V0.9.1)
1. company and user now separated in bloc/views
2. all packages can be operated just with core
3. No dependencies between packages except core.
4. All tests within the specific packages
5. Overall test like roundtrip only in admin application.
6. All packages now at V0.9.0 in [pub.dev](https://pub.dev/publishers/growerp.com/packages)

## Refactoring Release February 20 2023 (V0.9.0)
1. System now split-up in packages registered in [pub.dev](https://pub.dev/publishers/growerp.com/packages)
2. Role of company now separated from security group at userlogin.
3. Reorganized the user and website detail screen.
4. Company model added to user model
5. Use of the new dart Enum.
6. Added header with close button at all dialog screens
7. Moved images into the core package
8. Lint rules now applied to all source files
9. Extended user/company/website integration tests
10. Rename files and variable names according Dart standard. 

## Production release December 20 2022 (V0.6.0)
1. User backend organization change from owner/user/company to owner/company/user
2. Finished documents like order/invoices/payment also shown when not older than one week.
3. Userlogin can be reused as customer with any other company within the system.
4. Removed internal coding for single company use. With new user organization change no special coding required when used in single mode.

## Production release November 23 2022 (V0.5.0)
1. It is now possible to use [Obsidian](https://obsidian.md/) to publish information about your company or provide documentation of your product on the generated Website. Functions supported:
	1. Internal and external linking
	2. Inclusion of external md files.
	3. Inline images
	4. Mobile/Web upload from local obsidian vault
6. GrowERP website now completely using GrowERP itself
	1. Added Google analytics
	2. [BirdSend](https://birdsend.co/) API interface for GrowERP promotion, (later for every user?)
7. The system at [growerp.com](https://admin.growerp.com) is now in production, while [growerp.org](https://admin.growerp.org) is our test system.

## Fifth beta release August 17 2022
1.  improved documentation
2.  improved category and product interface
3.  Added category & product CSV up/download
4.  Improved integration tests, now 14 in total.
5.  Removed repository history, size reduced by 75%. history now in repository [growerpuntil20220814](https://github.com/growerp/growerpuntil20220814)

## Fourth beta release July 7, 2022.
First comments from end users arrived.
1.  Upload images was limited to 200K, now larger although after upload the size will be reduced to about 200k
2.  At the html website one can now add menu dropdowns which are generated from the markdown documents
3.  On the html website available categories can now be reduced even to the stage they do not show at all.
4.  On the html website available products in the home page can now be managed.
5.  When the title of a markdown document is called it appear on the home above the products if any.
6.  The above changes mean, that the website can now be used just as a textual website without any e-commerce products.
7.  Web application has now an improved user interface taking advantage of the larger screen.

## Third beta release July 1, 2022.
1.  Automatically generated website.
    -   Maintenance from flutter frontend:
        -   logo, products and categories
        -   title, about, support, using markdown format
    -   using improved demo data
    -   multi currency
    -   multi company
2.  Api documented and available: [[7 Integration tests]] for testing with Flutter front-end
    -   in/output parameters definition
    -   authorization
    -   test/production public API sites
3.  [[Stripe]] gateway    
    -   working with E-commerce website and flutter frontend. 
4.  Flutter frontend improvements: 
    -   Added E-commerce website maintenance to flutter frontend at company -> website
    -   adding categories to products and adding products to categories improved
    -   no mandatory assignment of a product to at least a single category
    -   be able to add assets at the product screen
    -   improved demo data from Moqui PopRestStore
    -   integration tests now all fixed.
    -   A product can now be assigned to more categories
    -   Upgraded to flutter v3 with mostly latest packages.
    -   upgraded app in app/play store.
    -   More documentation.

## Second beta release May 3, 2022]
1.  Input of invoice/payment without an order with automatic posting.
2.  better integration tests.
3.  more confirmation messages.
4.  first Stripe implementation.
5.  Invoice and payment creation without Order
6.  Started documentation in docsify package

## First beta release feb 28, 2022

Changes since September 2021:
1.  All packages now in a single git branch.
2.  Reorganized the project into a domain organization see: packages/core/lib/domains
3.  Well organized integration tests for all functions.
4.  Added a warehouse function: locations, incoming/outgoing shipments.
5.  Accounting now working for purchase/sales orders and inventory changes.
6.  Improved models, backend API and adding 'freeze' and 'jsonserializer' (need to run buildrunner on core package)
7.  Introduction of smart enum classes (FinDocType,FinDocStatusVal)
8.  Upgraded to bloc V8, flutter 2.16
9.  Merged login/change password bloc into Authenticate bloc.
10.  Started new app: freelance