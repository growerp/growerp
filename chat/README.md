## GrowERP chat

this is companion for flutter GrowERP to enable simple chatting in a room or privately between company employees and customers/suppliers. All messages are exchanged in JSON format.

It is a component which will run independently of the Moqui backend system
but will communicate over a REST interface for user information and authorization.

to build: ./gradlew build
to run in a jetty server locally: ./gradlew appRun

### Relevant articles where this component is based on:

- [A Guide to the Java API for WebSocket](https://www.baeldung.com/java-websockets)
- [A nice simple introduction](https://learn.vonage.com/blog/2018/10/22/create-websocket-server-java-api-dr/#)

The second one is easy to create locally.
The first one a bit more difficult but was the basis of this component.

Interface to the Moqui server:
- a simple java http REST client: https://www.baeldung.com/java-http-request
- simple encode/decode json: https://www.w3schools.in/json/json-java/

start docker instance: 
    docker run -p 8081:8080 -e "DATABASEBACKEND=http://host_ip_number:8080" chat
