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

import com.sun.net.httpserver.HttpServer
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
   - userContent: a text prompt stays text; an image goes with it in the format of
     Gemini, Anthropic and OpenAI
   - postJson retries a read timeout and a 5xx answer, like a 429 (a website translation
     failed on a Gemini 'Read timed out', 2026-10-29)

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

    def "a text prompt stays plain text for every provider"() {
        expect:
        util.userContent('gemini', 'hello', [:]) == [[text: 'hello']]
        util.userContent('anthropic', 'hello', [:]) == 'hello'
        util.userContent('openai', 'hello', [:]) == 'hello'
    }

    def "an image goes with the prompt in the format of each provider"() {
        given:
        Map image = [imageData: 'QUJD', imageMimeType: 'image/png']

        expect:
        util.userContent('gemini', 'read it', image) ==
                [[text: 'read it'], [inline_data: [mime_type: 'image/png', data: 'QUJD']]]
        util.userContent('anthropic', 'read it', image) ==
                [[type: 'image', source: [type: 'base64', media_type: 'image/png', data: 'QUJD']],
                 [type: 'text', text: 'read it']]
        util.userContent('openai', 'read it', image) ==
                [[type: 'text', text: 'read it'],
                 [type: 'image_url', image_url: [url: 'data:image/png;base64,QUJD']]]
    }

    /** a local server that answers each request with the next of [answers]: a status code,
     *  or 'hang' to keep the connection open past the read timeout */
    private HttpServer fakeLlm(List answers) {
        HttpServer server = HttpServer.create(new InetSocketAddress('127.0.0.1', 0), 0)
        int calls = 0
        server.createContext('/') { exchange ->
            def answer = answers[Math.min(calls++, answers.size() - 1)]
            if (answer == 'hang') Thread.sleep(3000)
            byte[] body = (answer == 200 ? 'ok' : 'busy').bytes
            exchange.sendResponseHeaders(answer == 'hang' ? 200 : answer as int, body.length)
            exchange.responseBody.withStream { it.write(body) }
        }
        server.start()
        return server
    }

    def "a read timeout or a 5xx answer is retried"() {
        setup:
        HttpServer server = fakeLlm(answers)
        int readTimeout = util.readTimeoutMs
        int retryWait = util.retryWaitSeconds
        util.readTimeoutMs = 1000
        util.retryWaitSeconds = 0

        expect:
        util.postJson(ec, "http://127.0.0.1:${server.address.port}/", [:], '{}', 'Fake') == 'ok'

        cleanup:
        server.stop(0)
        util.readTimeoutMs = readTimeout
        util.retryWaitSeconds = retryWait

        where:
        answers << [['hang', 200], [503, 200], [500, 502, 200]]
    }
}
