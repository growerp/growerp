# GrowERP Chat Functionality

GrowERP includes a built-in, real-time chat system designed to facilitate seamless collaboration within teams and provide integrated communication channels for customer support.

## Overview

The chat system is a core component of the GrowERP ecosystem, accessible across all specialized applications (Admin, Hotel, Freelance, etc.). It enables users to communicate in real-time, share information, and stay updated on business activities without leaving the ERP environment.

## Key Features

### 1. Real-Time Messaging
Powered by WebSocket technology, the chat system ensures that messages are delivered and received instantaneously. This real-time capability is essential for fast-paced business environments and immediate customer support.

### 2. Chat Rooms
Communication is organized into chat rooms. 
- **Direct Messaging:** Private conversations between two users.
- **Group Chats:** Collaborative rooms for teams, projects, or specific departments.
- **Topic-Based Rooms:** Automatically generated or manual rooms focused on specific business entities or activities.

### 3. Unread Message Indicators
A persistent chat icon in the application's top header provides a visual badge indicating the number of unread messages across all joined chat rooms. This ensures that users never miss important updates.

### 4. Integration with Notification System
Chat is tightly integrated with the GrowERP notification system. New messages can trigger system notifications, allowing users to stay informed even when the chat dialog is closed.

### 5. Multi-Platform Support
As part of the Flutter-based frontend, the chat functionality works consistently across all supported platforms:
- **Web Browsers**
- **Mobile (Android & iOS)**
- **Desktop (Windows, macOS, Linux)**

### 6. Security and Multi-Tenancy
The chat system inherits GrowERP's robust security model:
- **Authentication:** Only authenticated users with a valid API key can connect to the chat WebSockets.
- **Authorization:** Chat room access is restricted based on room membership and user groups.
- **Multi-Tenant Isolation:** Messages are strictly isolated between different tenants (companies) using the `ownerPartyId` strategy.

## User Interface

- **Chat Icon:** Located in the AppBar, showing an unread message badge.
- **Chat Room List:** A dialog listing all active chat rooms with snippets of the latest messages and unread status.
- **Chat Window:** A dedicated messaging interface with message history, sender identification, and timestamps.

## Technical Architecture

### Backend (Moqui)
The backend implementation leverages the Moqui Framework's WebSocket capabilities:
- **`ChatEndpoint`:** Manages WebSocket connections, user presence, and message broadcasting.
- **Services:** REST services handle chat room creation, membership management, and message persistence.

### Frontend (Flutter)
The frontend is modularized into the `growerp_chat` package:
- **BLoCs:** `ChatRoomBloc` manages the list of rooms, while `ChatMessageBloc` handles individual message streams and history.
- **WebSocket Client:** A shared `WsClient` manages the persistent connection to the Moqui backend.

## Benefits for Business
- **Centralized Communication:** Reduces the need for external messaging tools, keeping business discussions within the ERP.
- **Improved Collaboration:** Enables teams to discuss orders, products, or tasks in context.
- **Customer Engagement:** Provides a foundation for integrated customer support and real-time assistance.

---
*For technical implementation details, see the [WebSocket Notification System](./WebSocket_Notification_System.md) documentation.*
