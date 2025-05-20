## Overview
The Moqui back-end provides [WebSocket notification services](https://github.com/growerp/growerp/blob/master/moqui/framework/src/main/groovy/org/moqui/impl/webapp/NotificationEndpoint.groovy) which we used as a basis for the new back-end [chat server](https://github.com/growerp/growerp/blob/master/moqui/framework/src/main/groovy/org/moqui/impl/webapp/ChatEndpoint.groovy) because they are both using the WebSocket protocol.

In the front-end we moved the [chat functionality in its own package](https://github.com/growerp/growerp/tree/master/flutter/packages/growerp_chat) to keep things organized. We also modified the automated tests- and docker generation scripts in the flutter directory by removing the external chat server image. 

Messaging is done in two parallel ways, one way is via Websocket to get a 'live' connection where chat message data on the screen is updated without refreshing the screen and secondly via a REST interface to save the messages in the database for history purposes and when the other user is not logged in.
## The Moqui back-end
For the WebSocket chatserver within the backend we created a new web app with the path 'chat' in the [GrowERP Moqui configuration](https://github.com/growerp/growerp/blob/master/moqui/runtime/component/growerp/MoquiConf.xml) file which will be merged with the [default configuration file](https://github.com/growerp/growerp/blob/master/moqui/framework/src/main/resources/MoquiDefaultConf.xml) and a [groovy file in the moqui webapp directory.](https://github.com/growerp/growerp/blob/master/moqui/framework/src/main/groovy/org/moqui/impl/webapp/ChatEndpoint.groovy)

The notification service where this chat endpoint is based on is relying on a user being logged in via a web browser via a HTTP session, which we obviously do not have in GrowERP because even the browser implementation of our front-end also uses the REST interface.

This problem we solved by having a rest call within the chat server with an ApiKey as part of the WebSocket connect function which will fail when the ApiKey is not valid.

Because the userid is now not available we provide its value in the WebSocket connect function send by the front-end.

## The flutter front-end
#### The chat client setup file
The [chat client](https://github.com/growerp/growerp/blob/master/flutter/packages/growerp_core/lib/src/services/ws_client.dart) provides the basic function like setting up the url for the connect service,the send , close and provide a stream of incoming data
#### the chat message bloc(business logic)
The chat message bloc will subscribe to the stream function of the client setup file when initializing and will make sure that initial unread chats are requested from the database and when chats are send, are saved in the database.|
Data incoming from the stream will be added to the list by the ChatMessageReceiveWs bloc function.
#### The chat message dialog
Finally the chat message dialog will show the data send by the message bloc
and will refresh the screen when data is added by the bloc.

This concludes the chat implementation in the back-end. Next week we will show you how you can use the Moqui notification services not just for sending messages but also for updating the order list screen automatically when orders come in.

## Websocket interface
The system uses WebSockets for real-time communication between the Flutter client and the Moqui backend. The Flutter client uses the `WsClient` class to manage the WebSocket connection, while the Moqui backend uses `NotificationEndpoint` and `NotificationWebSocketListener` to handle notifications. Chat messages are sent as JSON objects.

__Message Formats:__

- __Chat Messages:__ Chat messages are sent as JSON objects with the following structure:

```json
{
  "chatMessage": {
    "chatRoom": {
      // ChatRoom object (structure not defined here)
    },
    "fromUserId": "user123",
    "fromUserFullName": "John Doe",
    "chatMessageId": "msg456",
    "content": "Hello!",
    "creationDate": "2024-01-01T12:00:00Z"
  }
}
```

- __Notifications:__ The `NotificationEndpoint` uses `subscribe:` and `unsubscribe:` prefixes followed by a comma-separated list of topics. The actual notification messages are sent as JSON in the `messageWrapperJson` field without a prefix.

__Key Functions and Classes:__

__Flutter:__

- __`WsClient` class:__

  - `connect(String apiKey, String userId)`: Establishes the WebSocket connection.
  - `send(Object message)`: Sends messages to the server, encoding `ChatMessage` objects to JSON.
  - `stream()`: Returns a stream of messages received from the server.
  - `close()`: Closes the connection.

__Moqui:__

- __`NotificationEndpoint` class:__

  - `onOpen(Session session, EndpointConfig config)`: Registers the endpoint with the `NotificationWebSocketListener`.
  - `onMessage(String message)`: Handles subscription and unsubscription messages based on prefixes.
  - `onClose(Session session, CloseReason closeReason)`: Deregisters the endpoint.

- __`NotificationWebSocketListener` class:__

  - `registerEndpoint(NotificationEndpoint endpoint)`: Registers an endpoint.
  - `deregisterEndpoint(NotificationEndpoint endpoint)`: Deregisters an endpoint.
  - `onMessage(NotificationMessage nm)`: Sends notification messages to subscribed endpoints.

__Authentication and Authorization:__

- __Authentication:__ The Flutter client sends the `apiKey` and `userId` as query parameters when establishing the WebSocket connection. The Moqui backend then uses the `apiKey` to authenticate the user by making a REST call to `/rest/s1/growerp/100/Authenticate?classificationId=token`.
- __Authorization:__ The `NotificationEndpoint` uses a topic-based subscription mechanism to authorize which notifications a user receives. The client sends `subscribe:` and `unsubscribe:` messages to manage their subscriptions. The `NotificationWebSocketListener` then only sends messages to endpoints that are subscribed to the relevant topic.
