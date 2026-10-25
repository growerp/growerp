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

/* Tests for sales opportunities (CrmServices100):
   - create, get, update and delete an opportunity of a lead
   - the stage summary and the CRM dashboard
   - another tenant does not see the opportunities

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class CrmServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant, otherTenant, lead
    @Shared String service = 'growerp.100.CrmServices100'
    @Shared String run = Long.toString(System.currentTimeMillis(), 36)

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        otherTenant = GrowerpTestSupport.tenant(ec, 'CrmTestOther')
        tenant = GrowerpTestSupport.tenant(ec, 'CrmTest')
        lead = ec.service.sync().name('growerp.100.PartyServices100.create#User')
                .parameters([user: [firstName: 'Lena', lastName: "Lead${run}", role: 'Lead',
                        company: [name: "Prospect ${run}", role: 'Lead']]]).call().user
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def cleanup() {
        ec.message.clearErrors()
        if (ec.user.username != tenant.username) ec.user.internalLoginUser(tenant.username)
    }

    Map createOpportunity(String name, Map fields = [:]) {
        return ec.service.sync().name("${service}.create#Opportunity")
                .parameters([opportunity: [opportunityName: name, stageId: 'Prospecting',
                        estAmount: 1000, estProbability: 20,
                        employeeUser: [partyId: tenant.adminPartyId],
                        leadUser: [partyId: lead.partyId]] + fields]).call()?.opportunity
    }

    def "create, get, update and delete an opportunity"() {
        when:
        Map opportunity = createOpportunity("Deal ${run}", [description: 'Ten licenses', nextStep: 'Demo'])

        then:
        !ec.message.hasError()
        opportunity.opportunityId
        opportunity.pseudoId
        opportunity.stageId == 'Prospecting'
        opportunity.leadUser.partyId == lead.partyId
        opportunity.employeeUser.partyId == tenant.adminPartyId

        when:
        List opportunities = ec.service.sync().name("${service}.get#Opportunity")
                .parameters([opportunityId: opportunity.opportunityId]).call().opportunities

        then:
        opportunities.size() == 1
        opportunities[0].opportunityName == "Deal ${run}"
        opportunities[0].nextStep == 'Demo'
        opportunities[0].estAmount as BigDecimal == 1000

        when: 'it moves to the proposal stage'
        Map updated = ec.service.sync().name("${service}.update#Opportunity")
                .parameters([opportunity: [opportunityId: opportunity.opportunityId,
                        opportunityName: "Deal ${run}", stageId: 'Proposal', estAmount: 1500,
                        estProbability: 60, employeeUser: [partyId: tenant.adminPartyId],
                        leadUser: [partyId: lead.partyId]]]).call().opportunity

        then:
        !ec.message.hasError()
        updated.stageId == 'Proposal'
        updated.estAmount as BigDecimal == 1500

        when:
        ec.service.sync().name("${service}.delete#Opportunity")
                .parameters([opportunity: [opportunityId: opportunity.opportunityId]]).call()

        then: 'it is kept in the deleted stage and left out of the list'
        !ec.message.hasError()
        ec.service.sync().name("${service}.get#Opportunity")
                .parameters([opportunityId: opportunity.opportunityId]).call().opportunities[0].stageId == 'Deleted'
        !ec.service.sync().name("${service}.get#Opportunity")
                .parameters([search: "Deal ${run}"]).call().opportunities
    }

    def "search opportunities"() {
        given:
        Map opportunity = createOpportunity("Findable ${run}")

        when:
        List found = ec.service.sync().name("${service}.get#Opportunity")
                .parameters([search: "Findable ${run}"]).call().opportunities

        then:
        found*.opportunityId == [opportunity.opportunityId]
    }

    def "the stage summary counts the opportunities"() {
        given:
        createOpportunity("Counted ${run}", [stageId: 'Qualification', estAmount: 400, estProbability: 50])

        when:
        List stages = ec.service.sync().name("${service}.get#OpportunitySummary").call().stageSummary
        Map dashboard = ec.service.sync().name("${service}.get#CrmDashboard").call()

        then:
        !ec.message.hasError()
        stages.find { it.stageId == 'Qualification' }?.opportunityCount as Integer >= 1
        dashboard.totalContacts as Integer >= 1
    }

    def "another tenant does not see the opportunities"() {
        given:
        Map opportunity = createOpportunity("Hidden ${run}")

        when:
        ec.user.internalLoginUser(otherTenant.username)
        List found = ec.service.sync().name("${service}.get#Opportunity")
                .parameters([opportunityId: opportunity.opportunityId]).call().opportunities

        then:
        !found
    }
}
