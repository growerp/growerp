## GrowERP chat

this is companion for flutter GrowERP to enable simple chatting in a room or privately between company employees and customers/suppliers. All messages are exchanged in JSON format.

### Server part
It is a component which will run independently of the Moqui backend system but will communicate over a REST interface to the moqui backend for user information and authorization.

to build: ./gradlew build to run in a jetty server locally: ./gradlew appRun

### Client part
The flutter part is located in the [core package](https://github.com/growerp/growerp/tree/master/flutter/packages/growerp_core/lib/src/domains/chat) and has the standard implementation with blocs, and views and even an integration test

### [](https://github.com/growerp/growerp-chat#relevant-articles-where-this-component-is-based-on)

### Relevant articles where this component is based on:
- [A Guide to the Java API for WebSocket](https://www.baeldung.com/java-websockets)
- [A nice simple introduction](https://developer.vonage.com/en/blog/create-websocket-server-java-api-dr)

The second one is easy to create locally. The first one a bit more difficult but was the basis of this component.

Interface to the Moqui server:
- [a simple java http REST client](https://www.baeldung.com/java-http-request)

start docker instance: docker run -p 8081:8080 -e "DATABASEBACKEND=http://host_ip_number:8080" chat
