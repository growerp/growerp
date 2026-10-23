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

import groovy.json.JsonOutput
import org.moqui.Moqui
import org.moqui.context.ExecutionContext
import org.moqui.entity.EntityList
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import spock.lang.Shared
import spock.lang.Specification

/* Tests for the public website lead-capture form's submit#WebsiteForm service:
   - a submission turns into a Lead party (lastName 'website')
   - every submission is logged as a WebsiteForm entry in the lead's
     communications list, a repeat submission reuses the same Lead

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class WebsiteFormServicesTests extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(WebsiteFormServicesTests.class)
    @Shared ExecutionContext ec

    @Shared String ownerPartyId = 'WSFORM_OWNER'
    @Shared String companyPartyId = 'WSFORM_COMP'
    @Shared String formId = 'WSFORM_FORM'

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        ec.user.loginUser('SystemSupport', 'moqui')
        ec.artifactExecution.disableAuthz()

        // owner/company/form (idempotent: the test database persists between runs)
        if (ec.entity.find('mantle.party.Party').condition('partyId', ownerPartyId).one() == null) {
            ec.service.sync().name('create#mantle.party.Party').disableAuthz()
                    .parameters([partyId: ownerPartyId, partyTypeEnumId: 'PtyOrganization']).call()
            ec.service.sync().name('create#mantle.party.Party').disableAuthz()
                    .parameters([partyId: companyPartyId, partyTypeEnumId: 'PtyOrganization',
                            ownerPartyId: ownerPartyId]).call()
            ec.service.sync().name('create#mantle.party.Organization').disableAuthz()
                    .parameters([partyId: companyPartyId, organizationName: 'Website Form Test Co']).call()
            ec.service.sync().name('create#growerp.website.WebsiteForm').disableAuthz()
                    .parameters([formId: formId, ownerPartyId: companyPartyId,
                            title: 'Contact us']).call()
            ec.service.sync().name('create#growerp.website.WebsiteFormField').disableAuthz()
                    .parameters([formId: formId, fieldId: 'name', sequenceNum: 1,
                            label: 'Name', fieldType: 'text', isRequired: 'N']).call()
            ec.service.sync().name('create#growerp.website.WebsiteFormField').disableAuthz()
                    .parameters([formId: formId, fieldId: 'email', sequenceNum: 2,
                            label: 'Email', fieldType: 'email', isRequired: 'Y']).call()
        }
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    private String leadPartyId(String email) {
        String contactMechId = ec.entity.find('mantle.party.contact.ContactMech')
                .condition('infoString', email).list().first.contactMechId
        ec.entity.find('mantle.party.contact.PartyContactMech')
                .condition('contactMechId', contactMechId).list().first.partyId
    }

    private EntityList formEvents(String partyId) {
        ec.entity.find('mantle.party.communication.CommunicationEvent')
                .condition([fromPartyId: partyId, communicationEventTypeId: 'WebsiteForm'] as Map)
                .useCache(false).list()
    }

    def "submitting a form twice gives one website Lead with two communications"() {
        setup:
        String email = "formtest${System.currentTimeMillis()}@example.com"
        String valuesJson = JsonOutput.toJson([name: 'Jan', email: email])

        when: 'the visitor submits the form twice'
        ec.service.sync().name('growerp.100.WebsiteServices100.submit#WebsiteForm')
                .parameters([formId: formId, valuesJson: valuesJson]).disableAuthz().call()
        ec.service.sync().name('growerp.100.WebsiteServices100.submit#WebsiteForm')
                .parameters([formId: formId, valuesJson: valuesJson]).disableAuthz().call()
        String partyId = leadPartyId(email)
        EntityList events = formEvents(partyId)

        then: 'one Lead with last name website'
        !ec.message.hasError()
        ec.entity.find('mantle.party.contact.ContactMech').condition('infoString', email).list().size() == 1
        ec.entity.find('mantle.party.Person').condition('partyId', partyId).one().lastName == 'website'

        and: 'each submission is logged from the lead to the company'
        events.size() == 2
        events.every {
            it.ownerPartyId == ownerPartyId && it.toPartyId == companyPartyId &&
                    it.statusId == 'CeReceived' && it.subject == 'Website form: Contact us' &&
                    it.body.contains('Name: Jan') && it.body.contains("Email: ${email}")
        }
    }
}
