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
package org.moqui.adk

import java.util.concurrent.ConcurrentHashMap

/** In-memory conversation history store. Keyed by sessionId. Resets on Moqui restart. */
class AdkSessionHolder {
    static final ConcurrentHashMap<String, List<Map>> sessions = new ConcurrentHashMap<>()
    static final ConcurrentHashMap<String, List<Map>> events = new ConcurrentHashMap<>()

    static void logEvent(String sessionId, String type, String summary, Map details) {
        if (!sessionId) return
        def list = events.computeIfAbsent(sessionId, { new java.util.concurrent.CopyOnWriteArrayList<Map>() })
        list.add([
            timestamp: new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS").format(new Date()),
            type: type,
            summary: summary,
            details: details ?: [:]
        ])
    }
}
