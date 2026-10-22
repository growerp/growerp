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

/* Tests for the communications log services (CommunicationServices100):
   - create, get, update and delete a manual communication
   - a system email (AutoEmail) cannot be entered by hand
   - an unknown party gives an empty list, never all communications

   The services scope on the logged in user's owner, so the tests run as an
   admin user of a test owner.

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class CommunicationServicesTests extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(CommunicationServicesTests.class)
    @Shared ExecutionContext ec

    @Shared String ownerPartyId = 'COMMTEST_OWNER'
    @Shared String adminPartyId = 'COMMTEST_ADMIN'
    @Shared String adminUsername = 'commtest-admin'
    @Shared String leadPartyId = 'COMMTEST_LEAD'
    @Shared String service = 'growerp.100.CommunicationServices100'

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        ec.artifactExecution.disableAuthz()

        // owner, its admin user and a lead (idempotent: the test database persists between runs)
        if (ec.entity.find('mantle.party.Party').condition('partyId', ownerPartyId).one() == null) {
            ec.service.sync().name('create#mantle.party.Party').disableAuthz()
                    .parameters([partyId: ownerPartyId, pseudoId: ownerPartyId,
                            partyTypeEnumId: 'PtyOrganization', ownerPartyId: ownerPartyId]).call()
            ec.service.sync().name('create#mantle.party.Organization').disableAuthz()
                    .parameters([partyId: ownerPartyId, organizationName: 'Communication Test Co']).call()
            [(adminPartyId): 'Admin', (leadPartyId): 'Lead'].each { partyId, firstName ->
                ec.service.sync().name('create#mantle.party.Party').disableAuthz()
                        .parameters([partyId: partyId, pseudoId: partyId,
                                partyTypeEnumId: 'PtyPerson', ownerPartyId: ownerPartyId]).call()
                ec.service.sync().name('create#mantle.party.Person').disableAuthz()
                        .parameters([partyId: partyId, firstName: firstName, lastName: 'commtest']).call()
            }
            ec.service.sync().name('create#moqui.security.UserAccount').disableAuthz()
                    .parameters([partyId: adminPartyId, username: adminUsername,
                            userFullName: 'Admin commtest', disabled: 'N']).call()
        }
        ec.user.internalLoginUser(adminUsername)
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def cleanup() {
        ec.message.clearErrors()
    }

    def "create, get, update and delete a communication"() {
        when: 'a phone call is logged'
        Map created = ec.service.sync().name("${service}.create#CommunicationEvent")
                .parameters([communicationEvent: [partyPseudoId: leadPartyId, type: 'Phone',
                        direction: 'outgoing', subject: 'Intro call', body: 'Talked about pricing']])
                .call()
        String id = created.communicationEvent?.communicationEventId

        then:
        !ec.message.hasError()
        id
        created.communicationEvent.toPartyPseudoId == leadPartyId
        created.communicationEvent.fromPartyPseudoId == adminPartyId

        when: 'the lead list is read'
        List events = ec.service.sync().name("${service}.get#CommunicationEvent")
                .parameters([userPseudoId: leadPartyId]).call().communicationEvents

        then:
        events.any { it.communicationEventId == id && it.subject == 'Intro call' && it.type == 'Phone' }

        when: 'it is updated to an incoming email'
        Map updated = ec.service.sync().name("${service}.update#CommunicationEvent")
                .parameters([communicationEvent: [communicationEventId: id, type: 'Email',
                        direction: 'incoming', subject: 'Reply', body: 'Sounds good']])
                .call()

        then: 'type, direction and parties changed'
        !ec.message.hasError()
        updated.communicationEvent.type == 'Email'
        updated.communicationEvent.direction == 'incoming'
        updated.communicationEvent.subject == 'Reply'
        updated.communicationEvent.fromPartyPseudoId == leadPartyId

        when: 'it is deleted'
        ec.service.sync().name("${service}.delete#CommunicationEvent")
                .parameters([communicationEvent: [communicationEventId: id]]).call()

        then:
        !ec.message.hasError()
        ec.entity.find('mantle.party.communication.CommunicationEvent')
                .condition('communicationEventId', id).useCache(false).one() == null
    }

    def "a system email cannot be entered by hand"() {
        when:
        ec.service.sync().name("${service}.create#CommunicationEvent")
                .parameters([communicationEvent: [partyPseudoId: leadPartyId, type: 'AutoEmail',
                        subject: 'Fake system mail']])
                .call()

        then:
        ec.message.hasError()
        ec.message.errorsString.contains('System emails are logged automatically')
    }

    def "an unknown party gives an empty list"() {
        when:
        Map out = ec.service.sync().name("${service}.get#CommunicationEvent")
                .parameters([userPseudoId: 'NO_SUCH_PARTY']).call()

        then:
        !ec.message.hasError()
        !out.communicationEvents
    }
}
