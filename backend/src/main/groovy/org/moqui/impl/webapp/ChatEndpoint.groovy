/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.moqui.impl.webapp

import groovy.transform.CompileStatic
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import groovy.json.*
import org.moqui.impl.context.ExecutionContextImpl
import org.moqui.impl.context.UserFacadeImpl
import org.moqui.entity.*
import org.moqui.util.*

import jakarta.websocket.CloseReason
import jakarta.websocket.EndpointConfig
import jakarta.websocket.Session
import jakarta.websocket.EncodeException

import java.io.IOException
import java.util.concurrent.CopyOnWriteArraySet

@CompileStatic
class ChatEndpoint extends MoquiAbstractEndpoint {
    private final static Logger logger = LoggerFactory.getLogger(ChatEndpoint.class)

    private static final Set<ChatEndpoint> chatEndpoints = new CopyOnWriteArraySet<>()
    private String apiKey = null

    @Override
    void onOpen(Session session, EndpointConfig config) {
        super.onOpen(session, config)
        this.session = session
        // Get apiKey from request parameters if provided
        List<String> apiKeys = session.getRequestParameterMap().get("api_key")
        if (apiKeys) apiKey = apiKeys.get(0)
        chatEndpoints.add(this)
        logger.info("Opened chat websocket for user ${userId} session ${session.id}")
    }

    @Override
    void onMessage(String messageJson) {
        ExecutionContextImpl eci = super.ecfi.getEci()
        try {
            // internalLoginUser takes the username, not the userId: passing the userId
            // added a 'No account found' error to the message facade, which made every
            // following service call refuse to run, so no message was ever fanned out
            if (username) ((UserFacadeImpl) eci.user).internalLoginUser(username)

            Object parsed = new JsonSlurper().parseText(messageJson)
            if (!(parsed instanceof Map)) {
                logger.warn("Received non-map message: ${messageJson}")
                return
            }
            Map message = (Map) parsed

            String chatRoomId = (String) ((Map) message.get("chatRoom"))?.get("chatRoomId")
            logger.info("Receiving message from: ${userId} for chatRoomId: ${chatRoomId}")

            message.put("fromUserId", userId)

            if (!chatRoomId) {
                logger.warn("No chatRoomId in message: ${message}")
                return
            }

            // get member using direct service call instead of HTTP (avoids localhost issues in Docker)
            // authz is disabled because this call has no parent REST artifact to inherit
            // authorization from; the service itself still scopes the rooms to the logged in user
            boolean alreadyDisabled = eci.artifactExecution.disableAuthz()
            Map result
            try {
                result = eci.service.sync().name("growerp.100.ChatServices100.get#ChatRoom")
                    .parameter("chatRoomId", chatRoomId)
                    .parameter("apiKey", apiKey)
                    .call()
            } finally {
                if (!alreadyDisabled) eci.artifactExecution.enableAuthz()
            }

            if (result == null || result.get("chatRooms") == null || ((List)result.get("chatRooms")).isEmpty()) {
                logger.warn("Websocket ChatRoom lookup error for room ${chatRoomId}: ${result}")
                return
            }

            List chatRooms = (List) result.get("chatRooms")
            Map chatRoom = (Map) chatRooms.get(0)
            List members = (List) chatRoom.get("members")
            if (!members) {
                logger.warn("No members found for chatRoom ${chatRoomId}")
                return
            }

            // Extract userIds of members to broadcast to
            List<String> memberUserIds = new ArrayList<>()
            for (Object memberObj : members) {
                Map member = (Map) memberObj
                Map user = (Map) member.get("user")
                if (user != null && user.get("userId") != null) {
                    memberUserIds.add((String) user.get("userId"))
                }
            }

            String messageOutput = JsonOutput.toJson(message)
            chatEndpoints.forEach(endpoint -> {
                String toUserId = endpoint.getUserId()
                if (toUserId != null && toUserId != userId && memberUserIds.contains(toUserId)) {
                    synchronized (endpoint) {
                        try {
                            if (endpoint.session != null && endpoint.session.isOpen()) {
                                logger.info("Sending chat message to: ${toUserId} roomId: ${chatRoomId} sessionId: ${endpoint.session.id}")
                                endpoint.session.asyncRemote.sendText(messageOutput)
                            }
                        } catch (Exception e) {
                            logger.warn("Chat message send failed to ${toUserId}: ${e.message}")
                        }
                    }
                }
            })
        } catch (Exception e) {
            logger.error("Error in ChatEndpoint.onMessage", e)
        } finally {
            eci.destroy()
        }
    }

    @Override
    void onClose(Session session, CloseReason closeReason) {
        logger.info("Closing websocket for user: ${userId} ${session.id} reason: ${closeReason}")
        chatEndpoints.remove(this)
        super.onClose(session, closeReason)
    }

    private static void broadcast(String message) {
        chatEndpoints.forEach(endpoint -> {
            synchronized (endpoint) {
                try {
                    if (endpoint.session != null && endpoint.session.isOpen()) {
                        logger.info("Chat broadcast message send to ${endpoint.getUserId()}...")
                        endpoint.session.asyncRemote.sendText(message)
                    }
                } catch (Exception e) {
                    logger.warn("Chat broadcast message send failed: ${e.message}")
                }
            }
        })
    }

    /** True if the given userId has at least one open WebSocket session. */
    static boolean isUserOnline(String userId) {
        if (userId == null) return false
        for (ChatEndpoint endpoint : chatEndpoints) {
            if (userId == endpoint.getUserId()
                    && endpoint.session != null && endpoint.session.isOpen()) {
                return true
            }
        }
        return false
    }

    /** Push a server-originated message to all connected WebSocket sessions whose userId is in memberUserIds. */
    static void pushToMembers(String messageJson, List<String> memberUserIds) {
        chatEndpoints.forEach(endpoint -> {
            String toUserId = endpoint.getUserId()
            if (toUserId != null && memberUserIds.contains(toUserId)) {
                synchronized (endpoint) {
                    try {
                        if (endpoint.session != null && endpoint.session.isOpen()) {
                            endpoint.session.asyncRemote.sendText(messageJson)
                            logger.info("Chat push sent to ${toUserId}")
                        }
                    } catch (Exception e) {
                        logger.warn("Chat push to ${toUserId} failed: ${e.message}")
                    }
                }
            }
        })
    }
}
