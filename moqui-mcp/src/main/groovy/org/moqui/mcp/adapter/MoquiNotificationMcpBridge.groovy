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
package org.moqui.mcp.adapter

import groovy.json.JsonOutput
import org.moqui.context.ExecutionContextFactory
import org.moqui.context.NotificationMessage
import org.moqui.context.NotificationMessageListener
import org.moqui.mcp.transport.MoquiMcpTransport
import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * Bridge that connects Moqui's NotificationMessage system to MCP notifications.
 * Implements NotificationMessageListener to receive all Moqui notifications
 * and forwards them to MCP clients via the transport layer.
 */
class MoquiNotificationMcpBridge implements NotificationMessageListener {
    protected final static Logger logger = LoggerFactory.getLogger(MoquiNotificationMcpBridge.class)

    private ExecutionContextFactory ecf
    private MoquiMcpTransport transport

    // Topic prefix for MCP-specific notifications (optional filtering)
    private static final String MCP_TOPIC_PREFIX = "mcp."

    // Whether to forward all notifications or only MCP-prefixed ones
    private boolean forwardAllNotifications = true

    /**
     * Initialize the bridge with the ECF and transport
     * Note: This method signature matches what the ECF registration expects
     */
    @Override
    void init(ExecutionContextFactory ecf) {
        this.ecf = ecf
        logger.info("MoquiNotificationMcpBridge initialized (transport not yet set)")
    }

    /**
     * Set the transport after initialization
     * @param transport The MCP transport to use for sending notifications
     */
    void setTransport(MoquiMcpTransport transport) {
        this.transport = transport
        logger.info("MoquiNotificationMcpBridge transport configured: ${transport?.class?.simpleName}")
    }

    /**
     * Configure whether to forward all notifications or only MCP-prefixed ones
     * @param forwardAll If true, forward all notifications; if false, only forward those with topic starting with 'mcp.'
     */
    void setForwardAllNotifications(boolean forwardAll) {
        this.forwardAllNotifications = forwardAll
        logger.info("MoquiNotificationMcpBridge forwardAllNotifications set to: ${forwardAll}")
    }

    @Override
    void onMessage(NotificationMessage nm) {
        if (transport == null) {
            logger.trace("Transport not configured, skipping notification: ${nm.topic}")
            return
        }

        // Optionally filter by topic prefix
        if (!forwardAllNotifications && !nm.topic?.startsWith(MCP_TOPIC_PREFIX)) {
            logger.trace("Skipping non-MCP notification: ${nm.topic}")
            return
        }

        try {
            // Convert Moqui notification → MCP notification format
            Map mcpNotification = convertToMcpNotification(nm)

            // Get target users
            Set<String> notifyUserIds = nm.getNotifyUserIds()

            if (notifyUserIds && !notifyUserIds.isEmpty()) {
                // Send to each target user's active MCP sessions
                int sentCount = 0
                for (String userId in notifyUserIds) {
                    try {
                        transport.sendNotificationToUser(userId, mcpNotification)
                        sentCount++
                        logger.debug("Sent MCP notification to user ${userId}: ${nm.topic}")
                    } catch (Exception e) {
                        logger.warn("Failed to send MCP notification to user ${userId}: ${e.message}")
                    }
                }
                logger.info("Forwarded Moqui notification '${nm.topic}' to ${sentCount} users via MCP")
            } else {
                // No specific users, could broadcast or log
                logger.debug("Notification '${nm.topic}' has no target users, skipping MCP forward")
            }

        } catch (Exception e) {
            logger.error("Error converting/sending Moqui notification to MCP: ${e.message}", e)
        }
    }

    /**
     * Convert a Moqui NotificationMessage to MCP notification format
     * @param nm The Moqui notification
     * @return The MCP notification map
     */
    private Map convertToMcpNotification(NotificationMessage nm) {
        return [
            jsonrpc: "2.0",
            method: "notifications/message",
            params: [
                level: "info",
                logger: nm.topic ?: "moqui",
                data: JsonOutput.toJson([
                    topic: nm.topic,
                    subTopic: nm.subTopic,
                    title: nm.title,
                    type: nm.type,
                    message: nm.getMessageMap() ?: [:],
                    link: nm.link,
                    showAlert: nm.isShowAlert(),
                    notificationMessageId: nm.notificationMessageId,
                    timestamp: System.currentTimeMillis()
                ])
            ]
        ]
    }

    /**
     * Create a custom MCP notification and send to specific users
     * @param topic The notification topic
     * @param title The notification title
     * @param message The message content
     * @param userIds The target user IDs
     */
    void sendMcpNotification(String topic, String title, Map message, Set<String> userIds) {
        if (transport == null) {
            logger.warn("Cannot send MCP notification: transport not configured")
            return
        }

        Map mcpNotification = [
            jsonrpc: "2.0",
            method: "notifications/message",
            params: [
                level: "info",
                logger: topic ?: "moqui.notification",
                data: JsonOutput.toJson([
                    topic: topic,
                    title: title,
                    message: message,
                    timestamp: System.currentTimeMillis()
                ])
            ]
        ]

        for (String userId in userIds) {
            try {
                transport.sendNotificationToUser(userId, mcpNotification)
                logger.debug("Sent custom MCP notification to user ${userId}: ${topic}")
            } catch (Exception e) {
                logger.warn("Failed to send custom MCP notification to user ${userId}: ${e.message}")
            }
        }
    }

    /**
     * Broadcast an MCP notification to all active sessions
     * @param topic The notification topic
     * @param title The notification title
     * @param message The message content
     */
    void broadcastMcpNotification(String topic, String title, Map message) {
        if (transport == null) {
            logger.warn("Cannot broadcast MCP notification: transport not configured")
            return
        }

        Map mcpNotification = [
            jsonrpc: "2.0",
            method: "notifications/message",
            params: [
                level: "info",
                logger: topic ?: "moqui.notification",
                data: JsonOutput.toJson([
                    topic: topic,
                    title: title,
                    message: message,
                    timestamp: System.currentTimeMillis()
                ])
            ]
        ]

        try {
            transport.broadcastNotification(mcpNotification)
            logger.info("Broadcast MCP notification: ${topic}")
        } catch (Exception e) {
            logger.error("Failed to broadcast MCP notification: ${e.message}", e)
        }
    }

    /**
     * Send a tools/list_changed notification to inform clients that available tools have changed
     */
    void notifyToolsChanged() {
        if (transport == null) {
            logger.warn("Cannot send tools changed notification: transport not configured")
            return
        }

        Map notification = [
            jsonrpc: "2.0",
            method: "notifications/tools/list_changed",
            params: [:]
        ]

        try {
            transport.broadcastNotification(notification)
            logger.info("Broadcast tools/list_changed notification")
        } catch (Exception e) {
            logger.error("Failed to broadcast tools changed notification: ${e.message}", e)
        }
    }

    /**
     * Send a resources/list_changed notification
     */
    void notifyResourcesChanged() {
        if (transport == null) return

        Map notification = [
            jsonrpc: "2.0",
            method: "notifications/resources/list_changed",
            params: [:]
        ]

        try {
            transport.broadcastNotification(notification)
            logger.info("Broadcast resources/list_changed notification")
        } catch (Exception e) {
            logger.error("Failed to broadcast resources changed notification: ${e.message}", e)
        }
    }

    /**
     * Send a progress notification for a long-running operation
     * @param sessionId The target session
     * @param progressToken The progress token
     * @param progress Current progress value
     * @param total Total progress value (optional)
     */
    void sendProgressNotification(String sessionId, String progressToken, Number progress, Number total = null) {
        if (transport == null) return

        Map notification = [
            jsonrpc: "2.0",
            method: "notifications/progress",
            params: [
                progressToken: progressToken,
                progress: progress,
                total: total
            ]
        ]

        try {
            transport.sendNotification(sessionId, notification)
            logger.debug("Sent progress notification to session ${sessionId}: ${progress}/${total ?: '?'}")
        } catch (Exception e) {
            logger.warn("Failed to send progress notification: ${e.message}")
        }
    }

    @Override
    void destroy() {
        logger.info("MoquiNotificationMcpBridge destroyed")
        this.ecf = null
        this.transport = null
    }
}
