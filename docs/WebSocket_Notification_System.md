# WebSocket Notification System in GrowERP

This document explains how the WebSocket notification system works between the Moqui backend and Flutter frontend, enabling real-time notifications and messaging.

## Overview

The GrowERP system implements a comprehensive WebSocket-based notification system that provides:
- Real-time notifications from backend to frontend
- Chat messaging between users
- Topic-based subscription management
- Automatic reconnection and error handling

The system uses two main WebSocket endpoints:
1. **Chat WebSocket** (`/chat`) - For real-time chat messaging
2. **Notification WebSocket** (`/notws`) - For general notifications and system alerts

## Architecture

### Backend (Moqui)

The Moqui framework provides a comprehensive notification system based on the `NotificationMessage` interface and supporting infrastructure. This is documented in the [official Moqui documentation](https://www.moqui.org/m/docs/framework/User+Interface/Notification+and+WebSocket).

#### Core Notification Components

**NotificationMessage Interface**:
The primary interface for generating notifications to one or more users with specific topics. Key methods include:

```groovy
// Create and send a notification
ec.makeNotificationMessage()
    .topic("TestTopic")
    .type("info")
    .title("Test notification message")
    .message(messageMapOrJsonString)
    .userGroupId("ALL_USERS")
    .send()
```

**Key NotificationMessage Methods**:
- `topic(String topic)`: Set the topic identifier for message routing
- `type(NotificationType type)`: Set message type (info, success, warning, danger)
- `title(String title)`: Set display title (supports GString expansion)
- `message(Map<String, Object> message)`: Set message body as Map
- `message(String messageJson)`: Set message body as JSON string
- `userId(String userId)`: Add specific user to notification recipients
- `userGroupId(String userGroupId)`: Add user group to notification recipients
- `link(String link)`: Set link for more details (supports GString expansion)
- `showAlert(boolean show)`: Control whether to show alert dialog
- `persistOnSend(Boolean persist)`: Control message persistence
- `send()`: Send the notification

**User and Group Targeting**:
- `userId(String userId)`: Target specific users
- `userGroupId(String userGroupId)`: Target user groups (including "ALL_USERS")
- `getNotifyUserIds()`: Get all users who will receive the notification

**NotificationTopic Entity**:
Provides configuration defaults for notification topics including:
- Default title and link templates
- Email notification settings
- Alert display preferences
- Message persistence options

#### WebSocket Infrastructure
- **`NotificationEndpoint.groovy`**: Handles WebSocket connections for notifications
- **`NotificationWebSocketListener.groovy`**: Manages notification distribution to subscribed clients
- **`ChatEndpoint.groovy`**: Handles chat-specific WebSocket connections and message routing

#### Key Components

**NotificationEndpoint**:
- Manages subscription/unsubscription to notification topics using prefixes:
  - `subscribe: topic1, topic2, ALL` - Subscribe to specific topics or all topics
  - `unsubscribe: topic1, topic2` - Unsubscribe from topics
- Handles authentication via API key validation
- Routes messages based on topic subscriptions
- Extends `MoquiAbstractEndpoint` for common WebSocket functionality

**NotificationWebSocketListener**:
- Implements `NotificationMessageListener` interface
- Registers and deregisters endpoints by user ID
- Distributes notifications to subscribed users via `onMessage(NotificationMessage nm)`
- Manages topic-based message filtering
- Only sends to endpoints subscribed to "ALL" or the specific message topic

**Message Wrapper Format**:
Notifications are sent as wrapped JSON with this structure:
```json
{
  "topic": "OrderUpdate",
  "subTopic": "status_change", 
  "sentDate": "2024-01-01T12:00:00Z",
  "notificationMessageId": "12345",
  "topicDescription": "Order status changed",
  "message": { /* message body */ },
  "title": "Order Shipped",
  "link": "/order/12345",
  "type": "info",
  "persistOnSend": false,
  "showAlert": true,
  "alertNoAutoHide": false
}
```

**ChatEndpoint**:
- Handles real-time chat message broadcasting
- Validates chat room membership via REST API calls
- Manages user presence and connection status
- Broadcasts messages to chat room members only

### Frontend (Flutter)

#### Core Components
- **`WsClient`**: Generic WebSocket client for both chat and notifications
- **`NotificationBloc`**: Business logic for handling notifications
- **`ChatMessageBloc`**: Business logic for chat messaging
- **Models**: `NotificationWs`, `ChatMessage` for data representation

## WebSocket Connection Setup

### Client Connection (Flutter)

```dart
// Initialize WebSocket clients
WsClient chatClient = WsClient('chat');
WsClient notificationClient = WsClient('notws');

// Connect with authentication
await notificationClient.connect(apiKey, userId);
await chatClient.connect(apiKey, userId);
```

### URL Construction
The WebSocket URLs are constructed based on environment:

**Debug Mode**:
- Web/iOS/macOS/Linux: `ws://localhost:8080/{path}`
- Android: `ws://10.0.2.2:8080/{path}`

**Release Mode**:
- Uses configured `chatUrl` from global configuration

### Authentication
Authentication is handled via query parameters in the connection URL:
```
ws://hostname:8080/notws?apiKey={apiKey}&userId={userId}
```

The backend validates the API key by making a REST call to:
```
/rest/s1/growerp/100/Authenticate?classificationId=token
```

## Message Formats

### Notification Messages

#### Subscription/Unsubscription
```javascript
// Subscribe to topics
"subscribe: topicName1, topicName2, ALL"

// Unsubscribe from topics  
"unsubscribe: topicName1, topicName2"
```

#### Notification Message Structure
```json
{
  "notification": {
    "topic": "OrderUpdate",
    "topicDescription": "Order status changed",
    "sentDate": "2024-01-01T12:00:00Z",
    "message": {
      "orderId": "12345",
      "status": "shipped",
      "details": "Order has been shipped"
    },
    "title": "Order Shipped",
    "link": "/order/12345",
    "type": "info",
    "showAlert": true
  }
}
```

### Chat Messages

#### Chat Message Structure
```json
{
  "chatMessage": {
    "chatRoom": {
      "chatRoomId": "room123",
      "chatRoomName": "General Discussion"
    },
    "fromUserId": "user456",
    "fromUserFullName": "John Doe",
    "chatMessageId": "msg789",
    "content": "Hello everyone!",
    "creationDate": "2024-01-01T12:00:00Z"
  }
}
```

## Implementation Examples

### Setting Up Notification Listening (Flutter)

```dart
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc(this.restClient, this.notificationClient, this.authBloc)
      : super(const NotificationState()) {
    on<NotificationFetch>(_onNotificationFetch);
    on<NotificationReceive>(_onNotificationReceive);
  }

  Future<void> _onNotificationFetch(
    NotificationFetch event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.status == NotificationStatus.initial) {
      // Subscribe to all notifications
      notificationClient.send("subscribe: ALL");
      
      // Listen to WebSocket stream
      final myStream = notificationClient.stream();
      myStream.listen((data) =>
          add(NotificationReceive(NotificationWs.fromJson(jsonDecode(data)))));
    }
    
    // Fetch initial notifications from REST API
    try {
      Notifications compResult = await restClient.getNotifications(limit: 20);
      emit(state.copyWith(
        status: NotificationStatus.success,
        notifications: compResult.notifications,
      ));
    } catch (e) {
      // Handle error
    }
  }
}
```

### Handling Incoming Notifications

```dart
Future<void> _onNotificationReceive(
  NotificationReceive event,
  Emitter<NotificationState> emit,
) async {
  // Process incoming notification
  final notification = event.notification;
  
  // Show alert if requested
  if (notification.showAlert == true) {
    _showNotificationAlert(notification);
  }
  
  // Update state with new notification
  emit(state.copyWith(
    notifications: [notification, ...state.notifications],
    status: NotificationStatus.success,
  ));
}

void _showNotificationAlert(NotificationWs notification) {
  // Show system notification or in-app alert
  HelperFunctions.showMessage(
    context,
    notification.title ?? notification.message?['message'] ?? 'New notification',
    Colors.blue,
  );
}
```

### Chat Message Integration

```dart
class ChatMessageBloc extends Bloc<ChatMessageEvent, ChatMessageState> {
  Future<void> _onChatMessageFetch(
    ChatMessageFetch event,
    Emitter<ChatMessageState> emit,
  ) async {
    if (state.status == ChatMessageStatus.initial) {
      // Listen for incoming chat messages
      final myStream = chatClient.stream();
      final subscription = myStream.listen((data) =>
          add(ChatMessageReceiveWs(ChatMessage.fromJson(jsonDecode(data)))));
    }
    
    // Fetch chat history from REST API
    // ...
  }

  Future<void> _onChatMessageSendWs(
    ChatMessageSendWs event,
    Emitter<ChatMessageState> emit,
  ) async {
    try {
      // Send via WebSocket for real-time delivery
      chatClient.send(event.chatMessage);
      
      // Save to database via REST API
      await restClient.createChatMessage(chatMessage: event.chatMessage);
      
      // Update local state
      List<ChatMessage> chatMessages = List.from(state.chatMessages);
      chatMessages.insert(0, event.chatMessage);
      emit(state.copyWith(chatMessages: chatMessages));
    } catch (e) {
      // Handle error
    }
  }
}
```

## Topic-Based Subscriptions

### Common Topics
- **`ALL`**: Subscribe to all notifications (client-side subscription)
- **`OrderUpdate`**: Order status changes
- **`UserActivity`**: User login/logout events  
- **`SystemAlert`**: System maintenance notifications
- **`ImportantUpdate`**: Critical system updates
- **`DataImport`**: Data import/export notifications
- **`ServiceJobError`**: Service job failures
- **`ChatMessage`**: New chat messages (handled separately by chat endpoint)

### Topic Naming Conventions
Following Moqui best practices:
- Use PascalCase for topic names (e.g., `OrderUpdate`, `SystemAlert`)
- Use descriptive names that clearly indicate the notification purpose
- Consider using subtopics for granular filtering (e.g., `topic="Order", subTopic="StatusChange"`)

### Subscription Management

```dart
// Subscribe to specific topics
notificationClient.send("subscribe: OrderUpdate, SystemAlert");

// Subscribe to all notifications
notificationClient.send("subscribe: ALL");

// Unsubscribe from topics
notificationClient.send("unsubscribe: OrderUpdate");
```

### User-Level Topic Control
Users can control topic subscriptions via `NotificationTopicUser` entity:
- `receiveNotifications`: Enable/disable notifications for a topic
- `emailNotifications`: Enable/disable email notifications
- `allNotifications`: Receive all messages on the topic (override filters)

### Backend Topic Broadcasting (Moqui)

The Moqui framework provides several ways to send notifications:

#### Basic Notification
```groovy
// Simple notification to all users
ec.makeNotificationMessage()
    .topic("OrderUpdate")
    .type("info")
    .title("Order Status Changed")
    .message([orderId: "12345", status: "shipped"])
    .userGroupId("ALL_USERS")
    .send()
```

#### Targeted Notification
```groovy
// Notification to specific users
def notification = ec.makeNotificationMessage()
    .topic("SystemAlert")
    .type("warning") 
    .title("System Maintenance")
    .message([
        startTime: "2024-01-01T02:00:00Z",
        duration: "30 minutes",
        impact: "limited"
    ])
    .userId("admin123")
    .userId("manager456")
    .showAlert(true)
    .send()
```

#### Persistent Notifications
```groovy
// Notification that persists for offline users
ec.makeNotificationMessage()
    .topic("ImportantUpdate")
    .type("success")
    .title("Data Import Complete")
    .message([
        recordsProcessed: 1500,
        errors: 0,
        duration: "5 minutes"
    ])
    .userGroupId("DATA_MANAGERS")
    .persistOnSend(true)  // Will be saved for offline users
    .emailTemplateId("DataImportComplete")  // Also send via email
    .send()
```

#### Service Integration
```groovy
// In a Moqui service
Map<String, Object> serviceResult = ec.service.sync()
    .name("example.services.ProcessOrder")
    .parameter("orderId", orderId)
    .call()

if (serviceResult.success) {
    // Notify users of successful processing
    ec.makeNotificationMessage()
        .topic("OrderProcessing")
        .type("success")
        .title("Order Processed Successfully")
        .message([
            orderId: orderId,
            customerName: serviceResult.customerName,
            amount: serviceResult.totalAmount
        ])
        .userGroupId("ORDER_MANAGERS")
        .link("/order/detail/${orderId}")
        .send()
}
```

#### NotificationTopic Configuration
The `NotificationTopic` entity allows configuring defaults for topics:

```xml
<!-- In seed data -->
<NotificationTopic topic="OrderUpdate" 
                   description="Order status updates"
                   titleTemplate="Order ${orderId} ${status}"
                   linkTemplate="/order/${orderId}"
                   typeString="info"
                   showAlert="Y"
                   receiveNotifications="Y"
                   emailNotifications="Y"
                   emailTemplateId="OrderUpdateEmail"/>
```

## Error Handling and Reconnection

### Client-Side Error Handling

```dart
class WsClient {
  connect(String apiKey, String userId) async {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse("$wsUrl?apiKey=$apiKey&userId=$userId"),
      );
    } catch (error) {
      if (error is WebSocketChannelException) {
        logger.e('WebSocket error: ${error.message}');
        // Implement reconnection logic
        _scheduleReconnect();
      }
    }
  }

  void _scheduleReconnect() {
    Timer(Duration(seconds: 5), () {
      // Attempt to reconnect
      connect(lastApiKey, lastUserId);
    });
  }
}
```

### Connection State Management

```dart
enum WebSocketStatus { disconnected, connecting, connected, error }

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  void _onConnectionStatusChanged(ConnectionStatusChanged event) {
    switch (event.status) {
      case WebSocketStatus.disconnected:
        // Show disconnection indicator
        break;
      case WebSocketStatus.connected:
        // Resume normal operation
        break;
      case WebSocketStatus.error:
        // Show error and retry options
        break;
    }
  }
}
```

## Security Considerations

### Authentication
- API key validation on every connection via query parameters
- Backend validates API key by calling `/rest/s1/growerp/100/Authenticate?classificationId=token`
- User ID verification against authenticated session
- Automatic disconnection on invalid credentials

### Authorization  
- Topic-based access control using `NotificationTopicUser` entity
- Users can only receive notifications they're authorized for via:
  - Direct user subscription (`userId`)
  - User group membership (`userGroupId`) 
  - Topic-level permissions (`NotificationTopicUser.receiveNotifications`)
- Chat room membership validation before message delivery
- Default authorization follows "ALL_USERS" group membership

### User Notification Preferences
The system respects user preferences stored in `NotificationTopicUser`:
```sql
-- Example: User opts out of order notifications
INSERT INTO NotificationTopicUser (topic, userId, receiveNotifications, emailNotifications)
VALUES ('OrderUpdate', 'user123', 'N', 'N');

-- Example: User wants all system alerts  
INSERT INTO NotificationTopicUser (topic, userId, allNotifications, emailNotifications)
VALUES ('SystemAlert', 'manager456', 'Y', 'Y');
```

### Data Validation
- JSON message structure validation
- Content sanitization for chat messages
- Rate limiting on message sending

## Performance Optimization

### Connection Management
- Single WebSocket connection per endpoint type
- Connection pooling on backend
- Automatic cleanup of closed connections

### Message Handling
- Efficient JSON parsing using Freezed models
- Stream-based message processing
- Memory-efficient message queuing

### Scaling Considerations
- Horizontal scaling with session affinity
- Message persistence for offline users
- Load balancing WebSocket connections

## Troubleshooting

### Common Issues

**Connection Failures**:
- Check API key validity
- Verify network connectivity
- Confirm backend WebSocket endpoints are running

**Message Delivery Issues**:
- Verify topic subscriptions
- Check user authorization for topics
- Ensure proper JSON message format

**Performance Issues**:
- Monitor connection count on backend
- Check memory usage for large message volumes
- Verify efficient stream processing

### Debug Logging

Enable detailed logging in Flutter:
```dart
var logger = Logger(
  filter: ProductionFilter(), // Only log in debug mode
  printer: PrettyPrinter(lineLength: 133, methodCount: 0),
);
```

Enable WebSocket logging in Moqui:
```xml
<logger name="org.moqui.impl.webapp" level="DEBUG"/>
```

## Integration with UI

### Notification Display

```dart
class NotificationWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        return ListView.builder(
          itemCount: state.notifications.length,
          itemBuilder: (context, index) {
            final notification = state.notifications[index];
            return ListTile(
              title: Text(notification.title ?? 'Notification'),
              subtitle: Text(notification.message?['message'] ?? ''),
              trailing: Text(notification.sentDate ?? ''),
              onTap: () {
                if (notification.link != null) {
                  // Navigate to linked content
                  Navigator.pushNamed(context, notification.link!);
                }
              },
            );
          },
        );
      },
    );
  }
}
```

### Real-time UI Updates

```dart
class OrderListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<NotificationBloc, NotificationState>(
          listener: (context, state) {
            // Check for order-related notifications
            for (final notification in state.notifications) {
              if (notification.topic == 'OrderUpdate') {
                // Refresh order list
                context.read<OrderBloc>().add(OrderFetch(refresh: true));
                break;
              }
            }
          },
        ),
      ],
      child: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          // Build order list UI
          return ListView.builder(/* ... */);
        },
      ),
    );
  }
}
```

## Best Practices

### Client Implementation
1. **Single Connection**: Use one WebSocket connection per endpoint type
2. **Graceful Degradation**: Implement fallback to polling if WebSocket fails
3. **Memory Management**: Limit notification history in memory
4. **User Experience**: Show connection status to users

### Backend Implementation
1. **Resource Cleanup**: Properly close unused connections using `onClose()` methods
2. **Rate Limiting**: Implement message rate limits per user/topic
3. **Monitoring**: Log connection metrics and message volumes
4. **Security**: Validate all incoming messages and topics
5. **User Group Management**: Use Moqui's built-in "ALL_USERS" group for broadcast messages
6. **Topic Configuration**: Define `NotificationTopic` entities for consistent defaults
7. **Email Integration**: Configure `emailTemplateId` for offline user notifications
8. **Persistence Strategy**: Use `persistOnSend(true)` for critical notifications

### Message Design
1. **Topic Hierarchy**: Use clear, hierarchical topic naming (e.g., "Order.StatusChange")
2. **Message Structure**: Include essential data in message body for offline access
3. **Template Usage**: Leverage GString templates in titles and links for dynamic content
4. **Type Consistency**: Use appropriate NotificationType (info, success, warning, danger)

### Testing
1. **Unit Tests**: Test message parsing and state management
2. **Integration Tests**: Test full WebSocket communication flow with Moqui backend
3. **Load Testing**: Verify performance under high message volume using multiple topics
4. **Network Testing**: Test behavior with poor network conditions and reconnection
5. **Authorization Testing**: Verify topic-based access control and user preferences

This notification system provides a robust foundation for real-time communication in GrowERP, enabling responsive user interfaces and efficient data synchronization between frontend and backend components. It leverages Moqui's powerful notification framework with topic-based subscriptions, user preferences, email integration, and persistent messaging for offline users.

## Additional Resources

- [Official Moqui Notification Documentation](https://www.moqui.org/m/docs/framework/User+Interface/Notification+and+WebSocket)
- [Moqui Framework Source Code](https://github.com/moqui/moqui-framework)
- [GrowERP Documentation](https://www.growerp.com)
- [NotificationMessage API Reference](https://github.com/moqui/moqui-framework/blob/master/framework/src/main/java/org/moqui/context/NotificationMessage.java)
- [NotificationEndpoint Implementation](https://github.com/moqui/moqui-framework/blob/master/framework/src/main/groovy/org/moqui/impl/webapp/NotificationEndpoint.groovy)
