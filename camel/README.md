
This is the Camel component for GrowERP

make sure you have java 17

GrowERP still needs Java 11 (actually the reason to start a separate camel component)

compile:
mvn clean compile quarkus:dev

login to the GrowERP backend:
http://localhost:8080/vapps --> tools --> service
search for get#fruits --> run service
result should be:{"result":[{"name":"Apple","description":"Winter fruit"},{"name":"Pineapple","description":"Tropical fruit"}],"message":"OK"} 
