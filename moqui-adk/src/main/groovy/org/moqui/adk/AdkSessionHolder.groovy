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
