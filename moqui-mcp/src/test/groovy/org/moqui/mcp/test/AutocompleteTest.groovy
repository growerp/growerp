/*
 * This software is in the public domain under CC0 1.0 Universal plus a 
 * Grant of Patent License.
 */
package org.moqui.mcp.test

import org.moqui.Moqui
import org.moqui.context.ExecutionContext
import spock.lang.Shared
import spock.lang.Specification
import spock.lang.Stepwise

@Stepwise
class AutocompleteTest extends Specification {
    @Shared ExecutionContext ec
    @Shared SimpleMcpClient client

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        client = new SimpleMcpClient()
        client.initializeSession()
        
        // Log in to ensure permissions
        ec.user.internalLoginUser("john.doe") 
    }

    def cleanupSpec() {
        if (client) client.closeSession()
        if (ec) ec.destroy()
    }

    def "Test getCategoryList Autocomplete"() {
        when:
        println "🔍 Testing getCategoryList autocomplete on Search screen"
        
        // 1. Get screen details to find the field and transition
        def details = client.callTool("moqui_get_screen_details", [
            path: "component://SimpleScreens/screen/SimpleScreens/Catalog/Search.xml",
            fieldName: "productCategoryId"
        ])

        println "📋 Screen details result: ${details}"

        then:
        details != null
        !details.error
        !details.result?.error
        
        def content = details.result?.content
        content != null
        content.size() > 0
        
        // Parse the text content from the response
        def jsonText = content[0].text
        def jsonResult = new groovy.json.JsonSlurper().parseText(jsonText)
        
        def field = jsonResult.fields?.productCategoryId
        field != null
        field.dynamicOptions != null
        field.dynamicOptions.transition == "getCategoryList"
        field.dynamicOptions.serverSearch == true
        
        println "✅ Field metadata verified: ${field.dynamicOptions}"

        when:
        println "🔍 Testing explicit transition call via TransitionAsMcpTool"
        
        // 2. Call the transition directly to simulate typing
        def transitionResult = ec.service.sync().name("McpServices.execute#TransitionAsMcpTool")
            .parameters([
                path: "component://SimpleScreens/screen/SimpleScreens/Catalog/Search.xml",
                transitionName: "getCategoryList",
                parameters: [term: ""] 
            ])
            .call()

        println "🔄 Transition result: ${transitionResult}"

        then:
        transitionResult != null
        transitionResult.result != null
        !transitionResult.result.error
        transitionResult.result.data != null
        transitionResult.result.data instanceof List
        transitionResult.result.data.size() > 0
        
        println "✅ Found ${transitionResult.result.data.size()} categories via transition"
        println "📝 First category: ${transitionResult.result.data[0]}"
    }
}
