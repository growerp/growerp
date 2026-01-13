/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
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

import javax.websocket.CloseReason
import javax.websocket.EndpointConfig
import javax.websocket.Session
import javax.websocket.EncodeException

import java.io.IOException
import java.util.HashMap
import java.util.Set
import java.util.concurrent.CopyOnWriteArraySet

@CompileStatic
class ChatEndpoint extends MoquiAbstractEndpoint {
    private final static Logger logger = LoggerFactory.getLogger(ChatEndpoint.class)

    private static final Set<ChatEndpoint> chatEndpoints = new CopyOnWriteArraySet<>()

    @Override
    void onOpen(Session session, EndpointConfig config) {
        super.onOpen(session, config)
        this.session = session
        chatEndpoints.add(this)
        logger.info("Opened chat websocket for user ${userId} session ${session.id}")
    }

    @Override
    void onMessage(String messageJson) {
        ExecutionContextImpl eci = super.ecfi.getEci()
        try {
            if (userId) ((UserFacadeImpl) eci.user).internalLoginUser(userId)
            
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
            Map result = eci.service.sync().name("growerp.100.ChatServices100.get#ChatRoom")
                .parameter("chatRoomId", chatRoomId)
                .parameter("apiKey", apiKey)
                .call()
                
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
}


