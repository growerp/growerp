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

/* Tests for the email nurture sequence services (NurtureServices100.xml):
   - step bodies are markdown and are stored and returned unchanged
   - a sent step is the markdown rendered to html with placeholders, tracked links,
     unsubscribe footer and open pixel
   - migrate#EmailSequenceStepBody converts the html bodies of GROWERP sequences to
     markdown, once, and leaves other owners alone

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class NurtureServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        tenant = GrowerpTestSupport.tenant(ec, 'Nurture')
    }

    def cleanupSpec() {
        ec.artifactExecution.disableAuthz()
        ['SPOCK_NURTURE_GROWERP', 'SPOCK_NURTURE_OTHER'].each { id ->
            ec.entity.find('growerp.marketing.EmailSequenceStep').condition('emailSequenceId', id).deleteAll()
            ec.entity.find('growerp.marketing.EmailSequence').condition('emailSequenceId', id).deleteAll()
        }
        if (ec) ec.destroy()
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
        ec.message.clearAll()
        ec.user.internalLoginUser(tenant.username)
    }

    def "create and get keep a markdown step body unchanged"() {
        when:
        String markdown = 'Hi {name},\n\n- **one**\n- two\n\n[read more]({track:https://growerp.com})'
        Map created = ec.service.sync().name('growerp.100.NurtureServices100.create#EmailSequence')
                .parameters([emailSequence: [sequenceName: 'Markdown sequence', steps: [
                        [delayDays: 0, subject: 'Hello {name}', body: markdown]]]]).call()
        Map got = ec.service.sync().name('growerp.100.NurtureServices100.get#EmailSequence')
                .parameters([emailSequenceId: created.emailSequence.emailSequenceId]).call()

        then:
        !ec.message.hasError()
        got.emailSequences[0].steps[0].body == markdown
    }

    def "a due step is sent as html rendered from its markdown"() {
        given:
        Map created = ec.service.sync().name('growerp.100.NurtureServices100.create#EmailSequence')
                .parameters([emailSequence: [sequenceName: 'Send sequence', steps: [
                        [delayDays: 0, subject: 'Hello {name}',
                         body: 'Hi {name},\n\n- **one**\n\n[read more]({track:https://growerp.com/x})\n\n<b>raw</b>']]]]).call()
        Map enrolled = ec.service.sync().name('growerp.100.NurtureServices100.enroll#EmailSequence')
                .parameters([emailSequenceId: created.emailSequence.emailSequenceId,
                        emailAddress: 'nurture-lead@spock.example.com', firstName: 'Ann']).call()

        when:
        Map sent = ec.service.sync().name('growerp.100.NurtureServices100.process#SequenceEnrollment')
                .parameters([enrollmentId: enrolled.enrollmentId]).call()
        String html = sent.emailBody

        then:
        !ec.message.hasError()
        html.contains('Hi Ann,')
        html.contains('<li><strong>one</strong></li>')
        html.contains('/nurture/click?id=' + enrolled.enrollmentId)
        html.contains('url=https%3A%2F%2Fgrowerp.com%2Fx')
        html.contains('>read more</a>')
        html.contains('&lt;b&gt;raw&lt;/b&gt;')
        html.contains('/nurture/unsubscribe?id=' + enrolled.enrollmentId + '&amp;token=')
        html.contains('/nurture/open?id=' + enrolled.enrollmentId + '&amp;token=')
    }

    def "migrate converts html bodies of GROWERP sequences to markdown once"() {
        given:
        String html = '<p>Hi {name},</p>\n<p>A few days in &#8212; try:</p>\n<ul>\n' +
                '<li><b>Invite</b> your team.</li>\n<li>Explore the <i>dashboard</i>.</li>\n</ul>\n' +
                '<p>Questions? <a href="https://growerp.com">Ask us</a><br/>Thanks</p>\n<br/><br/><br/>'
        ec.entity.makeValue('growerp.marketing.EmailSequence').setAll([emailSequenceId: 'SPOCK_NURTURE_GROWERP',
                ownerPartyId: 'GROWERP', sequenceName: 'Spock GROWERP', status: 'PAUSED']).create()
        ec.entity.makeValue('growerp.marketing.EmailSequenceStep').setAll([emailSequenceId: 'SPOCK_NURTURE_GROWERP',
                stepSeq: 1, delayDays: 0, subject: 'Hi', bodyHtml: html]).create()
        ec.entity.makeValue('growerp.marketing.EmailSequence').setAll([emailSequenceId: 'SPOCK_NURTURE_OTHER',
                ownerPartyId: tenant.ownerPartyId, sequenceName: 'Spock other', status: 'PAUSED']).create()
        ec.entity.makeValue('growerp.marketing.EmailSequenceStep').setAll([emailSequenceId: 'SPOCK_NURTURE_OTHER',
                stepSeq: 1, delayDays: 0, subject: 'Hi', bodyHtml: html]).create()

        when:
        ec.service.sync().name('growerp.100.NurtureServices100.migrate#EmailSequenceStepBody').call()
        def growerpStep = ec.entity.find('growerp.marketing.EmailSequenceStep')
                .condition([emailSequenceId: 'SPOCK_NURTURE_GROWERP', stepSeq: 1]).useCache(false).one()
        def otherStep = ec.entity.find('growerp.marketing.EmailSequenceStep')
                .condition([emailSequenceId: 'SPOCK_NURTURE_OTHER', stepSeq: 1]).useCache(false).one()

        then:
        !ec.message.hasError()
        growerpStep.body == 'Hi {name},\n\nA few days in — try:\n\n' +
                '- **Invite** your team.\n- Explore the _dashboard_.\n\n' +
                'Questions? [Ask us](https://growerp.com)\nThanks'
        growerpStep.bodyHtml == null
        otherStep.body == null
        otherStep.bodyHtml == html

        when: 'run again'
        growerpStep.body = 'edited'
        growerpStep.update()
        ec.service.sync().name('growerp.100.NurtureServices100.migrate#EmailSequenceStepBody').call()

        then: 'a converted step is not touched again'
        ec.entity.find('growerp.marketing.EmailSequenceStep')
                .condition([emailSequenceId: 'SPOCK_NURTURE_GROWERP', stepSeq: 1]).useCache(false).one()
                .body == 'edited'
    }
}
