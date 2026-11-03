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
import spock.lang.Stepwise
import spock.lang.Unroll

/* Tests for agent program mode (moqui-adk AdkProgramServices, org.moqui.adk.AdkProgram):
   - the sandbox: only whitelisted elements and expressions, literal allowed service names
   - a save, a team upload and a test run refuse a program that breaks the rules
   - a run executes as the company's AI agent user, through the governance gate:
     reads run, writes are simulated in a test run, held for approval or executed per write policy
   - a run is logged with no tokens; a scheduled run posts the report to the agent's room
   - generate: the LLM's answer is checked, its problems go back for another try
   - a program that grows a value without bound is stopped
   The LLM answers are given in test mode (growerp.testMode), no API call.

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test --tests AdkProgramServicesTests"
 */
@Stepwise
class AdkProgramServicesTests extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(AdkProgramServicesTests.class)
    @Shared ExecutionContext ec
    @Shared Map tenant
    @Shared Map otherTenant
    @Shared String run = System.currentTimeMillis().toString()
    @Shared Map readAgent
    @Shared Map writeAgent

    static final String CATALOG = 'growerp.100.CatalogServices100'

    static final String READ_PROGRAM = '''<actions>
    <service-call name="growerp.100.CatalogServices100.get#ProductCategory" in-map="[limit: 100]" out-map="found"/>
    <set field="names" from="(found.categories ?: []).collect { it.categoryName }.findAll { it.startsWith(prefix) }.sort()"/>
    <if condition="!names">
        <set field="report" value="No categories."/>
        <return/>
    </if>
    <set field="report" from="'Categories: ' + names.join(', ')"/>
</actions>'''

    static final String WRITE_PROGRAM = '''<actions>
    <service-call name="growerp.100.CatalogServices100.create#ProductCategory"
        in-map="[category: [categoryName: prefix + ' made by program']]" out-map="made"/>
    <set field="report" from="made.approvalPending ? 'waiting for approval' : (made.simulated ? 'simulated' : 'created ' + made.category?.categoryName)"/>
</actions>'''

    def setupSpec() {
        System.setProperty('growerp.testMode', 'true')
        ec = Moqui.getExecutionContext()
        tenant = GrowerpTestSupport.tenant(ec, 'Program')
        otherTenant = GrowerpTestSupport.tenant(ec, 'ProgramOther')
    }

    def cleanupSpec() {
        System.clearProperty('growerp.testMode')
        if (ec) ec.destroy()
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
        ec.message.clearAll()
        ec.user.internalLoginUser(tenant.username)
    }

    private List<Map> validate(String program, String toolMode = 'scoped', String allow = '*#ProductCategory',
                               String writePolicy = 'approve') {
        return ec.service.sync().name('AdkProgramServices.validate#AgentProgram')
                .parameters([programText: program, toolMode: toolMode, serviceAllowlist: allow, writePolicy: writePolicy])
                .call().issues as List<Map>
    }

    private Map createAgent(Map fields) {
        Map out = ec.service.sync().name('AdkServices100.create#AdkAgentConfig').parameters([
                agentName: "Program ${fields.agentName} ${run}", instruction: 'List the product categories.',
                toolMode: 'scoped', serviceAllowlist: '*#ProductCategory', writePolicy: 'approve',
                parameters: '[{"name":"prefix","label":"Name prefix","value":"Prog' + run + '"}]'] +
                fields.findAll { it.key != 'agentName' }).call()
        assert !ec.message.hasError(), ec.message.errorsString
        return out.adkAgentConfig as Map
    }

    private Map runProgram(String adkAgentConfigId, boolean dryRun = false) {
        Map out = ec.service.sync().name('AdkProgramServices.run#AgentProgram')
                .parameters([adkAgentConfigId: adkAgentConfigId, dryRun: dryRun]).call()
        assert !ec.message.hasError(), ec.message.errorsString
        return out
    }

    private List categories(Map t, String name) {
        ec.user.internalLoginUser(t.username)
        List found = ec.service.sync().name("${CATALOG}.get#ProductCategory").parameters([limit: 200])
                .call().categories.findAll { it.categoryName == name }
        ec.user.internalLoginUser(tenant.username)
        return found
    }

    def "a read program passes the sandbox"() {
        expect:
        validate(READ_PROGRAM) == []
        validate(WRITE_PROGRAM) == []
    }

    @Unroll
    def "the sandbox refuses #reason"() {
        when:
        List<Map> issues = validate(program)

        then:
        issues
        issues.every { it.level == 'error' }
        issues*.message.join(' ').contains(expected)

        where:
        reason                       | program                                                                                                     | expected
        'a script element'           | '<actions><script>System.exit(0)</script></actions>'                                                       | '<script> is not allowed'
        'an entity find'             | '<actions><entity-find entity-name="mantle.party.Party" list="x"/></actions>'                             | '<entity-find> is not allowed'
        'a while loop'               | '<actions><while condition="true"/></actions>'                                                             | '<while> is not allowed'
        'ec in a condition'          | call('<if condition="ec.user.userId"><set field="report" value="x"/></if>')                                | 'ec is not available'
        'context access'             | call('<set field="x" from="context.cfg"/>')                                                                | 'context is not available'
        'a static call'              | call('<set field="x" from="System.exit(0)"/>')                                                             | 'System is not available'
        'a constructor'              | call('<set field="x" from="new File(&quot;/etc/passwd&quot;).text"/>')                                     | 'new objects are not allowed'
        'the class property'         | call('<set field="x" from="found.class"/>')                                                                | 'property class is not allowed'
        'a subscript to class'       | call('<set field="x" from="found[&apos;class&apos;]"/>')                                                    | 'this key is not allowed'
        'a non-listed method'        | call('<set field="x" from="&apos;ls&apos;.execute()"/>')                                                    | 'method execute() is not allowed'
        'an unknown function'        | call('<set field="x" from="evaluate(&apos;1&apos;)"/>')                                                     | 'function evaluate() is not available'
        'a range'                    | call('<set field="x" from="(1..1000000000).toList()"/>')                                                   | 'ranges are not allowed'
        'string multiplication'      | call('<set field="x" from="&apos;x&apos; * 1000000000"/>')                                                  | 'operator * is not allowed'
        'an assignment'              | call('<set field="x" from="found = null"/>')                                                               | 'operator = is not allowed'
        'a declaration in a closure' | call('<set field="x" from="[1].collect { def y = it; y }"/>')                                              | 'declarations are not allowed'
        'two statements'             | call('<set field="x" from="1; 2"/>')                                                                       | 'must be one expression'
        'a dangerous text'           | call('<set field="x" value="${System.getenv()}"/>')                                                        | 'System is not available'
        'a triple quote in text'     | call('<set field="x" value="a&quot;&quot;&quot;+System.exit(0)+&quot;&quot;&quot;"/>')                      | 'triple quotes'
        'a backslash'                | call('<set field="x" value="\\u0022"/>')                                                                   | 'backslash'
        'a field-name injection'     | call('<set field="x&quot;);System.exit(0);(&quot;" value="1"/>')                                          | 'must be a plain name'
        'an unknown attribute'       | call('<set field="x" from="1" location="component://x.groovy"/>')                                          | 'no attribute location'
        'a service outside growerp'  | '<actions><service-call name="org.moqui.impl.BasicServices.noop#Test"/></actions>'                         | 'not a growerp.* service'
        'a service name injection'   | '<actions><service-call name="growerp.100.CatalogServices100.get#ProductCategory&quot;).call();System.exit(0);ec.service.sync().name(&quot;x"/></actions>' | 'not a growerp.* service'
        'a not allowed service'      | '<actions><service-call name="growerp.100.CatalogServices100.get#Product"/></actions>'                     | 'not in this agent'
        'no service call'            | '<actions><set field="report" value="hi"/></actions>'                                                      | 'calls no service'
        'not xml'                    | '<actions><set field="x"></actions>'                                                                       | 'not valid XML'
    }

    /** A valid service call plus the given elements. */
    private static String call(String elements) {
        return '<actions><service-call name="growerp.100.CatalogServices100.get#ProductCategory" out-map="found"/>' +
                elements + '</actions>'
    }

    def "the date and number functions read what the services return"() {
        given:
        // moqui-adk is another component: not on the test compile classpath
        Map<String, Closure> f = Thread.currentThread().contextClassLoader.loadClass('org.moqui.adk.AdkProgram').helpers()

        expect:
        f.formatDate.call(date) == expected
        f.formatNumber.call('12.345') == '12.35'
        f.times.call('2.5', 4) == 10.0
        f.daysAgo.call('1') < new java.sql.Timestamp(System.currentTimeMillis())

        where:
        date                        | expected
        '2026-11-03 05:00:56+0000'  | '2026-11-03'
        '2026-11-03T05:00:56+07:00' | '2026-11-03'
        '2026-11-03'                | '2026-11-03'
        null                        | ''
    }

    def "a read-only agent or blocked writes may not call a write service"() {
        expect:
        validate(WRITE_PROGRAM, 'readOnly', '').any { it.message.contains('read-only') }
        validate(WRITE_PROGRAM, 'scoped', '*#ProductCategory', 'block').any { it.message.contains('Writes are blocked') }
    }

    def "saving an agent in program mode needs a valid program"() {
        when: 'no program'
        ec.service.sync().name('AdkServices100.create#AdkAgentConfig').parameters([
                agentName: "Program empty ${run}", instruction: 'x', toolMode: 'scoped',
                serviceAllowlist: '*#ProductCategory', runMode: 'program']).call()

        then:
        ec.message.hasError()
        ec.message.errorsString.contains('generate one first')

        when: 'a program that breaks the rules'
        ec.message.clearAll()
        ec.service.sync().name('AdkServices100.create#AdkAgentConfig').parameters([
                agentName: "Program bad ${run}", instruction: 'x', toolMode: 'scoped',
                serviceAllowlist: '*#ProductCategory', runMode: 'program',
                programText: '<actions><script>1</script></actions>']).call()

        then:
        ec.message.hasError()
        ec.message.errorsString.contains('<script> is not allowed')
    }

    def "a program agent is saved and read back with its program"() {
        given: 'a category of this run in this company and one in another company'
        ec.service.sync().name("${CATALOG}.create#ProductCategory")
                .parameters([category: [categoryName: "Prog${run} Tools"]]).call()
        ec.user.internalLoginUser(otherTenant.username)
        ec.service.sync().name("${CATALOG}.create#ProductCategory")
                .parameters([category: [categoryName: "Prog${run} Other company"]]).call()
        ec.user.internalLoginUser(tenant.username)

        when:
        readAgent = createAgent([agentName: 'read', runMode: 'program', programText: READ_PROGRAM])
        List agents = ec.service.sync().name('AdkServices100.get#AdkAgentConfig')
                .parameters([search: "Program read ${run}"]).call().adkAgentConfigs

        then:
        readAgent.runMode == 'program'
        agents.size() == 1
        agents[0].runMode == 'program'
        agents[0].programText == READ_PROGRAM
    }

    def "a run reads as the company's agent user and is logged without tokens"() {
        when:
        Map out = runProgram(readAgent.adkAgentConfigId as String)

        then: "only this company's category: the run acts inside the agent's company"
        out.status == 'done'
        out.resultText == "Categories: Prog${run} Tools"
        out.toolCalls.size() == 1
        out.toolCalls[0].service == "${CATALOG}.get#ProductCategory"
        out.toolCalls[0].decision == 'ok'

        and: 'a run row with no tokens and the gate row of the read'
        List logs = ec.entity.find('moqui.adk.AdkActionLog').condition('configId', readAgent.adkAgentConfigId)
                .orderBy('-actionTime').list()
        logs.find { it.serviceName == 'agentProgram' }?.tokensTotal == 0
        logs.find { it.serviceName == 'agentProgram' }?.verbClass == 'program'
        logs.find { it.serviceName == "${CATALOG}.get#ProductCategory" }?.decision == 'allowed'
        logs.every { (it.tokensTotal ?: 0) == 0 }
    }

    def "an input parameter given for the run replaces the default"() {
        when:
        Map out = ec.service.sync().name('AdkProgramServices.run#AgentProgram')
                .parameters([adkAgentConfigId: readAgent.adkAgentConfigId, parameters: [prefix: 'Nothing like this']]).call()

        then:
        out.status == 'done'
        out.resultText == 'No categories.'
    }

    def "a test run simulates a write"() {
        given:
        writeAgent = createAgent([agentName: 'write', runMode: 'program', programText: WRITE_PROGRAM, writePolicy: 'allow',
                                  parameters: '[{"name":"prefix","value":"Made' + run + '"}]'])

        when:
        Map out = runProgram(writeAgent.adkAgentConfigId as String, true)

        then:
        out.status == 'done'
        out.resultText == 'simulated'
        out.toolCalls[0].decision == 'simulated'
        !categories(tenant, "Made${run} made by program")
    }

    def "a write runs when the write policy allows it"() {
        when:
        Map out = runProgram(writeAgent.adkAgentConfigId as String)

        then:
        out.status == 'done'
        out.resultText == "created Made${run} made by program"
        categories(tenant, "Made${run} made by program").size() == 1
        !categories(otherTenant, "Made${run} made by program")
    }

    def "a write waits for approval when the write policy says so"() {
        given:
        // an update sends the whole agent, like the agent dialog
        ec.service.sync().name('AdkServices100.update#AdkAgentConfig')
                .parameters(writeAgent + [writePolicy: 'approve', parameters: '[{"name":"prefix","value":"Held' + run + '"}]']).call()
        assert !ec.message.hasError(), ec.message.errorsString

        when:
        Map out = runProgram(writeAgent.adkAgentConfigId as String)

        then:
        out.status == 'done'
        out.resultText == 'waiting for approval'
        out.toolCalls[0].decision == 'approval'
        !categories(tenant, "Held${run} made by program")
        ec.entity.find('moqui.adk.AdkApproval').condition('configId', writeAgent.adkAgentConfigId)
                .condition('status', 'pending').count() == 1
    }

    def "a list with a default value iterates, and the first service call is not counted as program memory"() {
        given: 'the iterate template appends .iterator(): rows ?: [] must stay one expression'
        String program = '''<actions>
    <service-call name="growerp.100.CatalogServices100.get#ProductCategory" in-map="[limit: 100]" out-map="found"/>
    <set field="names" from="[]"/>
    <iterate list="found.categories ?: []" entry="c">
        <if condition="c.categoryName.startsWith(prefix)"><set field="names" from="names + [c.categoryName]"/></if>
    </iterate>
    <set field="report" from="names.sort().join(', ')"/>
</actions>'''
        Map agent = createAgent([agentName: 'iterate', runMode: 'program', programText: program])

        when:
        Map out = runProgram(agent.adkAgentConfigId as String)

        then:
        out.status == 'done'
        out.resultText == "Prog${run} Tools"
    }

    def "a program that grows a text in a loop is stopped"() {
        given:
        String program = '''<actions>
    <service-call name="growerp.100.CatalogServices100.get#ProductCategory" out-map="found"/>
    <set field="s" value="0123456789"/>
    <iterate list="'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'.split('')" entry="c">
        <set field="s" from="s + s"/>
    </iterate>
    <set field="report" from="s"/>
</actions>'''
        Map agent = createAgent([agentName: 'grow', runMode: 'program', programText: program])

        when:
        Map out = runProgram(agent.adkAgentConfigId as String)

        then:
        out.status == 'failed'
        out.error.contains('grew over')
    }

    def "the test run of a program agent makes no AI call"() {
        when:
        Map started = ec.service.sync().name('AdkServices100.start#AdkAgentTest')
                .parameters([adkAgentConfigId: readAgent.adkAgentConfigId]).call()
        Map testRun = ec.service.sync().name('AdkServices100.get#AdkAgentTest')
                .parameters([testRunId: started.testRunId]).call().testRun

        then:
        !ec.message.hasError()
        testRun.status == 'done'
        testRun.response == "Categories: Prog${run} Tools"
        testRun.llmCalls == 0
        testRun.tokensTotal == 0
    }

    def "a scheduled run posts the report to the agent's room"() {
        when:
        ec.service.sync().name('AdkSchedulerServices.run#ScheduledAgent')
                .parameters([adkAgentConfigId: readAgent.adkAgentConfigId]).call()
        String roomId = ec.entity.find('moqui.adk.AdkAgentConfig')
                .condition('adkAgentConfigId', readAgent.adkAgentConfigId).one().scheduleChatRoomId

        then:
        !ec.message.hasError()
        roomId
        ec.entity.find('growerp.general.ChatMessage').condition('chatRoomId', roomId).list()
                .any { it.content == "[Program read ${run}] Categories: Prog${run} Tools" }
    }

    def "a team file carries the program"() {
        when:
        ec.service.sync().name('AdkServices100.update#AdkAgentConfig')
                .parameters(readAgent + [teamName: "Program team ${run}"]).call()
        assert !ec.message.hasError(), ec.message.errorsString
        Map exported = ec.service.sync().name('AdkTeamTransferServices.export#AdkAgentTeam')
                .parameters([teamName: "Program team ${run}"]).call()
        Map data = new groovy.json.JsonSlurper().parseText(exported.jsonText as String) as Map
        ec.user.internalLoginUser(otherTenant.username)
        ec.service.sync().name('AdkTeamTransferServices.import#AdkAgentTeam')
                .parameters([jsonText: exported.jsonText]).call()
        Map imported = ec.entity.find('moqui.adk.AdkAgentConfig').condition('ownerPartyId', otherTenant.ownerPartyId)
                .condition('agentName', "Program read ${run}").one()

        then:
        !ec.message.hasError()
        data.agents[0].runMode == 'program'
        data.agents[0].programText == READ_PROGRAM
        imported.runMode == 'program'
        imported.programText == READ_PROGRAM

        when: 'a team file with a program that breaks the rules'
        data.agents[0].programText = '<actions><script>1</script></actions>'
        ec.service.sync().name('AdkTeamTransferServices.import#AdkAgentTeam')
                .parameters([jsonText: groovy.json.JsonOutput.toJson(data)]).call()

        then:
        ec.message.hasError()
        ec.message.errorsString.contains('<script> is not allowed')
    }

    def "generate gives the problems of a bad answer back and keeps the good one"() {
        when:
        Map gen = ec.service.sync().name('AdkProgramServices.generate#AgentProgram')
                .parameters([adkAgentConfigId: readAgent.adkAgentConfigId,
                             testAnswers: ['```xml\n<actions><script>1</script></actions>\n```', READ_PROGRAM]]).call()

        then:
        !ec.message.hasError()
        gen.attempts == 2
        gen.issues == []
        gen.programText == READ_PROGRAM
    }

    def "another company can not generate for or test this agent"() {
        when:
        ec.user.internalLoginUser(otherTenant.username)
        ec.service.sync().name('AdkServices100.generate#AdkAgentProgram')
                .parameters([adkAgentConfigId: readAgent.adkAgentConfigId]).call()

        then:
        ec.message.hasError()
        ec.message.errorsString.contains('not found for your company')
    }
}
