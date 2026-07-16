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

import com.sun.net.httpserver.HttpExchange
import com.sun.net.httpserver.HttpServer
import org.moqui.Moqui
import org.moqui.context.ExecutionContext
import org.moqui.entity.EntityValue
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import spock.lang.Shared
import spock.lang.Specification

import java.util.concurrent.atomic.AtomicInteger

/* Tests for the Substack automation services (SubstackServices100.xml and the
   auto-publish extension of publish#SocialPostToSubstack) against an embedded
   HTTP stub playing Substack:
   - article publish: draft -> publish -> PUBLISHED with externalPostId + canonical url
   - SUBSTACK_NOTE posts ride the scheduled publish job
   - add#SubstackSubscriber is idempotent and filters test (example.com) emails
   - collect#SubstackEngagements dedupes on externalEngagementId across runs

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class SubstackServicesTests extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(SubstackServicesTests.class)
    @Shared ExecutionContext ec

    @Shared String ownerPartyId = 'SUBSTACK_OWNER'
    @Shared String configId = 'SUBSTACK_TEST_CFG'
    @Shared HttpServer stubServer
    @Shared String stubUrl
    @Shared AtomicInteger freeEndpointCalls = new AtomicInteger(0)

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        ec.user.loginUser('SystemSupport', 'moqui')
        ec.artifactExecution.disableAuthz()

        stubServer = HttpServer.create(new InetSocketAddress('127.0.0.1', 0), 0)
        stubServer.createContext('/', { HttpExchange ex ->
            String path = ex.requestURI.path
            String response
            int status = 200
            if (path == '/api/v1/drafts') {
                response = '{"id": 4242}'
            } else if (path ==~ '/api/v1/drafts/\\d+/publish') {
                response = "{\"id\": 4242, \"slug\": \"test-post\", \"canonical_url\": \"${stubUrl}/p/test-post\"}"
            } else if (path == '/api/v1/free') {
                freeEndpointCalls.incrementAndGet()
                response = '{"status": "ok"}'
            } else if (path ==~ '/api/v1/post/.+/comments') {
                response = '{"comments": [{"id": "c1", "name": "Alice", "handle": "alice", ' +
                        '"body": "Great post!", "date": "2026-07-15T10:00:00Z", "type": "comment", ' +
                        '"children": [{"id": "c2", "name": "Bob", "body": "+1", "type": "restack", "children": []}]}]}'
            } else if (path == '/api/v1/comment/feed') {
                response = '{"id": 555}'
            } else {
                response = '{"error": "not found"}'
                status = 404
            }
            byte[] bytes = response.getBytes('UTF-8')
            ex.responseHeaders.set('Content-Type', 'application/json')
            ex.sendResponseHeaders(status, bytes.length)
            ex.responseBody.withStream { it.write(bytes) }
        })
        stubServer.start()
        stubUrl = "http://127.0.0.1:${stubServer.address.port}"
        System.setProperty('growerp.substack.notesBaseUrl', stubUrl)

        // owner party + Substack config pointing at the stub (idempotent: the test
        // database persists between runs, but the stub port changes -> store#)
        if (ec.entity.find('mantle.party.Party').condition('partyId', ownerPartyId).one() == null) {
            ec.service.sync().name('create#mantle.party.Party').disableAuthz()
                    .parameters([partyId: ownerPartyId, partyTypeEnumId: 'PtyOrganization']).call()
        }
        ec.service.sync().name('store#growerp.marketing.PlatformConfiguration').disableAuthz()
                .parameters([configId: configId, ownerPartyId: ownerPartyId, platform: 'SUBSTACK',
                        isEnabled: 'Y', apiKey: 'test-sid', username: stubUrl]).call()
    }

    def cleanupSpec() {
        System.clearProperty('growerp.substack.notesBaseUrl')
        if (stubServer) stubServer.stop(0)
        if (ec) ec.destroy()
    }

    private EntityValue platformConfig() {
        ec.entity.find('growerp.marketing.PlatformConfiguration').condition('configId', configId).one()
    }

    private String createPost(Map fields) {
        Map out = ec.service.sync().name('create#growerp.marketing.SocialPost').disableAuthz()
                .parameters([ownerPartyId: ownerPartyId, status: 'READY', type: 'OTHER',
                        createdDate: ec.user.nowTimestamp, lastModifiedDate: ec.user.nowTimestamp] + fields).call()
        return out.postId
    }

    def "article publish runs draft then publish and returns externalPostId and canonical url"() {
        setup: // DRAFT status so the scheduled-job test below does not pick it up
        String postId = createPost([platform: 'SUBSTACK', status: 'DRAFT',
                headline: 'Test article', finalContent: 'First paragraph.\n\nSecond paragraph.'])
        EntityValue post = ec.entity.find('growerp.marketing.SocialPost').condition('postId', postId).one()

        when:
        Map out = ec.service.sync()
                .name('growerp.100.SocialPostPublishingServices100.publish#SocialPostToSubstack')
                .parameters([post: post, platformConfig: platformConfig()]).disableAuthz().call()

        then:
        out.success
        out.externalPostId == '4242'
        out.publishedUrl == "${stubUrl}/p/test-post"
    }

    def "SUBSTACK_NOTE posts are published by the scheduled job"() {
        setup:
        String postId = createPost([platform: 'SUBSTACK_NOTE', finalContent: 'A short note.'])

        when:
        ec.service.sync().name('growerp.100.SocialPostPublishingServices100.publish#ScheduledSocialPosts')
                .disableAuthz().call()
        EntityValue post = ec.entity.find('growerp.marketing.SocialPost')
                .condition('postId', postId).one()

        then:
        post.status == 'PUBLISHED'
        post.externalPostId == '555'
        post.publishedUrl == "${stubUrl}/note/c-555"
    }

    def "add#SubstackSubscriber is idempotent and retries are skipped once synced"() {
        setup:
        String email = "trial${System.currentTimeMillis()}@growerp-test.com"

        when:
        Map first = ec.service.sync().name('growerp.100.SubstackServices100.add#SubstackSubscriber')
                .parameters([emailAddress: email, ownerPartyId: ownerPartyId]).disableAuthz().call()
        Map second = ec.service.sync().name('growerp.100.SubstackServices100.add#SubstackSubscriber')
                .parameters([emailAddress: email, ownerPartyId: ownerPartyId]).disableAuthz().call()

        then:
        first.resultStatus == 'SYNCED'
        second.resultStatus == 'SKIPPED'
        ec.entity.find('growerp.marketing.SubstackSubscriberSync')
                .condition([ownerPartyId: ownerPartyId, emailAddress: email] as Map).list().size() == 1
    }

    def "test emails (example.com) are skipped without calling Substack"() {
        setup:
        String email = "tester${System.currentTimeMillis()}@example.com"
        int callsBefore = freeEndpointCalls.get()

        when:
        Map out = ec.service.sync().name('growerp.100.SubstackServices100.add#SubstackSubscriber')
                .parameters([emailAddress: email, ownerPartyId: ownerPartyId]).disableAuthz().call()

        then:
        out.resultStatus == 'SKIPPED'
        freeEndpointCalls.get() == callsBefore
        ec.entity.find('growerp.marketing.SubstackSubscriberSync')
                .condition([ownerPartyId: ownerPartyId, emailAddress: email] as Map).list().size() == 0
    }

    def "collect#SubstackEngagements stores comments and restacks once, deduped on rerun"() {
        setup: // a published article with an externalPostId unique to this run
        String externalPostId = "9${System.currentTimeMillis()}"
        String postId = createPost([platform: 'SUBSTACK', status: 'PUBLISHED',
                headline: 'Engagement test', finalContent: 'Body.',
                externalPostId: externalPostId, publishedDate: ec.user.nowTimestamp,
                publishedUrl: "${stubUrl}/p/engagement-test"])

        when: 'collecting twice'
        ec.service.sync().name('growerp.100.SubstackServices100.collect#SubstackEngagements')
                .disableAuthz().call()
        ec.service.sync().name('growerp.100.SubstackServices100.collect#SubstackEngagements')
                .disableAuthz().call()
        List<EntityValue> engagements = ec.entity.find('growerp.marketing.SocialEngagement')
                .condition('postId', postId).orderBy('externalEngagementId').list()

        then: 'one row per comment, restack mapped to SHARE, no duplicates'
        engagements.size() == 2
        engagements[0].externalEngagementId == 'c1'
        engagements[0].engagementType == 'COMMENT'
        engagements[0].userName == 'Alice'
        engagements[0].note == 'Great post!'
        engagements[1].externalEngagementId == 'c2'
        engagements[1].engagementType == 'SHARE'
    }
}
