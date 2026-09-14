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

import com.sun.net.httpserver.HttpExchange
import com.sun.net.httpserver.HttpServer
import groovy.json.JsonSlurper
import org.moqui.Moqui
import org.moqui.context.ExecutionContext
import org.moqui.entity.EntityValue
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import spock.lang.Shared
import spock.lang.Specification

import java.util.concurrent.CopyOnWriteArrayList

/* Tests publish#SocialPostToX against an embedded HTTP stub playing the X API:
   - a one-block post becomes a single tweet
   - a multi-block post becomes a thread chained on reply.in_reply_to_tweet_id,
     with the FIRST tweet's id and url reported back
   - a block over 280 characters fails the whole post without calling the API
   - an API error names the tweet that failed

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class XPublishingTests extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(XPublishingTests.class)
    @Shared ExecutionContext ec

    @Shared String ownerPartyId = 'X_OWNER'
    @Shared String configId = 'X_TEST_CFG'
    @Shared HttpServer stubServer
    @Shared String stubUrl
    /** Every request body the stub received, in order. */
    @Shared List<Map> received = new CopyOnWriteArrayList<>()
    /** Set to make the stub reject the tweet at this 1-based position. */
    @Shared Integer failAtTweet = null

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        ec.user.loginUser('SystemSupport', 'moqui')
        ec.artifactExecution.disableAuthz()

        stubServer = HttpServer.create(new InetSocketAddress('127.0.0.1', 0), 0)
        stubServer.createContext('/', { HttpExchange ex ->
            String response
            int status
            if (ex.requestURI.path == '/2/tweets') {
                Map body = (Map) new JsonSlurper().parse(ex.requestBody)
                received.add(body)
                if (failAtTweet != null && received.size() == failAtTweet) {
                    status = 403
                    response = '{"title": "Forbidden"}'
                } else {
                    status = 201
                    response = "{\"data\": {\"id\": \"100${received.size()}\"}}"
                }
            } else {
                status = 404
                response = '{"error": "not found"}'
            }
            byte[] bytes = response.getBytes('UTF-8')
            ex.responseHeaders.set('Content-Type', 'application/json')
            ex.sendResponseHeaders(status, bytes.length)
            ex.responseBody.withStream { it.write(bytes) }
        })
        stubServer.start()
        stubUrl = "http://127.0.0.1:${stubServer.address.port}"
        System.setProperty('growerp.x.baseUrl', stubUrl)

        if (ec.entity.find('mantle.party.Party').condition('partyId', ownerPartyId).one() == null) {
            ec.service.sync().name('create#mantle.party.Party').disableAuthz()
                    .parameters([partyId: ownerPartyId, partyTypeEnumId: 'PtyOrganization']).call()
        }
        // apiKey/apiSecret = consumer key + secret, username/password = access token + secret
        ec.service.sync().name('store#growerp.marketing.PlatformConfiguration').disableAuthz()
                .parameters([configId: configId, ownerPartyId: ownerPartyId, platform: 'TWITTER',
                        isEnabled: 'Y', apiKey: 'ck', apiSecret: 'cs',
                        username: 'at', password: 'ats']).call()
    }

    def cleanupSpec() {
        System.clearProperty('growerp.x.baseUrl')
        if (stubServer) stubServer.stop(0)
        if (ec) ec.destroy()
    }

    def setup() {
        received.clear()
        failAtTweet = null
    }

    private EntityValue platformConfig() {
        ec.entity.find('growerp.marketing.PlatformConfiguration').condition('configId', configId).one()
    }

    private EntityValue makePost(String finalContent, String headline = 'A headline') {
        Map out = ec.service.sync().name('create#growerp.marketing.SocialPost').disableAuthz()
                .parameters([ownerPartyId: ownerPartyId, status: 'DRAFT', type: 'OTHER',
                        platform: 'TWITTER', headline: headline, finalContent: finalContent,
                        createdDate: ec.user.nowTimestamp, lastModifiedDate: ec.user.nowTimestamp]).call()
        return ec.entity.find('growerp.marketing.SocialPost').condition('postId', out.postId).one()
    }

    private Map publish(EntityValue post) {
        return ec.service.sync().name('growerp.100.SocialPostPublishingServices100.publish#SocialPostToX')
                .parameters([post: post, platformConfig: platformConfig()]).disableAuthz().call()
    }

    def "a single block posts one tweet and does not prepend the headline"() {
        when:
        Map out = publish(makePost('Just the one tweet.'))

        then:
        out.success
        out.externalPostId == '1001'
        out.publishedUrl == 'https://x.com/i/web/status/1001'
        received.size() == 1
        received[0].text == 'Just the one tweet.'
        received[0].reply == null
    }

    def "blank-line separated blocks post as a chained thread"() {
        when:
        Map out = publish(makePost('Hook tweet.\n\nSecond tweet.\n\n\nThird tweet.'))

        then:
        out.success
        received.size() == 3
        received*.text == ['Hook tweet.', 'Second tweet.', 'Third tweet.']
        received[0].reply == null
        received[1].reply.in_reply_to_tweet_id == '1001'
        received[2].reply.in_reply_to_tweet_id == '1002'

        and: 'the thread is identified by its first tweet'
        out.externalPostId == '1001'
        out.publishedUrl == 'https://x.com/i/web/status/1001'
    }

    def "a block over 280 characters fails the post without calling the API"() {
        when:
        Map out = publish(makePost('Short one.\n\n' + ('x' * 281)))

        then:
        !out.success
        out.errorMessage == 'Tweet 2 of 2 is 281 chars (max 280)'
        received.isEmpty()
        out.externalPostId == null
    }

    def "a rejected tweet names its position and keeps the thread start"() {
        setup:
        failAtTweet = 2

        when:
        Map out = publish(makePost('First.\n\nSecond.\n\nThird.'))

        then:
        !out.success
        out.errorMessage.startsWith('X API error 403 on tweet 2 of 3')
        out.errorMessage.contains('thread starts at https://x.com/i/web/status/1001')
        received.size() == 2
    }

    def "missing credentials fail before any request"() {
        setup:
        EntityValue config = platformConfig()
        config.password = null

        when:
        Map out = ec.service.sync().name('growerp.100.SocialPostPublishingServices100.publish#SocialPostToX')
                .parameters([post: makePost('Anything.'), platformConfig: config]).disableAuthz().call()

        then:
        !out.success
        out.errorMessage == 'X access token secret (password) not configured'
        received.isEmpty()
    }
}
