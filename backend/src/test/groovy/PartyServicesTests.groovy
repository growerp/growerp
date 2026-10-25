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

/* Tests for users and companies (PartyServices100):
   - create, get, update and delete a user, with and without a company
   - create, get and update a company
   - email and company checks
   - a party of another tenant is never returned

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class PartyServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant, otherTenant
    @Shared String service = 'growerp.100.PartyServices100'
    // users are new on every run, their email is their login name
    @Shared String run = Long.toString(System.currentTimeMillis(), 36)

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        otherTenant = GrowerpTestSupport.tenant(ec, 'PartyTestOther')
        tenant = GrowerpTestSupport.tenant(ec, 'PartyTest')
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def cleanup() {
        ec.message.clearErrors()
        if (ec.user.username != tenant.username) ec.user.internalLoginUser(tenant.username)
    }

    Map createUser(Map user) {
        return ec.service.sync().name("${service}.create#User").parameters([user: user]).call()?.user
    }

    def "create, get, update and delete a customer with a company"() {
        when:
        Map user = createUser([firstName: 'Cora', lastName: "Customer${run}", role: 'Customer',
                email: "cora-${run}@spock.example.com",
                company: [name: "Cora Corp ${run}", role: 'Customer']])

        then:
        !ec.message.hasError()
        user.partyId
        user.pseudoId
        user.role == 'Customer'
        user.company.partyId
        user.company.name == "Cora Corp ${run}"

        when: 'it is read back by partyId'
        List users = ec.service.sync().name("${service}.get#User")
                .parameters([userPartyId: user.partyId]).call().users

        then:
        users.size() == 1
        users[0].lastName == "Customer${run}"
        users[0].email == "cora-${run}@spock.example.com"
        users[0].company.name == "Cora Corp ${run}"

        when: 'the name changes'
        Map updated = ec.service.sync().name("${service}.update#User")
                .parameters([user: [partyId: user.partyId, firstName: 'Corinne',
                        lastName: "Customer${run}", email: "cora-${run}@spock.example.com",
                        role: 'Customer', company: user.company]])
                .call().user

        then:
        !ec.message.hasError()
        updated.firstName == 'Corinne'

        when: 'it is deleted'
        ec.service.sync().name("${service}.delete#User").parameters([partyId: user.partyId]).call()

        then: 'the party is disabled'
        !ec.message.hasError()
        ec.entity.find('mantle.party.Party').condition('partyId', user.partyId).useCache(false).one().disabled == 'Y'
    }

    def "a lead without a company and an employee with a login"() {
        when:
        Map lead = createUser([firstName: 'Lee', lastName: "Lead${run}", role: 'Lead'])
        Map employee = createUser([firstName: 'Emma', lastName: "Employee${run}", role: 'OrgInternal',
                email: "emma-${run}@spock.example.com", loginName: "emma-${run}@spock.example.com",
                userGroupId: 'GROWERP_M_EMPLOYEE', company: [partyId: tenant.companyPartyId]])

        then:
        !ec.message.hasError()
        lead.role == 'Lead'
        !lead.company?.partyId
        employee.role == 'OrgInternal'
        employee.userGroupId == 'GROWERP_M_EMPLOYEE'
        employee.company.partyId == tenant.companyPartyId
        ec.entity.find('moqui.security.UserAccount')
                .condition('username', "emma-${run}@spock.example.com").useCache(false).one()

        when: 'the employees of the main company are listed'
        List employees = ec.service.sync().name("${service}.get#User")
                .parameters([role: 'OrgInternal', limit: 100]).call().users

        then:
        employees*.partyId.contains(employee.partyId)
        !employees*.partyId.contains(lead.partyId)
    }

    def "search users by name"() {
        given:
        Map user = createUser([firstName: 'Searchable', lastName: "Zz${run}", role: 'Customer'])

        when:
        List found = ec.service.sync().name("${service}.get#User")
                .parameters([search: "Zz${run}"]).call().users

        then:
        found*.partyId == [user.partyId]
    }

    def "create, get and update a supplier company"() {
        when:
        Map company = ec.service.sync().name("${service}.create#Company")
                .parameters([company: [name: "Supplies ${run}", role: 'Supplier',
                        email: "supplies-${run}@spock.example.com", telephoneNr: '555-0100']])
                .call().company

        then:
        !ec.message.hasError()
        company.partyId
        company.role == 'Supplier'

        when:
        List companies = ec.service.sync().name("${service}.get#Company")
                .parameters([companyPartyId: company.partyId]).call().companies

        then:
        companies.size() == 1
        companies[0].name == "Supplies ${run}"
        companies[0].email == "supplies-${run}@spock.example.com"

        when:
        Map updated = ec.service.sync().name("${service}.update#Company")
                .parameters([company: [partyId: company.partyId, name: "Supplies ${run} Ltd",
                        role: 'Supplier']]).call().company

        then:
        !ec.message.hasError()
        updated.name == "Supplies ${run} Ltd"
    }

    def "the main company has the tenant currency"() {
        when:
        List companies = ec.service.sync().name("${service}.get#Company")
                .parameters([companyPartyId: tenant.companyPartyId]).call().companies

        then:
        companies.size() == 1
        companies[0].currency?.currencyId == 'USD'
        companies[0].name == 'PartyTest Co'
    }

    def "email and company checks"() {
        expect:
        ec.service.sync().name("${service}.check#Email").parameters([email: tenant.username]).call().ok
        !ec.service.sync().name("${service}.check#Email")
                .parameters([email: "nobody-${run}@spock.example.com"]).call().ok
        ec.service.sync().name("${service}.check#Company").parameters([partyId: tenant.companyPartyId]).call().ok
    }

    def "a user of another tenant is not returned"() {
        given: 'a customer of the other tenant'
        ec.user.internalLoginUser(otherTenant.username)
        Map foreign = createUser([firstName: 'Foreign', lastName: "Other${run}", role: 'Customer'])

        when: 'the first tenant asks for it'
        ec.user.internalLoginUser(tenant.username)
        Map out = ec.service.sync().name("${service}.get#User")
                .parameters([userPartyId: foreign.partyId]).call()

        then:
        !out.users
    }

    def "deleting a party of another tenant fails"() {
        given:
        ec.user.internalLoginUser(otherTenant.username)
        Map foreign = createUser([firstName: 'Keep', lastName: "Other${run}", role: 'Customer'])
        ec.user.internalLoginUser(tenant.username)

        when:
        ec.service.sync().name("${service}.delete#User").parameters([partyId: foreign.partyId]).call()

        then:
        ec.message.hasError()
        ec.entity.find('mantle.party.Party').condition('partyId', foreign.partyId).useCache(false).one().disabled != 'Y'
    }

    def "removing the company of a user"() {
        given:
        Map user = createUser([firstName: 'Wanda', lastName: "Withco${run}", role: 'Customer',
                company: [name: "Withco ${run}", role: 'Customer']])

        when: 'the user is updated without a company'
        Map updated = ec.service.sync().name("${service}.update#User")
                .parameters([user: [partyId: user.partyId, firstName: 'Wanda',
                        lastName: "Withco${run}", role: 'Customer']]).call()?.user

        then:
        !ec.message.hasError()
        !updated.company?.partyId
    }
}
