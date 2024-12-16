Any substantial internet information system needs a back-end internet server to be able to store and process information but also to share this information with the clients which can be mobile devices or computers connected to the internet/

Since GrowERP provides ERP services, we use a back-end software system from another open source system called  [Moqui](https://www.moqui.org) We use the database data model, the services, development framework and the application server it provides. The Moqui system itself provides browser screens but in order to create an easy to use system we have replaced these with a Flutter system communicating over a REST interface.

## Rest Interface
The Moqui REST interface is customized to provide a multi company API which de-normalizes the data from the complex data model to be consumed by the Flutter front end. This Rest interface is [documented here](https://backend.growerp.com/toolstatic/lib/swagger-ui/index.html?url=https://backend.growerp.com/rest/service.swagger/growerp#/100)
## Data model
The data model the Moqui system uses is completely separated from the framework application system in a component called  'mantle-udm' in the runtime/component directory' It can be completely replaced by any other data model. The data model used is based on the [Data model resource book'](https://www.amazon.com/Data-Model-Resource-Book-Vol/dp/0471380237) and provides a very flexible business model suitable for any kind of business. 

## Database Entity model support
The database tables and views are defined in XML files which are converted by the framework in SQL statements to operate the SQL database. Upon system start the database is automatically generated from these XML files.  It also provides entity model maintenance screens similar to PG-admin or phpMyAdmin. Most SQL databases are supported.

## Service oriented architecture (SOA)
All functions are implemented as services. To access the database, automated services are generated to maintain the tables. The framework system is developed in Java while most of the business logic is using Groovy. The system provides a searchable list of all the implemented services with the in-output parameters and the implementation code.

The services are stored in components in the runtime/component directory. The system provides the mantle-usl component containing  accounting services, catalog management, warehouse and more.

## System monitoring and user maintenance
The back-end provides a number of browser screens to monitor the installation, load and user activity. User system access can be maintained, with docker image management, background job scheduling etc.
## Other Framework functions
The framework provides a complete application server with user access management, job processing, entity and service management within an application server. 

## Adding extensions.
In the same way there is a growerp component in the runtime/components, you can add your own component where you define your mount points in a componentname.rest.xml file referring to a service you define in the services directory.

See for more detailed information the [Moqui website](https://www.moqui.org)


## API
The GrowERP backend is documented in the openAPI standard:

test system at [backend.growerp.org](https://backend.growerp.org/toolstatic/lib/swagger-ui/index.html?url=https://test.growerp.org/rest/service.swagger/growerp#/100)

production system at [backend.growerp.com](https://backend.growerp.com/toolstatic/lib/swagger-ui/index.html?url=https://backend.growerp.com/rest/service.swagger/growerp#/100) 

[Or can be downloaded](https://backend.growerp.org/rest/service.swagger/growerp) 

Currently this is an open system, an API key will be provided when you register a new company and administrator.