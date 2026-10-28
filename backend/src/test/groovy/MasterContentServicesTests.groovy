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

import org.moqui.Moqui
import org.moqui.context.ExecutionContext
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import spock.lang.Shared
import spock.lang.Specification

/* Tests for MasterContentServices100 get#PostingTime, the time a social post of a
   piece goes out, varied so posting does not look automated (LinkedIn is sensitive):
   - the time stays within -90 / +120 minutes of the planned time
   - the same piece and platform always get the same time
   - the platforms of one piece go out at most 30 minutes apart, not together
   - different pieces spread over the window

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class MasterContentServicesTests extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(MasterContentServicesTests.class)
    @Shared ExecutionContext ec
    @Shared Map tenant
    /** Monday 2026-11-02 10:00 UTC, the time a content plan gives a piece. */
    @Shared long planned = 1793613600000L
    @Shared List<String> pieceIds = (1..50).collect { "MC_SPOCK_${it}".toString() }

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        tenant = GrowerpTestSupport.tenant(ec, 'MasterContent')
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
        ec.message.clearAll()
        ec.user.internalLoginUser(tenant.username)
    }

    private long postingTime(String masterContentId, String platform) {
        Map result = ec.service.sync().name('growerp.100.MasterContentServices100.get#PostingTime')
                .parameters([baseTime: planned, masterContentId: masterContentId, platform: platform]).call()
        assert !ec.message.hasError()
        return result.scheduledDate as long
    }

    private static long minutes(long millis) { return millis.intdiv(60000L) }

    def "a post goes out within 90 minutes before to 2 hours after the planned time"() {
        expect:
        pieceIds.every { id ->
            ['LINKEDIN', 'TWITTER'].every { platform ->
                long offset = minutes(postingTime(id, platform) - planned)
                offset >= -90 && offset <= 120
            }
        }
    }

    def "the same piece and platform always get the same time"() {
        expect:
        postingTime('MC_SPOCK_1', 'LINKEDIN') == postingTime('MC_SPOCK_1', 'LINKEDIN')
    }

    def "the platforms of one piece go out at most 30 minutes apart, not together"() {
        when:
        List<Long> gaps = pieceIds.collect { id ->
            Math.abs(postingTime(id, 'LINKEDIN') - postingTime(id, 'TWITTER'))
        }

        then:
        gaps.every { minutes(it) <= 30 }
        gaps.count { it == 0L } < pieceIds.size().intdiv(4)
    }

    def "different pieces spread over the posting window"() {
        when:
        List<Long> times = pieceIds.collect { postingTime(it, 'LINKEDIN') }

        then:
        minutes(times.max() - times.min()) > 60
        times.unique(false).size() > pieceIds.size().intdiv(2)
    }
}
