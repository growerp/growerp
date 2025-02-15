# Functional feature List.

The features currently implemented in the system are listed below. For a roadmap please check the  [[5 Road Map]] page

## General
* Application available on IOS/Android phone or tablet and within the browser.([Flutter](https://flutter.dev))
* Completely open source.
* Multi company/currency/language for SAAS installations.
* Single company for [Moqui](https://moqui.org) or [Apache OFBiz](https://ofbiz.apache.org) existing installations.
## User and company management
* Contactpersons and relation to companies
* Employees (admin access or not)
* Suppliers
* Customers
## Product and related categories (Catalog)
* Product types: services, physical, rental
* Products to be grouped in categories
* Standard categories and website categories
## Order management
 * Purchase and Sales
 * Items can be products, rental or without productId
 * will create invoices and payments and shipments from orders
## Inventory
* location management
* in/outgoing shipments
* Asset management
## Accounting
* Sales and purchase management
* Invoices and payments
* Automatic posting over configuration entities
* Double entry ledger
* Any ledger organization
## Marketing
* Opportunity management

# Technical feature list

The system is consisting out of three parts, the frontend built in the flutter framework, the back-end using the Moqui framework and a chat server based on Java. Build and installation instructions are the related README files.

## Flutter GrowERP Front-end
* All applications and packages are a [single repository](https://github.com/growerp/growerp).

## Moqui Backend
cloned versions, with small modifications in the 'growerp' branch (when exist)
* Framework: https://github.com/growerp/moqui-framework
* Tools: https://github.com/growerp/moqui-runtime
* Services: https://github.com/growerp/mantle-usl
* Datamodel: https://github.com/growerp/mantle-udm
* GrowERP: https://github.com/growerp/growerp-moqui
* Website: https://github.com/growerp/PopRestStore
* PDF: https://github.com/moqui/moqui-fop

## WsServer
* https://github.com/growerp/growerp-chat

