package org.growerp.websocket;

import java.io.IOException;
import java.util.HashMap;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArraySet;

import javax.websocket.EncodeException;
import javax.websocket.OnClose;
import javax.websocket.OnError;
import javax.websocket.OnMessage;
import javax.websocket.OnOpen;
import javax.websocket.Session;
import javax.websocket.server.PathParam;
import javax.websocket.server.ServerEndpoint;

import org.growerp.model.Message;
import org.growerp.rest.RestClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@ServerEndpoint(value = "/{userId}/{apiKey}", decoders = MessageDecoder.class, encoders = MessageEncoder.class)
public class ChatEndpoint {
    private Session session;
    private static final Set<ChatEndpoint> chatEndpoints = new CopyOnWriteArraySet<>();
    private static HashMap<String, String> users = new HashMap<>();
    private static HashMap<String, String> usersApiKey = new HashMap<>();
    String databaseBackend = System.getenv("DATABASEBACKEND") != null ? 
            (System.getenv("DATABASEBACKEND") + "/rest/s1/growerp/100/") :
            "http://localhost:8080/rest/s1/growerp/100/" ;
    RestClient restClient = new RestClient(databaseBackend);
    Logger logger = LoggerFactory.getLogger(ChatEndpoint.class);
    String saveApiKey;

    @OnOpen
    public void onOpen(Session session,
        @PathParam("userId") String userId,
        @PathParam("apiKey") String apiKey) throws IOException, EncodeException {

        session.setMaxIdleTimeout(0);

        logger.info("New connection request received with userId:" + 
                userId + " sessionId: " + session.getId());
        // validate connection
        if (restClient.validate(apiKey)) {
            logger.info("New connection accepted from db: " + 
                    databaseBackend + " with userId:" + userId);

            this.session = session;
            chatEndpoints.add(this);
            users.put(session.getId(), userId);
            usersApiKey.put(session.getId(), apiKey);

            Message message = new Message();
            message.setFromUserId(userId);
            message.setContent("Connected!");
            message.setChatRoomid("%%system%%");
            broadcast(message);
        } else logger.info("Connection with userId:" + userId + 
            " rejected by " + databaseBackend);
    }

    @OnMessage
    public void onMessage(Session session, Message message)
            throws IOException, EncodeException {
        logger.info("receiving message from:" + message.getFromUserId() + 
                    " to: " + message.getToUserId() +
                    " content: " + message.getContent() +
                    " chatRoomId: " + message.getChatRoomId());
        message.setFromUserId(users.get(session.getId()));
        String apiKey = usersApiKey.get(session.getId());
        if (message.getToUserId() == null) broadcast(message);
        else {   
            logger.info("#endpoints: " + chatEndpoints.size());           
            chatEndpoints.forEach(endpoint -> {

                if (users.get(endpoint.session.getId()).equals(message.getToUserId())) {
    
                    synchronized (endpoint) {
                        try {
                            logger.info("Sending chatmessage: " + message.getContent() +
                                 " to: " + message.getToUserId() + " sessionId:" + 
                                endpoint.session.getId());
                            endpoint.session.getBasicRemote().sendObject(message);
                            if (!restClient.storeMessage(apiKey, message)) {
                                logger.info("Saving chat message failed...room: " + 
                                message.getChatRoomId());
                            }
                        } catch (IOException | EncodeException e) {
                            logger.info("chat message send failed....");
                        }
                    }
                }
            });
        }
    }

    @OnClose
    public void onClose(Session session) throws IOException, EncodeException {
        logger.info("closing websocket for user:" + session.getId());
        users.remove(session.getId());
        usersApiKey.remove(session.getId());
        chatEndpoints.remove(this);
        Message message = new Message();
        message.setFromUserId(users.get(session.getId()));
        message.setContent("Disconnected!");
        broadcast(message);
    }

    @OnError
    public void onError(Session session, Throwable throwable) {
        // Do error handling here
    }

    private static void broadcast(Message message) throws IOException, EncodeException {
        Logger logger = LoggerFactory.getLogger(ChatEndpoint.class);
        chatEndpoints.forEach(endpoint -> {
            synchronized (endpoint) {
                try {
                    endpoint.session.getBasicRemote()
                        .sendObject(message);
                } catch (IOException | EncodeException e) {
                    logger.info("chat broadcast message send failed....");
                }
            }
        });
    }

}
