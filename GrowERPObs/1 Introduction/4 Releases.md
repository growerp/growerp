# Releases

## Refactoring Release February 20 2022 (V0.9.0)
1. System now split-up in packages registered in [pub.dev](https://pub.dev/publishers/growerp.com/packages)
3. Role of company now separated from security group at userlogin.
4. Reorganized the user detail screen.
5. Company model added to user model
2. Use of the new dart Enum.
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
2.  Api documented and available: [[4 API]] for testing with Flutter frontend
    -   in/output parameters definition
    -   authorization
    -   test/production public API sites at test.growerp.org//rest
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