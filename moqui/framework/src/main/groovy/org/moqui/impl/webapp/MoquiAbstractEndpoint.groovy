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
import org.moqui.impl.context.ExecutionContextFactoryImpl
import org.moqui.impl.context.ExecutionContextImpl
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.moqui.util.*

import javax.servlet.http.HttpSession
import javax.websocket.*
import javax.websocket.server.HandshakeRequest

/**
 * An abstract class for WebSocket Endpoint that does basic setup, including creating an ExecutionContext with the user
 * logged if they were logged in for the corresponding HttpSession (based on the WebSocket HandshakeRequest, ie the
 * HTTP upgrade request, tied to an existing HttpSession).
 *
 * The main method to implement is the onMessage(String) method.
 *
 * If you override the onOpen() method call the super method first.
 * If you override the onClose() method call the super method last (will clear out all internal fields).
 */
@CompileStatic
abstract class MoquiAbstractEndpoint extends Endpoint implements MessageHandler.Whole<String> {
    private final static Logger logger = LoggerFactory.getLogger(MoquiAbstractEndpoint.class)

    protected ExecutionContextFactoryImpl ecfi = (ExecutionContextFactoryImpl) null
    protected Session session = (Session) null
    protected HttpSession httpSession = (HttpSession) null
    protected HandshakeRequest handshakeRequest = (HandshakeRequest) null
    protected String userId = (String) null
    protected String apiKey = (String) null
    protected String username = (String) null
    protected boolean destroyInitialEci = true

    MoquiAbstractEndpoint() { super() }

    ExecutionContextFactoryImpl getEcf() { return ecfi }
    HttpSession getHttpSession() { return httpSession }
    Session getSession() { return session }
    String getUserId() { return userId }
    String getUsername() { return username }

    @Override
    void onOpen(Session session, EndpointConfig config) {
        this.session = session
        ecfi = (ExecutionContextFactoryImpl) config.userProperties.get("executionContextFactory")
        handshakeRequest = (HandshakeRequest) config.userProperties.get("handshakeRequest")
        httpSession = handshakeRequest != null ? (HttpSession) handshakeRequest.getHttpSession() : (HttpSession) config.userProperties.get("httpSession")
        ExecutionContextImpl eci = ecfi.getEci()

        try {
            if (handshakeRequest != null) {
                eci.userFacade.initFromHandshakeRequest(handshakeRequest)
            } else if (httpSession != null) {
                eci.userFacade.initFromHttpSession(httpSession)
            } else {
                logger.warn("No HandshakeRequest or HttpSession found opening WebSocket Session ${session.id}, not logging in user")
            }

            if (session.getRequestParameterMap()["userId"] != null) {
                userId = session.getRequestParameterMap()["userId"][0]
                apiKey = session.getRequestParameterMap()["apiKey"][0]
                RestClient restClient = eci.service.rest().method(RestClient.GET)
                    .uri("http://localhost:8080/rest/s1/growerp/100/Authenticate?classificationId=token")
                    .addHeader("Content-Type", "application/json")
                    .addHeader("api_key", "${apiKey}")
                RestClient.RestResponse restResponse = restClient.call()
                Map result = (Map) restResponse.jsonObject()
                if (restResponse.statusCode < 200 || restResponse.statusCode >= 300 ) {
                    eci.logger.warn("Websocket Authorisation error: ${result}")
                    return
                }
            } else {
                userId = eci.user.userId
                username = eci.user.username
            }

            Long timeout = (Long) config.userProperties.get("maxIdleTimeout")
            if (timeout != null && session.getMaxIdleTimeout() > 0 && session.getMaxIdleTimeout() < timeout)
                session.setMaxIdleTimeout(timeout)

            session.addMessageHandler(this)

            if (logger.isTraceEnabled()) logger.trace("Opened WebSocket Session ${session.getId()}, userId: ${userId} (${username}), timeout: ${session.getMaxIdleTimeout()}ms")
        } finally {
            if (eci != null && destroyInitialEci) {
                eci.destroy()
            }
        }
        
        logger.info("Opened WebSocket Session ${session.getId()}, parameters: ${session.getRequestParameterMap()}, username: ${session.getUserPrincipal()?.getName()}, config props: ${config.userProperties}, request props: ${session.getRequestParameterMap()}")
    //    for (String attrName in httpSession.getAttributeNames())
    //        logger.info("WebSocket Session ${session.getId()}, session attribute: ${attrName}=${httpSession.getAttribute(attrName)}")
        
    }

    @Override
    abstract void onMessage(String message)

    @Override
    void onClose(Session session, CloseReason closeReason) {
        this.session = null
        this.httpSession = null
        this.handshakeRequest = null
        this.ecfi = null
        if (logger.isTraceEnabled()) logger.trace("Closed WebSocket Session ${session.getId()}: ${closeReason.reasonPhrase}")
    }

    @Override
    void onError(Session session, Throwable thr) {
        if (thr instanceof SocketTimeoutException || (thr.getMessage() != null && thr.getMessage().toLowerCase().contains("timeout"))) {
            logger.info("Timeout in WebSocket Session ${session.getId()}, User ${userId} (${username}): ${thr.getMessage()}")
        } else {
            logger.warn("Error in WebSocket Session ${session.getId()}, User ${userId} (${username})", thr)
        }
    }
}
