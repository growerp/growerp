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
import org.moqui.Moqui
import org.moqui.context.ExecutionContext
import org.moqui.entity.EntityValue
import spock.lang.IgnoreIf
import spock.lang.Shared
import spock.lang.Specification

import java.util.concurrent.CopyOnWriteArrayList

/* Tests for the LinkedIn connect in OutreachServices100.xml, against an embedded HTTP
   stub playing LinkedIn's token and userinfo endpoints:
   - start#LinkedInSignIn refuses when the GrowERP LinkedIn app is not configured
   - start#LinkedInSignIn returns the consent URL and remembers the tenant by state
   - complete#LinkedInSignIn stores token, person URN and expiry on the starting tenant
     only, and a reconnect keeps the tenant's own settings
   - an unknown state or a refused token exchange stores nothing

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class OutreachServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant
    @Shared Map otherTenant
    @Shared HttpServer stubServer
    /** Every token exchange body the stub received, in order. */
    @Shared List<String> tokenRequests = new CopyOnWriteArrayList<>()
    /** Set to make the stub refuse the token exchange. */
    @Shared boolean refuseToken = false

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        otherTenant = GrowerpTestSupport.tenant(ec, 'LinkedInOther')
        tenant = GrowerpTestSupport.tenant(ec, 'LinkedIn')

        stubServer = HttpServer.create(new InetSocketAddress('127.0.0.1', 0), 0)
        stubServer.createContext('/', { HttpExchange ex ->
            String response
            int status
            if (ex.requestURI.path == '/oauth/v2/accessToken') {
                tokenRequests.add(ex.requestBody.getText('UTF-8'))
                status = refuseToken ? 400 : 200
                response = refuseToken ? '{"error": "invalid_grant"}' :
                        '{"access_token": "li-token", "expires_in": 5184000, "scope": "openid,profile,w_member_social"}'
            } else if (ex.requestURI.path == '/v2/userinfo' &&
                    ex.requestHeaders.getFirst('Authorization') == 'Bearer li-token') {
                status = 200
                response = '{"sub": "AbC123", "name": "Ann Spock"}'
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
        String stubUrl = "http://127.0.0.1:${stubServer.address.port}"
        System.setProperty('growerp.linkedin.authBaseUrl', stubUrl)
        System.setProperty('growerp.linkedin.apiBaseUrl', stubUrl)
        System.setProperty('linkedin_oauth_redirect_uri', 'https://backend.example.com/linkedinOAuth/callback')
    }

    def cleanupSpec() {
        ['growerp.linkedin.authBaseUrl', 'growerp.linkedin.apiBaseUrl', 'linkedin_oauth_redirect_uri',
         'linkedin_oauth_client_id', 'linkedin_oauth_client_secret'].each { System.clearProperty(it) }
        if (stubServer) stubServer.stop(0)
        if (ec) {
            ec.artifactExecution.disableAuthz()
            [tenant, otherTenant].each { t ->
                ec.entity.find('growerp.marketing.PlatformConfiguration')
                        .condition('ownerPartyId', t.ownerPartyId).deleteAll()
            }
            ec.destroy()
        }
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
        ec.message.clearAll()
        tokenRequests.clear()
        refuseToken = false
        System.setProperty('linkedin_oauth_client_id', 'spock-client')
        System.setProperty('linkedin_oauth_client_secret', 'spock-secret')
        ec.user.internalLoginUser(tenant.username)
    }

    private String startSignIn() {
        Map out = ec.service.sync().name('growerp.100.OutreachServices100.start#LinkedInSignIn').call()
        return URLDecoder.decode((String) out.authUrl.split('state=')[1], 'UTF-8')
    }

    private Map complete(String state) {
        ec.user.logoutUser()
        Map out = ec.service.sync().name('growerp.100.OutreachServices100.complete#LinkedInSignIn')
                .parameters([state: state, code: 'the-code']).call()
        ec.user.internalLoginUser(tenant.username)
        return out
    }

    private EntityValue linkedInConfig(String ownerPartyId) {
        return ec.entity.find('growerp.marketing.PlatformConfiguration')
                .condition('ownerPartyId', ownerPartyId).condition('platform', 'LINKEDIN')
                .useCache(false).one()
    }

    @IgnoreIf({ System.getenv('LINKEDIN_OAUTH_CLIENT_ID') })
    def "start refuses when the GrowERP LinkedIn app is not configured"() {
        given:
        System.clearProperty('linkedin_oauth_client_id')

        when:
        ec.service.sync().name('growerp.100.OutreachServices100.start#LinkedInSignIn').call()

        then:
        ec.message.hasError()
        ec.message.errorsString.contains('not configured')
    }

    def "start returns the consent URL with scopes, redirect and a state"() {
        when:
        Map out = ec.service.sync().name('growerp.100.OutreachServices100.start#LinkedInSignIn').call()
        String clientId = System.getenv('LINKEDIN_OAUTH_CLIENT_ID') ?: 'spock-client'

        then:
        !ec.message.hasError()
        out.authUrl.startsWith('https://www.linkedin.com/oauth/v2/authorization?response_type=code')
        out.authUrl.contains('client_id=' + URLEncoder.encode(clientId, 'UTF-8'))
        out.authUrl.contains('scope=openid+profile+w_member_social')
        out.authUrl.contains('redirect_uri=' + URLEncoder.encode(
                System.getenv('LINKEDIN_OAUTH_REDIRECT_URI') ?: 'https://backend.example.com/linkedinOAuth/callback', 'UTF-8'))
        out.authUrl.contains('state=')
    }

    def "complete stores token, person URN and expiry on the starting tenant only"() {
        when:
        String state = startSignIn()
        Map out = complete(state)
        EntityValue conf = linkedInConfig(tenant.ownerPartyId)

        then:
        !ec.message.hasError()
        out.personUrn == 'urn:li:person:AbC123'
        out.name == 'Ann Spock'
        tokenRequests.size() == 1
        tokenRequests[0].contains('code=the-code')
        tokenRequests[0].contains('grant_type=authorization_code')
        conf.isEnabled == 'Y'
        conf.apiKey == 'li-token'
        conf.username == 'urn:li:person:AbC123'
        // expires_in 60 days
        Math.abs(conf.apiKeyExpireDate.time - (System.currentTimeMillis() + 5184000000L)) < 600000L
        linkedInConfig(otherTenant.ownerPartyId) == null
    }

    def "a reconnect replaces the token and keeps the tenant's own settings"() {
        given:
        complete(startSignIn())
        EntityValue conf = linkedInConfig(tenant.ownerPartyId)
        conf.apiKey = 'old-token'
        conf.dailyLimit = 7
        conf.lastCheckError = 'expired'
        conf.update()

        when:
        complete(startSignIn())
        EntityValue after = linkedInConfig(tenant.ownerPartyId)

        then:
        !ec.message.hasError()
        after.configId == conf.configId
        after.apiKey == 'li-token'
        after.dailyLimit == 7
        after.lastCheckError == null
        ec.entity.find('growerp.marketing.PlatformConfiguration')
                .condition('ownerPartyId', tenant.ownerPartyId).condition('platform', 'LINKEDIN').count() == 1
    }

    def "a state used once or unknown stores nothing"() {
        given:
        String state = startSignIn()
        complete(state)
        ec.message.clearAll()
        tokenRequests.clear()

        when:
        complete(state)

        then:
        ec.message.hasError()
        ec.message.errorsString.contains('expired')
        tokenRequests.isEmpty()
    }

    def "a refused token exchange reports the error and stores nothing"() {
        given:
        ec.entity.find('growerp.marketing.PlatformConfiguration')
                .condition('ownerPartyId', tenant.ownerPartyId).deleteAll()
        refuseToken = true

        when:
        complete(startSignIn())

        then:
        ec.message.hasError()
        ec.message.errorsString.contains('LinkedIn token exchange failed 400')
        linkedInConfig(tenant.ownerPartyId) == null
    }
}
