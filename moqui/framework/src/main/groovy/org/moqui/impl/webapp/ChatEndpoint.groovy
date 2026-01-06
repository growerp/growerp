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
import org.moqui.entity.*
import org.moqui.util.*

import javax.websocket.CloseReason
import javax.websocket.EndpointConfig
import javax.websocket.Session
import javax.websocket.EncodeException;
import javax.websocket.EncodeException;


import java.io.IOException;
import java.util.HashMap;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArraySet;

@CompileStatic
class ChatEndpoint extends MoquiAbstractEndpoint {
    private final static Logger logger = LoggerFactory.getLogger(ChatEndpoint.class)

    private static final Set<ChatEndpoint> chatEndpoints = new CopyOnWriteArraySet<>();
    private static HashMap<String, String> users = new HashMap<>();

    Logger logger = LoggerFactory.getLogger(ChatEndpoint.class);

    @Override
    void onOpen(Session session, EndpointConfig config) {
        super.onOpen(session, config)
        users.put(session.getId(), getUserId());
        this.session = session;
        chatEndpoints.add(this)
    }

    @Override
    void onMessage(String messageJson) {
        Map message = (Map) new JsonSlurper().parseText(messageJson)
        logger.info("receiving message from: ${message.fromUserId}" + 
                    " content: ${message.content}" +
                    " to chatRoomId: ${message.chatRoom['chatRoomId']}");
        message.fromUserId = users.get(session.getId());

        // get member using direct service call instead of HTTP (avoids localhost issues in Docker)
        ExecutionContextImpl eci = super.ecfi.getEci()
        List userIds
        try {
            Map result = eci.service.sync().name("growerp.100.ChatServices100.get#ChatRoom")
                .parameter("chatRoomId", message.chatRoom['chatRoomId'])
                .parameter("apiKey", apiKey)
                .call()
            if (result == null || result.chatRooms == null || ((List)result.chatRooms).isEmpty()) {
                logger.warn("Websocket ChatRoom lookup error: ${result}")
                return
            }
            List chatRooms = (List) result.chatRooms
            logger.info("====chatrooms; $chatRooms =======")
            List members = (List) chatRooms[0]["members"]
            userIds = (List) members["user"]["userId"]
        } catch (Exception e) {
            logger.warn("Websocket ChatRoom lookup error: ${e.message}")
            return
        }

        chatEndpoints.forEach(endpoint -> {
            var toUserId = users.get(endpoint.session.getId())
            if (toUserId != getUserId() && userIds.find{it == toUserId} != null) {
                synchronized (endpoint) {
                    try {
                        logger.info("Sending chatmessage: ${message.content}" +
                                " to: ${toUserId} roomId: ${message.chatRoom['chatRoomId']} " +
                                "sessionId: ${endpoint.session.getId()}");
                        endpoint.session.asyncRemote.sendText(JsonOutput.toJson(message))
                    } catch (IOException | EncodeException e) {
                        logger.warn("chat message send failed....");
                    }
                }
            }
        });
    }

    @Override
    void onClose(Session session, CloseReason closeReason) throws IOException, EncodeException {
        logger.info("closing websocket for user: ${users.get(session.getId())} ${session.getId()} reason: ${closeReason}");
        Map message = [
            "fromUserId": users.get(session.getId()),
            "content": "Disconnected: ${closeReason}"];
        broadcast(JsonOutput.toJson(message));
        users.remove(session.getId());
        chatEndpoints.remove(this);
        super.onClose(session, closeReason)
    }

    private static void broadcast(String message) throws IOException, EncodeException {
        Logger logger = LoggerFactory.getLogger(ChatEndpoint.class);
        chatEndpoints.forEach(endpoint -> {
            synchronized (endpoint) {
                try {
                    logger.info("chat broadcast message send: $message...");
                    endpoint.session.getBasicRemote()
                        .sendObject(message);
                } catch (IOException | EncodeException e) {
                    logger.info("chat broadcast message send failed....");
                }
            }
        });
    }
}

