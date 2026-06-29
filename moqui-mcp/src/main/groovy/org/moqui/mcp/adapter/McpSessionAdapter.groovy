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

import org.moqui.entity.EntityValue
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import java.util.concurrent.ConcurrentHashMap

/**
 * Adapter that maps Moqui Visit sessions to MCP sessions.
 * Provides in-memory session tracking to avoid database lock contention.
 */
class McpSessionAdapter {
    protected final static Logger logger = LoggerFactory.getLogger(McpSessionAdapter.class)

    // Visit ID → MCP Session state
    private final Map<String, McpSession> sessions = new ConcurrentHashMap<>()

    // User ID → Set of Visit IDs (for user-targeted notifications)
    private final Map<String, Set<String>> userSessions = new ConcurrentHashMap<>()

    // Session-specific locks to avoid sessionId.intern() deadlocks
    private final Map<String, Object> sessionLocks = new ConcurrentHashMap<>()

    /**
     * Create a new MCP session from a Moqui Visit
     * @param visit The Moqui Visit entity
     * @return The created McpSession
     */
    McpSession createSession(EntityValue visit) {
        String visitId = visit.visitId?.toString()
        String userId = visit.userId?.toString()

        if (!visitId) {
            throw new IllegalArgumentException("Visit must have a visitId")
        }

        def session = new McpSession(
            visitId: visitId,
            userId: userId,
            state: McpSession.STATE_INITIALIZED
        )
        sessions.put(visitId, session)

        // Track user → sessions mapping
        if (userId) {
            def userSet = userSessions.computeIfAbsent(userId) { new ConcurrentHashMap<>().newKeySet() }
            userSet.add(visitId)
        }

        logger.debug("Created MCP session ${visitId} for user ${userId}")
        return session
    }

    /**
     * Create a new MCP session with explicit parameters
     * @param visitId The Visit/session ID
     * @param userId The user ID
     * @return The created McpSession
     */
    McpSession createSession(String visitId, String userId) {
        if (!visitId) {
            throw new IllegalArgumentException("visitId is required")
        }

        def session = new McpSession(
            visitId: visitId,
            userId: userId,
            state: McpSession.STATE_INITIALIZED
        )
        sessions.put(visitId, session)

        // Track user → sessions mapping
        if (userId) {
            def userSet = userSessions.computeIfAbsent(userId) { new ConcurrentHashMap<>().newKeySet() }
            userSet.add(visitId)
        }

        logger.debug("Created MCP session ${visitId} for user ${userId}")
        return session
    }

    /**
     * Close and remove a session
     * @param visitId The session/visit ID to close
     */
    void closeSession(String visitId) {
        def session = sessions.remove(visitId)
        if (session) {
            // Remove from user tracking
            if (session.userId) {
                def userSet = userSessions.get(session.userId)
                if (userSet) {
                    userSet.remove(visitId)
                    if (userSet.isEmpty()) {
                        userSessions.remove(session.userId)
                    }
                }
            }
            // Clean up session lock
            sessionLocks.remove(visitId)
            logger.debug("Closed MCP session ${visitId}")
        }
    }

    /**
     * Get a session by visit ID
     * @param visitId The session/visit ID
     * @return The McpSession or null if not found
     */
    McpSession getSession(String visitId) {
        return sessions.get(visitId)
    }

    /**
     * Check if a session exists and is active
     * @param visitId The session/visit ID
     * @return true if the session exists
     */
    boolean hasSession(String visitId) {
        return sessions.containsKey(visitId)
    }

    /**
     * Get all session IDs for a specific user
     * @param userId The user ID
     * @return Set of session/visit IDs (empty set if none)
     */
    Set<String> getSessionsForUser(String userId) {
        return userSessions.get(userId) ?: Collections.emptySet()
    }

    /**
     * Get all active session IDs
     * @return Set of all session IDs
     */
    Set<String> getAllSessionIds() {
        return sessions.keySet()
    }

    /**
     * Get the count of active sessions
     * @return Number of active sessions
     */
    int getSessionCount() {
        return sessions.size()
    }

    /**
     * Get a session-specific lock for synchronized operations
     * @param visitId The session/visit ID
     * @return The lock object
     */
    Object getSessionLock(String visitId) {
        return sessionLocks.computeIfAbsent(visitId) { new Object() }
    }

    /**
     * Update session state
     * @param visitId The session/visit ID
     * @param state The new state
     */
    void setSessionState(String visitId, int state) {
        def session = sessions.get(visitId)
        if (session) {
            session.state = state
            logger.debug("Session ${visitId} state changed to ${state}")
        }
    }

    /**
     * Update session activity timestamp
     * @param visitId The session/visit ID
     */
    void touchSession(String visitId) {
        def session = sessions.get(visitId)
        if (session) {
            session.touch()
        }
    }

    /**
     * Get session statistics for monitoring
     * @return Map of session statistics
     */
    Map getStatistics() {
        return [
            totalSessions: sessions.size(),
            usersWithSessions: userSessions.size(),
            sessionsPerUser: userSessions.collectEntries { userId, sessionSet ->
                [(userId): sessionSet.size()]
            }
        ]
    }
}

/**
 * Represents an MCP session state
 */
class McpSession {
    static final int STATE_UNINITIALIZED = 0
    static final int STATE_INITIALIZING = 1
    static final int STATE_INITIALIZED = 2

    String visitId
    String userId
    int state = STATE_UNINITIALIZED
    long lastActivity = System.currentTimeMillis()
    long createdAt = System.currentTimeMillis()

    // SSE writer reference (for active connections)
    PrintWriter sseWriter

    // Notification queue for this session
    List<Map> notificationQueue = Collections.synchronizedList(new ArrayList<>())

    // Subscriptions (method names this session is subscribed to)
    Set<String> subscriptions = Collections.newSetFromMap(new ConcurrentHashMap<>())

    void touch() {
        lastActivity = System.currentTimeMillis()
    }

    boolean isActive() {
        return state == STATE_INITIALIZED && sseWriter != null && !sseWriter.checkError()
    }

    boolean hasActiveWriter() {
        return sseWriter != null && !sseWriter.checkError()
    }

    long getDurationMs() {
        return System.currentTimeMillis() - createdAt
    }

    Map toMap() {
        return [
            visitId: visitId,
            userId: userId,
            state: state,
            lastActivity: lastActivity,
            createdAt: createdAt,
            durationMs: getDurationMs(),
            active: isActive(),
            hasWriter: sseWriter != null,
            queuedNotifications: notificationQueue.size(),
            subscriptions: subscriptions.toList()
        ]
    }
}
