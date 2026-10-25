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
import spock.lang.PendingFeature
import spock.lang.Shared
import spock.lang.Specification

/* Tests for activities, time entries and notes (ActivityServices100):
   - create, get and update a todo and an event
   - create, get, update and delete a time entry, the time entry report
   - activity notes
   - another tenant does not see the activities

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class ActivityServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant, otherTenant
    @Shared String service = 'growerp.100.ActivityServices100'
    @Shared String run = Long.toString(System.currentTimeMillis(), 36)

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        otherTenant = GrowerpTestSupport.tenant(ec, 'ActivityTestOther')
        tenant = GrowerpTestSupport.tenant(ec, 'ActivityTest')
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def cleanup() {
        ec.message.clearErrors()
        if (ec.user.username != tenant.username) ec.user.internalLoginUser(tenant.username)
    }

    Map createActivity(Map activity) {
        return ec.service.sync().name("${service}.create#Activity")
                .parameters([activity: [activityType: 'todo', statusId: 'planning'] + activity])
                .call()?.activity
    }

    def "create, get and update a todo"() {
        when:
        Map todo = createActivity([activityName: "Call back ${run}", description: 'About the quote',
                assignee: [partyId: tenant.adminPartyId]])

        then:
        !ec.message.hasError()
        todo.activityId
        todo.pseudoId
        todo.activityType == 'todo'
        todo.statusId == 'planning'
        todo.assignee.partyId == tenant.adminPartyId

        when:
        List activities = ec.service.sync().name("${service}.get#Activity")
                .parameters([activityId: todo.activityId]).call().activities

        then:
        activities.size() == 1
        activities[0].activityName == "Call back ${run}"
        activities[0].description == 'About the quote'

        when: 'it is started'
        Map updated = ec.service.sync().name("${service}.update#Activity")
                .parameters([activity: [activityId: todo.activityId, activityType: 'todo',
                        activityName: "Call back ${run}", statusId: 'progress']]).call().activity

        then:
        !ec.message.hasError()
        updated.statusId == 'progress'

        when: 'the open todos are listed'
        List open = ec.service.sync().name("${service}.get#Activity")
                .parameters([activityType: 'todo', open: true, search: "Call back ${run}"]).call().activities

        then:
        open*.activityId == [todo.activityId]
    }

    @PendingFeature(reason = 'https://github.com/growerp/growerp/issues/54')
    def "create an event with a contact"() {
        given:
        Map contact = ec.service.sync().name('growerp.100.PartyServices100.create#User')
                .parameters([user: [firstName: 'Evan', lastName: "Event${run}", role: 'Customer']]).call().user

        when:
        Map event = createActivity([activityType: 'event', activityName: "Meeting ${run}",
                estimatedStartDate: ec.user.nowTimestamp, thirdParty: [partyId: contact.partyId]])

        then:
        !ec.message.hasError()
        event.activityType == 'event'
        event.thirdParty.partyId == contact.partyId

        when: 'the events of the contact are listed'
        List events = ec.service.sync().name("${service}.get#Activity")
                .parameters([activityType: 'event', userPseudoId: contact.pseudoId]).call().activities

        then:
        events*.activityId.contains(event.activityId)
    }

    def "create, get, update and delete a time entry"() {
        given:
        Map task = createActivity([activityName: "Billable ${run}"])

        when:
        Map entry = ec.service.sync().name("${service}.create#TimeEntry")
                .parameters([timeEntry: [activityId: task.activityId, partyId: tenant.adminPartyId,
                        hours: 2.5, comments: 'Design', date: ec.user.nowTimestamp]]).call().timeEntry

        then:
        !ec.message.hasError()
        entry.timeEntryId
        entry.hours as BigDecimal == 2.5

        when:
        Map read = ec.service.sync().name("${service}.get#TimeEntry")
                .parameters([timeEntryId: entry.timeEntryId]).call().timeEntry

        then:
        read.comments == 'Design'
        read.activityId == task.activityId

        when:
        Map updated = ec.service.sync().name("${service}.update#TimeEntry")
                .parameters([timeEntry: [timeEntryId: entry.timeEntryId, activityId: task.activityId,
                        partyId: tenant.adminPartyId, hours: 3, comments: 'Design and review']])
                .call().timeEntry

        then:
        !ec.message.hasError()
        updated.hours as BigDecimal == 3
        updated.comments == 'Design and review'

        when: 'the report counts the hours of the admin'
        List report = ec.service.sync().name("${service}.get#TimeEntryReport").call().reportItems

        then:
        report.find { it.partyId == tenant.adminPartyId }

        when:
        ec.service.sync().name("${service}.delete#TimeEntry")
                .parameters([timeEntry: [activityId: task.activityId, timeEntryId: entry.timeEntryId]]).call()

        then:
        !ec.message.hasError()
        ec.entity.find('mantle.work.time.TimeEntry').condition('timeEntryId', entry.timeEntryId)
                .useCache(false).one() == null
    }

    def "add and read activity notes"() {
        given:
        Map task = createActivity([activityName: "Noted ${run}"])

        when:
        ec.service.sync().name("${service}.create#ActivityNote")
                .parameters([activityId: task.activityId, noteText: 'First note']).call()
        List notes = ec.service.sync().name("${service}.get#ActivityNotes")
                .parameters([activityId: task.activityId]).call().activityNotes

        then:
        !ec.message.hasError()
        notes*.noteText == ['First note']
    }

    def "another tenant does not see the activities"() {
        given:
        Map task = createActivity([activityName: "Secret ${run}"])

        when:
        ec.user.internalLoginUser(otherTenant.username)
        List found = ec.service.sync().name("${service}.get#Activity")
                .parameters([activityId: task.activityId]).call().activities

        then:
        !found
    }
}
