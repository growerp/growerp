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
import spock.lang.Shared
import spock.lang.Specification

/* Tests for GeneralServices100 support statistics:
   - get#SignupStatistics charts every registration per day, but lists only the
     tenants that logged in
   and migrate#ServiceUserPasswords:
   - the mcp-user and agent-claude accounts lose their default password 'moqui',
     so nobody can sign in with it; running it again changes nothing
   and get#BackendUrl:
   - Application.version only routes newer (in review) apps to the review backend;
     an older app is forced to update only below Application.minVersion

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class GeneralServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        // registered, but never called login#User
        tenant = GrowerpTestSupport.tenant(ec, 'SignupNoLogin')
    }

    def cleanupSpec() {
        ec?.entity?.find('growerp.Application')?.condition('applicationId', 'AppVersionTest')?.deleteAll()
        if (ec) ec.destroy()
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
        ec.message.clearAll()
        ec.user.internalLoginUser('SystemSupport')
    }

    def "signup chart counts a registration that never logged in, the list does not"() {
        given: "the day the tenant registered"
        def event = ec.entity.find('mantle.work.effort.WorkEffort')
                .condition('workEffortName', 'New tenant & admin created')
                .condition('ownerPartyId', tenant.ownerPartyId).one()
        String day = ec.l10n.format(event.actualStartDate, 'yyyy-MM-dd')
        def registrations = ec.entity.find('mantle.work.effort.WorkEffort')
                .condition('workEffortName', 'New tenant & admin created')
                .condition('actualStartDate', 'greater-equals', java.sql.Timestamp.valueOf("${day} 00:00:00"))
                .condition('actualStartDate', 'less-equals', java.sql.Timestamp.valueOf("${day} 23:59:59"))
                .count()

        when:
        Map result = ec.service.sync().name('growerp.100.GeneralServices100.get#SignupStatistics')
                .parameters([startDateTime: "${day} 00:00:00", endDateTime: "${day} 23:59:59",
                        limit: 10000]).call()

        then:
        !ec.message.hasError()
        result.dailyCounts.find { it.date == day }?.count == registrations
        !result.signups.any { it.ownerPartyId == tenant.ownerPartyId }
        result.signupCount < registrations
    }

    def "service users lose their default password and cannot sign in with it"() {
        given: 'both accounts as an existing database has them, password moqui'
        ['MCP_USER': 'mcp-user', 'AGENT_CLAUDE': 'agent-claude'].each { userId, username ->
            ec.entity.makeValue('moqui.security.UserAccount').setAll([userId: userId, username: username,
                    currentPassword: '16ac58bbfa332c1c55bd98b53e60720bfa90d394', passwordHashType: 'SHA',
                    passwordSalt: null]).createOrUpdate()
        }

        when:
        Map first = ec.service.sync().name('growerp.100.GeneralServices100.migrate#ServiceUserPasswords').call()
        Map second = ec.service.sync().name('growerp.100.GeneralServices100.migrate#ServiceUserPasswords').call()
        List accounts = ec.entity.find('moqui.security.UserAccount')
                .condition('userId', 'in', ['MCP_USER', 'AGENT_CLAUDE']).list()
        boolean mcpLogin = ec.user.loginUser('mcp-user', 'moqui')
        boolean agentLogin = ec.user.loginUser('agent-claude', 'moqui')
        ec.message.clearAll()

        then:
        first.cleared == 2
        second.cleared == 0
        accounts.size() == 2
        accounts.every { it.currentPassword == null }
        !mcpLogin
        !agentLogin
    }

    private Map backendUrl(String version, Map app) {
        ec.entity.makeValue('growerp.Application')
                .setAll([applicationId: 'AppVersionTest', backendUrl: 'https://review.example.com'] + app)
                .createOrUpdate()
        return ec.service.sync().name('growerp.100.GeneralServices100.get#BackendUrl')
                .parameters([applicationId: 'AppVersionTest', version: version, platform: 'android']).call()
    }

    def "an app older than the review version is not forced to update"() {
        when: 'production was upgraded, the new 1.22 app is still in review'
        Map result = backendUrl('1.21.0', [version: '1.22.0', minVersion: null])

        then:
        !ec.message.hasError()
        !result.forceUpdate
        !result.backendUrl
    }

    def "an app older than minVersion is forced to update"() {
        when:
        Map result = backendUrl('1.20.5', [version: '1.22.0', minVersion: '1.21.0'])

        then:
        !ec.message.hasError()
        result.forceUpdate
        result.minVersion == '1.21.0'
        result.updateUrl == 'https://play.google.com/store/apps/details?id=org.growerp.versiontest'
    }

    def "an app at minVersion is not forced to update"() {
        when:
        Map result = backendUrl('1.21.3', [version: '1.22.0', minVersion: '1.21.0'])

        then:
        !ec.message.hasError()
        !result.forceUpdate
    }

    def "an app newer than the review version goes to the review backend"() {
        when:
        Map result = backendUrl('1.23.0', [version: '1.22.0', minVersion: '1.21.0'])

        then:
        !ec.message.hasError()
        !result.forceUpdate
        result.backendUrl == 'https://review.example.com'
    }

    def "add#Application stores minVersion"() {
        given:
        ec.entity.makeValue('growerp.Application').setAll([applicationId: 'AppVersionTest']).createOrUpdate()

        when:
        ec.service.sync().name('growerp.100.GeneralServices100.add#Application')
                .parameters([application: [applicationId: 'VersionTest', version: '1.22.0',
                        minVersion: '1.21.0', backendUrl: 'https://review.example.com']]).call()
        def app = ec.entity.find('growerp.Application').condition('applicationId', 'AppVersionTest').one()

        then:
        !ec.message.hasError()
        app.version == '1.22.0'
        app.minVersion == '1.21.0'
    }
}
