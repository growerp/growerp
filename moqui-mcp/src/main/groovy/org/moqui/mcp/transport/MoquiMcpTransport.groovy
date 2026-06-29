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

/**
 * Transport interface for MCP messages.
 * Abstracts transport concerns so implementations can be swapped (SSE, WebSocket, etc.)
 */
interface MoquiMcpTransport {

    // Session lifecycle

    /**
     * Open a new MCP session for the given user
     * @param sessionId The session ID (typically Visit ID)
     * @param userId The user ID associated with this session
     */
    void openSession(String sessionId, String userId)

    /**
     * Close an existing MCP session
     * @param sessionId The session ID to close
     */
    void closeSession(String sessionId)

    /**
     * Check if a session is currently active
     * @param sessionId The session ID to check
     * @return true if the session is active
     */
    boolean isSessionActive(String sessionId)

    // Message sending

    /**
     * Send a JSON-RPC message to a specific session
     * @param sessionId The target session ID
     * @param message The message to send (will be JSON-serialized)
     */
    void sendMessage(String sessionId, Map message)

    /**
     * Send an MCP notification to a specific session
     * @param sessionId The target session ID
     * @param notification The notification to send
     */
    void sendNotification(String sessionId, Map notification)

    /**
     * Send an MCP notification to all sessions for a specific user
     * @param userId The target user ID
     * @param notification The notification to send
     */
    void sendNotificationToUser(String userId, Map notification)

    // Broadcast

    /**
     * Broadcast a notification to all active sessions
     * @param notification The notification to broadcast
     */
    void broadcastNotification(Map notification)

    /**
     * Get the number of active sessions
     * @return count of active sessions
     */
    int getActiveSessionCount()

    /**
     * Get session IDs for a specific user
     * @param userId The user ID
     * @return Set of session IDs for this user
     */
    Set<String> getSessionsForUser(String userId)
}
