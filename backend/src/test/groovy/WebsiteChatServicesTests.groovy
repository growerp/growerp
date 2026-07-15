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

import org.moqui.Moqui
import org.moqui.context.ExecutionContext
import org.moqui.entity.EntityValue
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import spock.lang.Shared
import spock.lang.Specification

/* Tests for the public website chat widget's submit#WebsiteChat service:
   - a visitor's email/question turns into a Lead party (email + name from email)
   - resubmitting the same email (same or different case) never creates a second
     Lead/party ("doubles" check)
   - the room keeps the visitor's userId (visitorUserId) so the chat UI can tag
     which messages came from the anonymous website visitor

   get#ChatRoom is intentionally NOT exercised here: it always scopes rows to the
   logged-in caller's own company and, for SystemSupport, hard-filters isPrivate='Y',
   which the public support room (isPrivate='N') would never match. Assertions instead
   read the growerp.general.ChatRoom/ChatMessage and mantle.party.* entities directly,
   plus get#User (which accepts an explicit ownerPartyId override) for the Lead-list check.

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class WebsiteChatServicesTests extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(WebsiteChatServicesTests.class)
    @Shared ExecutionContext ec

    @Shared String ownerPartyId = 'WSCHAT_OWNER'
    @Shared String companyPartyId = 'WSCHAT_COMP'
    @Shared String productStoreId = 'WSCHAT_STORE'

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        ec.user.loginUser('SystemSupport', 'moqui')
        ec.artifactExecution.disableAuthz()

        // owner/company/store hierarchy the widget's productStoreId resolves through
        // (idempotent: the test database persists between runs)
        if (ec.entity.find('mantle.party.Party').condition('partyId', ownerPartyId).one() == null) {
            ec.service.sync().name('create#mantle.party.Party').disableAuthz()
                    .parameters([partyId: ownerPartyId, partyTypeEnumId: 'PtyOrganization']).call()
            ec.service.sync().name('create#mantle.party.Party').disableAuthz()
                    .parameters([partyId: companyPartyId, partyTypeEnumId: 'PtyOrganization',
                            ownerPartyId: ownerPartyId]).call()
            ec.service.sync().name('create#mantle.party.Organization').disableAuthz()
                    .parameters([partyId: companyPartyId, organizationName: 'Website Chat Test Co']).call()
            ec.service.sync().name('create#mantle.product.store.ProductStore').disableAuthz()
                    .parameters([productStoreId: productStoreId, organizationPartyId: companyPartyId,
                            storeName: 'Website Chat Test Store']).call()
        }
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    /** the Person/ContactMech/PartyRole created (or reused) for a visitor email */
    private Map visitorPartyDetail(String email) {
        EntityValue contactMech = ec.entity.find('mantle.party.contact.ContactMech')
                .condition('infoString', email).list().first
        assert contactMech != null
        EntityValue partyContactMech = ec.entity.find('mantle.party.contact.PartyContactMech')
                .condition('contactMechId', contactMech.contactMechId).list().first
        String partyId = partyContactMech.partyId
        EntityValue person = ec.entity.find('mantle.party.Person').condition('partyId', partyId).one()
        EntityValue party = ec.entity.find('mantle.party.Party').condition('partyId', partyId).one()
        EntityValue role = ec.entity.find('mantle.party.PartyRole').condition('partyId', partyId).list().first
        [partyId: partyId, person: person, party: party, role: role]
    }

    def "submit#WebsiteChat creates a Lead with the email address and the name from the email"() {
        setup:
        String email = 'leadtest1@example.com'

        when:
        Map out = ec.service.sync().name('growerp.100.ChatServices100.submit#WebsiteChat')
                .parameters([productStoreId: productStoreId, email: email, question: 'Can I connect my CRM?'])
                .disableAuthz().call()
        Map detail = visitorPartyDetail(email)

        then:
        out.visitorUserId
        out.chatRoomId
        detail.person.firstName == 'leadtest1'
        detail.person.lastName == 'website'
        detail.party.customerStatusId == 'CUSTOMER_ASSIGNED'
        detail.role.roleTypeId == 'Customer'

        and: 'the new Lead shows up in the Lead list'
        // NOTE: get#User's "search" param does not match on email (pre-existing bug in the
        // OwnerPersonDetailAndCompany view-entity's emailAddress condition, unrelated to this
        // feature) -- list unfiltered and check client-side instead of relying on search.
        Map users = ec.service.sync().name('growerp.100.PartyServices100.get#User')
                .parameters([role: 'Lead', ownerPartyId: ownerPartyId])
                .disableAuthz().call()
        users.users.any { it.email == email && it.firstName == 'leadtest1' }
    }

    def "resubmitting the same email does not create a duplicate Lead"() {
        setup:
        String email = 'leadtest2@example.com'

        when: 'the visitor chats twice'
        Map first = ec.service.sync().name('growerp.100.ChatServices100.submit#WebsiteChat')
                .parameters([productStoreId: productStoreId, email: email, question: 'First question'])
                .disableAuthz().call()
        Map second = ec.service.sync().name('growerp.100.ChatServices100.submit#WebsiteChat')
                .parameters([productStoreId: productStoreId, email: email, question: 'Second question'])
                .disableAuthz().call()

        then: 'both messages come from the same visitor account'
        second.visitorUserId == first.visitorUserId

        and: 'exactly one contact mech / disabled account exists for the email'
        ec.entity.find('mantle.party.contact.ContactMech').condition('infoString', email).list().size() == 1
        ec.entity.find('moqui.security.UserAccount')
                .condition([userFullName: email, disabled: 'Y'] as Map).list().size() == 1

        and: 'a fresh room (ticket) is still created per question'
        second.chatRoomId != first.chatRoomId
    }

    def "resubmitting with a different email case resolves to the same Lead"() {
        setup:
        String mixedCaseEmail = 'LeadTest3@Example.com'
        String lowerEmail = 'leadtest3@example.com'

        when:
        Map first = ec.service.sync().name('growerp.100.ChatServices100.submit#WebsiteChat')
                .parameters([productStoreId: productStoreId, email: mixedCaseEmail, question: 'Mixed case question'])
                .disableAuthz().call()
        Map second = ec.service.sync().name('growerp.100.ChatServices100.submit#WebsiteChat')
                .parameters([productStoreId: productStoreId, email: lowerEmail, question: 'Lower case question'])
                .disableAuthz().call()

        then: 'no duplicate is created for the case-mismatched email'
        second.visitorUserId == first.visitorUserId
        ec.entity.find('mantle.party.contact.ContactMech').condition('infoString', lowerEmail).list().size() == 1
        ec.entity.find('mantle.party.contact.ContactMech')
                .condition('infoString', mixedCaseEmail).list().size() == 0
    }

    def "the visitor's chat message is tagged with the room's visitorUserId for origin display"() {
        setup:
        String email = 'leadtest4@example.com'

        when:
        Map out = ec.service.sync().name('growerp.100.ChatServices100.submit#WebsiteChat')
                .parameters([productStoreId: productStoreId, email: email, question: 'Where do I start?'])
                .disableAuthz().call()
        EntityValue chatRoom = ec.entity.find('growerp.general.ChatRoom')
                .condition('chatRoomId', out.chatRoomId).one()
        EntityValue firstMessage = ec.entity.find('growerp.general.ChatMessage')
                .condition('chatRoomId', out.chatRoomId).list().first

        then: 'the room remembers the visitor, and the first message came from that visitor'
        chatRoom.visitorUserId == out.visitorUserId
        firstMessage.fromUserId == chatRoom.visitorUserId
    }
}
