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

/* Tests for GeminiAiUtil.groovy knowledgeBlock / knowledgeFacts, the company knowledge
   base passages put into every prompt that writes about the company:
   - no passages give no block
   - passages give a COMPANY FACTS block with each title and text, and the rule not to invent
   - a company without a knowledge base (or embedding key) gets no block and no error,
     so generation never fails on it

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class GeminiAiUtilTests extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(GeminiAiUtilTests.class)
    @Shared ExecutionContext ec
    @Shared Map tenant
    @Shared def util

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        tenant = GrowerpTestSupport.tenant(ec, 'GeminiAiUtil')
        util = ec.resource.script('component://growerp/service/GeminiAiUtil.groovy', null)
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
        ec.message.clearAll()
        ec.user.internalLoginUser(tenant.username)
    }

    def "no passages give no knowledge block"() {
        expect:
        util.knowledgeBlock([]) == ''
        util.knowledgeBlock(null) == ''
    }

    def "passages give a COMPANY FACTS block with each title and text"() {
        when:
        String block = util.knowledgeBlock([
                [title: 'Pricing', text: 'Hosted plan costs 10 euro a month.'],
                [title: 'Verticals', text: 'Apps for hotel, rental and freelance.']])

        then:
        block.contains('COMPANY FACTS')
        block.contains('Pricing')
        block.contains('Hosted plan costs 10 euro a month.')
        block.contains('Verticals')
        block.contains('Apps for hotel, rental and freelance.')
        block.toLowerCase().contains('never invent')
    }

    def "a company without a knowledge base gets no block and no error"() {
        when:
        String block = util.knowledgeFacts(ec, tenant.ownerPartyId as String, 'what does the hosted plan cost')

        then:
        block == ''
        !ec.message.hasError()
    }
}
