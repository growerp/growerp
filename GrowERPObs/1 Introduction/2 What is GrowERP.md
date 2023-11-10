# What is GrowERP?
GrowERP is an easy understandable system to solve the problem of normally smaller companies starting with ERP and E-Commerce. These starters select some of the smaller ERP systems and find out after some time that either the functionality is limited or that it cannot be easily adapted to specific business requirements.

All of the components of GrowERP are open source and can be used as you desire without limitations. You can install locally or use our installation in the cloud.

GrowERP provides the minimal functions required to run the administration of a company for E-Commerce, customers, suppliers, products, orders and accounting. More about the backend at either [the moqui website](https://www.moqui.org) or just as a proof of concept [at the Apache OFBiz website](https://ofbiz.apache.org)

The system also has an internal chat which is independent of Moqui but has a REST authorization link to the moqui system.

![[growerp-overview.jpg|400]]

Because the [Flutter](https://flutter.dev) framework is used, GrowERP frontend can be installed on most platforms naively i.e. can compete with other applications on that platform compared to speed, interfaces and integration.

For payment processing a Stripe interface is available which can be used in the e-commerce front-end or within the Admin package when a payment is approved.

Missing extended functions from the backend system can be relatively easily added to the frontend by providing extra screens as indicated in the GrowERP name.

The E-Commerce frontend is not using Flutter but is using the conventional html/javascript technology for speed and search engine optimization