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
package org.moqui.adk

import com.google.adk.events.Event
import com.google.adk.sessions.BaseSessionService
import com.google.adk.sessions.GetSessionConfig
import com.google.adk.sessions.ListEventsResponse
import com.google.adk.sessions.ListSessionsResponse
import com.google.adk.sessions.Session
import com.google.adk.sessions.State
import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import io.reactivex.rxjava3.core.Completable
import io.reactivex.rxjava3.core.Maybe
import io.reactivex.rxjava3.core.Single
import org.moqui.context.ExecutionContextFactory
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import java.sql.Timestamp
import java.time.Instant
import java.util.concurrent.ConcurrentMap

/**
 * ADK BaseSessionService backed by Moqui entities (AdkSession + AdkSessionEvent).
 * Conversation history and session state survive Moqui restarts.
 */
class MoquiSessionService implements BaseSessionService {

    protected final static Logger logger = LoggerFactory.getLogger(MoquiSessionService.class)

    final ExecutionContextFactory ecf
    private final JsonSlurper slurper = new JsonSlurper()

    MoquiSessionService(ExecutionContextFactory ecf) {
        this.ecf = ecf
    }

    @Override
    Single<Session> createSession(String appName, String userId,
                                  ConcurrentMap<String, Object> state, String sessionId) {
        Single.fromCallable {
            String id = sessionId ?: UUID.randomUUID().toString()
            String stateJson = JsonOutput.toJson(state ?: [:])

            withAuthz { ec ->
                def sv = ec.entity.makeValue('moqui.adk.AdkSession')
                sv.adkSessionId = id
                sv.appName = appName
                sv.userId = userId
                sv.stateJson = stateJson
                sv.lastUpdateTime = new Timestamp(System.currentTimeMillis())
                sv.create()
            }

            Session.builder(id)
                .appName(appName)
                .userId(userId)
                .state(new State(state ?: [:] as ConcurrentMap))
                .events([])
                .lastUpdateTime(Instant.now())
                .build()
        }
    }

    @Override
    Maybe<Session> getSession(String appName, String userId, String sessionId,
                              Optional<GetSessionConfig> config) {
        Maybe.fromCallable {
            def sv
            List<Event> events = []

            withAuthz { ec ->
                sv = ec.entity.find('moqui.adk.AdkSession')
                    .condition('adkSessionId', sessionId)
                    .condition('appName', appName)
                    .condition('userId', userId)
                    .one()
                if (!sv) return

                def evVals = ec.entity.find('moqui.adk.AdkSessionEvent')
                    .condition('adkSessionId', sessionId)
                    .orderBy('eventTime').list()
                events = evVals.collect { Event.fromJson(it.eventJson as String) }
            }

            if (!sv) return null

            Map<String, Object> stateMap = slurper.parseText(sv.stateJson ?: '{}') as Map
            Session.builder(sessionId)
                .appName(appName)
                .userId(userId)
                .state(new State(stateMap))
                .events(events)
                .lastUpdateTime(sv.lastUpdateTime?.toInstant() ?: Instant.now())
                .build()
        }
    }

    @Override
    Single<ListSessionsResponse> listSessions(String appName, String userId) {
        Single.fromCallable {
            List<Session> sessions = []
            withAuthz { ec ->
                def svList = ec.entity.find('moqui.adk.AdkSession')
                    .condition('appName', appName)
                    .condition('userId', userId)
                    .list()
                sessions = svList.collect { sv ->
                    Session.builder(sv.adkSessionId as String)
                        .appName(appName).userId(userId)
                        .state(new State([:])).events([]).build()
                }
            }
            ListSessionsResponse.builder().sessions(sessions).build()
        }
    }

    @Override
    Completable deleteSession(String appName, String userId, String sessionId) {
        Completable.fromAction {
            withAuthz { ec ->
                ec.entity.find('moqui.adk.AdkSessionEvent')
                    .condition('adkSessionId', sessionId).deleteAll()
                ec.entity.find('moqui.adk.AdkSession')
                    .condition('adkSessionId', sessionId)
                    .condition('appName', appName)
                    .condition('userId', userId)
                    .deleteAll()
            }
        }
    }

    @Override
    Single<ListEventsResponse> listEvents(String appName, String userId, String sessionId) {
        Single.fromCallable {
            List<Event> events = []
            withAuthz { ec ->
                def evVals = ec.entity.find('moqui.adk.AdkSessionEvent')
                    .condition('adkSessionId', sessionId)
                    .orderBy('eventTime').list()
                events = evVals.collect { Event.fromJson(it.eventJson as String) }
            }
            ListEventsResponse.builder().events(events).build()
        }
    }

    @Override
    Single<Event> appendEvent(Session session, Event event) {
        Single.fromCallable {
            // Mirror BaseSessionService's default contract: partial (streaming) events are
            // transient deltas — they must NOT be added to history or persisted.
            if (event.partial().orElse(false)) return event

            Map<String, Object> stateDelta = event.actions()?.stateDelta() ?: [:]

            // 1) Update the in-memory Session so the running invocation sees this event on the
            //    next LLM turn. Without this, function-call/response history never accumulates
            //    in-memory and the model re-issues the same tool call in a loop.
            def liveState = session.state()
            if (stateDelta && liveState != null) {
                stateDelta.each { k, v ->
                    if (v == State.REMOVED) liveState.remove(k)
                    else liveState.put(k, v)
                }
            }
            session.events()?.add(event)

            // 2) Persist to Moqui entities so history + state survive a restart.
            withAuthz { ec ->
                def ev = ec.entity.makeValue('moqui.adk.AdkSessionEvent')
                ev.adkSessionEventId = UUID.randomUUID().toString()
                ev.adkSessionId = session.id()
                ev.eventJson = event.toJson()
                ev.eventTime = new Timestamp(System.currentTimeMillis())
                ev.create()

                if (stateDelta) {
                    def sv = ec.entity.find('moqui.adk.AdkSession')
                        .condition('adkSessionId', session.id()).one()
                    if (sv) {
                        Map<String, Object> cur = slurper.parseText(sv.stateJson ?: '{}') as Map
                        stateDelta.each { k, v ->
                            if (v == State.REMOVED) cur.remove(k)
                            else cur[k] = v
                        }
                        sv.stateJson = JsonOutput.toJson(cur)
                        sv.lastUpdateTime = new Timestamp(System.currentTimeMillis())
                        sv.update()
                    }
                }
            }
            event
        }
    }

    // ── Helper ────────────────────────────────────────────────────────────────

    private <T> T withAuthz(Closure<T> work) {
        def ec = ecf.getExecutionContext()
        boolean wasDisabled = ec.artifactExecution.disableAuthz()
        try {
            return work(ec)
        } finally {
            if (!wasDisabled) ec.artifactExecution.enableAuthz()
        }
    }
}
