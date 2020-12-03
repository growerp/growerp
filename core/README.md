# core

This is the core package of the GrowERP frontend.

It contains all the basic functions of an ERP system:
1. login
2. logout
3. registration of new user in a existing company.
4. registration new admin and new company
5. forgot password
6. change pasword
7. tests of most functions. >50%
8. switch between companies: ecommerce.
9. 'About' form describing the App.
10. routing between forms
11. state management using flutter_bloc
12. Fully multicompany.
13. Image up/download for IOS,Android and the web.
14. Central configuration file.
15. All major entities have an image upload.

Dependent packages:

1. Moqui & Ofbiz
communication with the server

2. Models.
All models are in the models package.

Internals:

Blocs: 
1. Authentication
    connection status
    company
    loggedin user
2. Catalog
    products
    categories
3. Crm
    customers
    suppliers


