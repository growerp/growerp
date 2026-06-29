/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
package org.moqui.mcp.transport

import groovy.json.JsonOutput
import org.moqui.mcp.adapter.McpSession
import org.moqui.mcp.adapter.McpSessionAdapter
import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * SSE (Server-Sent Events) implementation of MoquiMcpTransport.
 * Uses McpSessionAdapter for session management and provides SSE-based message delivery.
 */
class SseTransport implements MoquiMcpTransport {
    protected final static Logger logger = LoggerFactory.getLogger(SseTransport.class)

    private final McpSessionAdapter sessionAdapter

    // Event ID counter for SSE
    private long eventIdCounter = 0

    SseTransport(McpSessionAdapter sessionAdapter) {
        this.sessionAdapter = sessionAdapter
    }

    @Override
    void openSession(String sessionId, String userId) {
        if (!sessionAdapter.hasSession(sessionId)) {
            sessionAdapter.createSession(sessionId, userId)
            logger.info("Opened SSE session ${sessionId} for user ${userId}")
        } else {
            logger.debug("Session ${sessionId} already exists")
        }
    }

    @Override
    void closeSession(String sessionId) {
        def session = sessionAdapter.getSession(sessionId)
        if (session) {
            // Try to send close event before removing
            if (session.hasActiveWriter()) {
                try {
                    def closeData = [
                        type: "disconnected",
                        sessionId: sessionId,
                        timestamp: System.currentTimeMillis()
                    ]
                    sendSseEvent(session.sseWriter, "close", JsonOutput.toJson(closeData))
                } catch (Exception e) {
                    logger.debug("Could not send close event to session ${sessionId}: ${e.message}")
                }
            }
            sessionAdapter.closeSession(sessionId)
            logger.info("Closed SSE session ${sessionId}")
        }
    }

    @Override
    boolean isSessionActive(String sessionId) {
        def session = sessionAdapter.getSession(sessionId)
        return session?.isActive() ?: false
    }

    @Override
    void sendMessage(String sessionId, Map message) {
        def session = sessionAdapter.getSession(sessionId)
        if (!session) {
            logger.warn("Cannot send message: session ${sessionId} not found")
            return
        }

        if (!session.hasActiveWriter()) {
            // Queue message for later delivery
            session.notificationQueue.add(message)
            logger.debug("Queued message for session ${sessionId} (no active writer)")
            return
        }

        try {
            String jsonMessage = JsonOutput.toJson(message)
            sendSseEvent(session.sseWriter, "message", jsonMessage)
            session.touch()
            logger.debug("Sent message to session ${sessionId}")
        } catch (Exception e) {
            logger.warn("Failed to send message to session ${sessionId}: ${e.message}")
            // Queue for later if send fails
            session.notificationQueue.add(message)
        }
    }

    @Override
    void sendNotification(String sessionId, Map notification) {
        def session = sessionAdapter.getSession(sessionId)
        if (!session) {
            logger.warn("Cannot send notification: session ${sessionId} not found")
            return
        }

        // Ensure notification has proper JSON-RPC format
        if (!notification.jsonrpc) {
            notification = [
                jsonrpc: "2.0",
                method: notification.method ?: "notifications/moqui/message",
                params: notification.params ?: notification
            ]
        }

        if (!session.hasActiveWriter()) {
            // Queue notification for later delivery
            session.notificationQueue.add(notification)
            logger.debug("Queued notification for session ${sessionId} (no active writer)")
            return
        }

        try {
            String jsonNotification = JsonOutput.toJson(notification)
            sendSseEvent(session.sseWriter, "message", jsonNotification)
            session.touch()
            logger.debug("Sent notification to session ${sessionId}: ${notification.method}")
        } catch (Exception e) {
            logger.warn("Failed to send notification to session ${sessionId}: ${e.message}")
            // Queue for later if send fails
            session.notificationQueue.add(notification)
        }
    }

    @Override
    void sendNotificationToUser(String userId, Map notification) {
        Set<String> sessionIds = sessionAdapter.getSessionsForUser(userId)
        if (sessionIds.isEmpty()) {
            logger.debug("No active sessions for user ${userId}")
            return
        }

        int sentCount = 0
        int queuedCount = 0

        for (String sessionId in sessionIds) {
            def session = sessionAdapter.getSession(sessionId)
            if (session) {
                if (session.hasActiveWriter()) {
                    try {
                        String jsonNotification = JsonOutput.toJson(notification)
                        sendSseEvent(session.sseWriter, "message", jsonNotification)
                        session.touch()
                        sentCount++
                    } catch (Exception e) {
                        logger.warn("Failed to send notification to session ${sessionId}: ${e.message}")
                        session.notificationQueue.add(notification)
                        queuedCount++
                    }
                } else {
                    session.notificationQueue.add(notification)
                    queuedCount++
                }
            }
        }

        logger.debug("Sent notification to user ${userId}: ${sentCount} delivered, ${queuedCount} queued")
    }

    @Override
    void broadcastNotification(Map notification) {
        Set<String> allSessionIds = sessionAdapter.getAllSessionIds()
        if (allSessionIds.isEmpty()) {
            logger.debug("No active sessions for broadcast")
            return
        }

        // Ensure notification has proper JSON-RPC format
        if (!notification.jsonrpc) {
            notification = [
                jsonrpc: "2.0",
                method: notification.method ?: "notifications/moqui/message",
                params: notification.params ?: notification
            ]
        }

        int sentCount = 0
        int failedCount = 0

        for (String sessionId in allSessionIds) {
            def session = sessionAdapter.getSession(sessionId)
            if (session?.hasActiveWriter()) {
                try {
                    String jsonNotification = JsonOutput.toJson(notification)
                    sendSseEvent(session.sseWriter, "message", jsonNotification)
                    session.touch()
                    sentCount++
                } catch (Exception e) {
                    logger.debug("Failed to broadcast to session ${sessionId}: ${e.message}")
                    failedCount++
                }
            } else {
                // Queue for sessions without active writers
                session?.notificationQueue?.add(notification)
            }
        }

        logger.info("Broadcast notification: ${sentCount} delivered, ${failedCount} failed")
    }

    @Override
    int getActiveSessionCount() {
        return sessionAdapter.getSessionCount()
    }

    @Override
    Set<String> getSessionsForUser(String userId) {
        return sessionAdapter.getSessionsForUser(userId)
    }

    /**
     * Register an SSE writer for a session
     * @param sessionId The session ID
     * @param writer The PrintWriter for SSE output
     */
    void registerSseWriter(String sessionId, PrintWriter writer) {
        def session = sessionAdapter.getSession(sessionId)
        if (session) {
            session.sseWriter = writer
            logger.debug("Registered SSE writer for session ${sessionId}")

            // Deliver any queued notifications
            deliverQueuedNotifications(sessionId)
        } else {
            logger.warn("Cannot register SSE writer: session ${sessionId} not found")
        }
    }

    /**
     * Unregister the SSE writer for a session (e.g., on disconnect)
     * @param sessionId The session ID
     */
    void unregisterSseWriter(String sessionId) {
        def session = sessionAdapter.getSession(sessionId)
        if (session) {
            session.sseWriter = null
            logger.debug("Unregistered SSE writer for session ${sessionId}")
        }
    }

    /**
     * Deliver any queued notifications to a session
     * @param sessionId The session ID
     */
    void deliverQueuedNotifications(String sessionId) {
        def session = sessionAdapter.getSession(sessionId)
        if (!session || !session.hasActiveWriter()) {
            return
        }

        List<Map> queue = session.notificationQueue
        if (queue.isEmpty()) {
            return
        }

        // Take snapshot and clear queue
        List<Map> toDeliver
        synchronized (queue) {
            toDeliver = new ArrayList<>(queue)
            queue.clear()
        }

        int deliveredCount = 0
        for (Map notification in toDeliver) {
            try {
                String jsonNotification = JsonOutput.toJson(notification)
                sendSseEvent(session.sseWriter, "message", jsonNotification)
                deliveredCount++
            } catch (Exception e) {
                logger.warn("Failed to deliver queued notification to ${sessionId}: ${e.message}")
                // Re-queue failed notifications
                queue.add(notification)
            }
        }

        if (deliveredCount > 0) {
            logger.debug("Delivered ${deliveredCount} queued notifications to session ${sessionId}")
        }
    }

    /**
     * Send a keep-alive ping to a session
     * @param sessionId The session ID
     * @return true if ping was sent successfully
     */
    boolean sendPing(String sessionId) {
        def session = sessionAdapter.getSession(sessionId)
        if (!session?.hasActiveWriter()) {
            return false
        }

        try {
            PrintWriter writer = session.sseWriter
            if (writer == null || writer.checkError()) {
                throw new IOException("Writer is closed or in error state")
            }
            
            synchronized(writer) {
                // Standard SSE keep-alive is a comment line starting with a colon
                writer.write(":ping\n\n")
                writer.flush()
            }
            
            if (writer.checkError()) {
                throw new IOException("Client disconnected during write")
            }
            session.touch()
            return true
        } catch (Exception e) {
            logger.debug("Failed to send ping to session ${sessionId}: ${e.message}")
            return false
        }
    }

    /**
     * Send an SSE event with proper formatting
     * @param writer The output writer
     * @param eventType The SSE event type
     * @param data The data payload
     */
    private void sendSseEvent(PrintWriter writer, String eventType, String data) throws IOException {
        if (writer == null || writer.checkError()) {
            throw new IOException("Writer is closed or in error state")
        }

        long eventId = ++eventIdCounter
        synchronized(writer) {
            writer.write("id: ${eventId}\n")
            writer.write("event: ${eventType}\n")
            writer.write("data: ${data}\n\n")
            writer.flush()
        }

        if (writer.checkError()) {
            throw new IOException("Client disconnected during write")
        }
    }

    /**
     * Send an SSE event with a specific event ID
     */
    void sendSseEventWithId(PrintWriter writer, String eventType, String data, long eventId) throws IOException {
        if (writer == null || writer.checkError()) {
            throw new IOException("Writer is closed or in error state")
        }

        synchronized(writer) {
            if (eventId >= 0) {
                writer.write("id: ${eventId}\n")
            }
            writer.write("event: ${eventType}\n")
            writer.write("data: ${data}\n\n")
            writer.flush()
        }

        if (writer.checkError()) {
            throw new IOException("Client disconnected during write")
        }
    }

    /**
     * Get the session adapter (for direct access if needed)
     */
    McpSessionAdapter getSessionAdapter() {
        return sessionAdapter
    }

    /**
     * Get transport statistics
     */
    Map getStatistics() {
        def adapterStats = sessionAdapter.getStatistics()
        int activeWriters = 0
        int totalQueued = 0

        for (String sessionId in sessionAdapter.getAllSessionIds()) {
            def session = sessionAdapter.getSession(sessionId)
            if (session) {
                if (session.hasActiveWriter()) activeWriters++
                totalQueued += session.notificationQueue.size()
            }
        }

        return adapterStats + [
            transportType: "SSE",
            activeWriters: activeWriters,
            queuedNotifications: totalQueued,
            eventIdCounter: eventIdCounter
        ]
    }
}
