package org.moqui.mcp

import org.moqui.context.ExecutionContext
import org.moqui.impl.context.ExecutionContextFactoryImpl
import groovy.json.JsonSlurper

/**
 * Service for getting screen field details including dropdown options via dynamic-options.
 * 
 * This implementation mirrors how the Moqui web UI handles autocomplete:
 * - Uses CustomScreenTestImpl with skipJsonSerialize(true) to call transitions
 * - Captures the raw JSON response via getJsonObject()
 * - Processes the response to extract options
 * 
 * See ScreenRenderImpl.getFieldOptions() in moqui-framework for the reference implementation.
 */
class McpFieldOptionsService {
    
    static service(String path, String fieldName, Map parameters, ExecutionContext ec) {
        if (!path) throw new IllegalArgumentException("path is required")

        def result = [screenPath: path, fields: [:]]
        try {
            // Pass mcpFullOptions through parameters to get full dropdown options without truncation
            def mergedParams = (parameters ?: [:]) + [mcpFullOptions: true]
            
            def browseResult = ec.service.sync().name("McpServices.execute#ScreenAsMcpTool")
                .parameters([path: path, parameters: mergedParams, renderMode: "mcp", sessionId: null])
                .call()

            if (!browseResult?.result?.content) {
                ec.logger.warn("GetScreenDetails: No content from ScreenAsMcpTool for path ${path}")
                return result + [error: "No content from ScreenAsMcpTool"]
            }
            def rawText = browseResult.result.content[0].text
            if (!rawText || !rawText.startsWith("{")) {
                ec.logger.warn("GetScreenDetails: Invalid JSON from ScreenAsMcpTool for path ${path}")
                return result + [error: "Invalid JSON from ScreenAsMcpTool"]
            }

            def resultObj = new JsonSlurper().parseText(rawText)
            def semanticState = resultObj?.semanticState
            def formMetadata = semanticState?.data?.formMetadata

            if (!(formMetadata instanceof Map)) {
                ec.logger.warn("GetScreenDetails: formMetadata is not a Map for path ${path}")
                return result + [error: "No form metadata found"]
            }

            def allFields = [:]
            
            formMetadata.each { formName, formItem ->
                if (!(formItem instanceof Map) || !formItem.fields) return
                formItem.fields.each { field ->
                    if (!(field instanceof Map) || !field.name) return
                    
                    def fieldInfo = [
                        name: field.name,
                        title: field.title,
                        type: field.type,
                        required: field.required ?: false
                    ]
                    if (field.type == "dropdown" && field.options) fieldInfo.options = field.options

                    def dynamicOptions = field.dynamicOptions
                    if (dynamicOptions instanceof Map) {
                        fieldInfo.dynamicOptions = dynamicOptions
                        try {
                            fetchOptions(fieldInfo, path, parameters, dynamicOptions, ec)
                        } catch (Exception e) {
                            ec.logger.warn("GetScreenDetails: Failed to fetch options for ${field.name}: ${e.message}")
                            fieldInfo.optionsError = e.message
                        }
                    }
                    
                    // Merge fields with same name - prefer version with options
                    // This handles cases where a field appears in both search and edit forms
                    def existingField = allFields[field.name]
                    if (existingField) {
                        // Keep existing options if new field has none
                        if (existingField.options && !fieldInfo.options) {
                            fieldInfo.options = existingField.options
                        }
                        // Merge dynamicOptions if existing has them
                        if (existingField.dynamicOptions && !fieldInfo.dynamicOptions) {
                            fieldInfo.dynamicOptions = existingField.dynamicOptions
                        }
                    }
                    allFields[field.name] = fieldInfo
                }
            }

            if (fieldName) {
                if (allFields[fieldName]) result.fields[fieldName] = allFields[fieldName]
                else result.error = "Field not found: ${fieldName}"
            } else {
                result.fields = allFields.collectEntries { k, v -> [k, v] }
            }
        } catch (Exception e) {
            ec.logger.error("MCP GetScreenDetails error: ${e.message}", e)
            result.error = e.message
        }
        return result
    }

    /**
     * Fetch options for a field with dynamic-options by calling the transition.
     * 
     * This uses CustomScreenTestImpl with skipJsonSerialize(true) to call the transition
     * and capture the raw JSON response - exactly how ScreenRenderImpl.getFieldOptions() works.
     */
    private static void fetchOptions(Map fieldInfo, String path, Map parameters, Map dynamicOptions, ExecutionContext ec) {
        def transitionName = dynamicOptions.transition
        if (!transitionName) return
        
        def optionParams = [:]
        
        // 1. Handle dependsOn (from form XML) - maps field values to service parameters
        if (dynamicOptions.dependsOn) {
            def depList = dynamicOptions.dependsOn instanceof String ? 
                new JsonSlurper().parseText(dynamicOptions.dependsOn) : dynamicOptions.dependsOn
            
            depList.each { dep ->
                def parts = dep.split('\\|')
                def fld = parts[0], prm = parts.size() > 1 ? parts[1] : fld
                def val = parameters?.get(fld)
                
                // Try common form map names if not found at top level
                if (val == null) {
                    ['fieldValues', 'fieldValuesMap', 'formValues', 'formValuesMap', 'formMap'].each { mapName ->
                        def mapVal = parameters?.get(mapName as String)
                        if (mapVal instanceof Map) {
                            val = mapVal.get(fld)
                            if (val != null) return
                        }
                    }
                }
                if (val != null) optionParams[prm] = val
            }
        }
 
        // 2. Handle serverSearch fields - skip if no search term provided (matches framework behavior)
        def isServerSearch = dynamicOptions.serverSearch == true || dynamicOptions.serverSearch == "true"
        if (isServerSearch) {
            if (parameters?.term != null && parameters.term.toString().length() > 0) {
                optionParams.term = parameters.term
            } else {
                return // Skip server-search fields without a term
            }
        }
 
        // 3. Use CustomScreenTestImpl with skipJsonSerialize to call the transition
        try {
            def ecfi = (ExecutionContextFactoryImpl) ec.factory
            
            // Build transition path by appending transition name to screen path
            def fullPath = path
            if (!fullPath.endsWith('/')) fullPath += '/'
            fullPath += transitionName
            
            // Parse path segments for component-based resolution
            def pathSegments = []
            fullPath.split('/').each { if (it && it.trim()) pathSegments.add(it) }
            
            // Component-based resolution (same as ScreenAsMcpTool)
            def rootScreen = "component://webroot/screen/webroot.xml"
            def testScreenPath = fullPath
            
            if (pathSegments.size() >= 2) {
                def componentName = pathSegments[0]
                def rootScreenName = pathSegments[1]
                def compRootLoc = "component://${componentName}/screen/${rootScreenName}.xml"
                
                if (ec.resource.getLocationReference(compRootLoc).exists) {
                    rootScreen = compRootLoc
                    testScreenPath = pathSegments.size() > 2 ? pathSegments[2..-1].join('/') : ""
                }
            }
            
            // Use CustomScreenTestImpl with skipJsonSerialize - like ScreenRenderImpl.getFieldOptions()
            def screenTest = new CustomScreenTestImpl(ecfi)
                .rootScreen(rootScreen)
                .skipJsonSerialize(true)
                .auth(ec.user.username)
            
            def str = screenTest.render(testScreenPath, optionParams, "GET")
            
            // Get JSON object directly (like web UI does)
            def jsonObj = str.getJsonObject()
            
            // Extract value-field and label-field from dynamic-options config
            def valueField = dynamicOptions.valueField ?: dynamicOptions.'value-field' ?: 'value'
            def labelField = dynamicOptions.labelField ?: dynamicOptions.'label-field' ?: 'label'
            
            // Process the JSON response - same logic as ScreenRenderImpl.getFieldOptions()
            List optsList = null
            if (jsonObj instanceof List) {
                optsList = (List) jsonObj
            } else if (jsonObj instanceof Map) {
                Map jsonMap = (Map) jsonObj
                // Try 'options' key first (standard pattern)
                def optionsObj = jsonMap.get("options")
                if (optionsObj instanceof List) {
                    optsList = (List) optionsObj
                } else if (jsonMap.get("resultList") instanceof List) {
                    // Some services return resultList
                    optsList = (List) jsonMap.get("resultList")
                }
            }
            
            if (optsList != null && optsList.size() > 0) {
                fieldInfo.options = optsList.collect { entryObj ->
                    if (entryObj instanceof Map) {
                        Map entryMap = (Map) entryObj
                        // Try configured fields first, then common fallbacks
                        def value = entryMap.get(valueField) ?: 
                                   entryMap.get('value') ?: 
                                   entryMap.get('geoId') ?: 
                                   entryMap.get('enumId') ?: 
                                   entryMap.get('id') ?: 
                                   entryMap.get('key')
                        def label = entryMap.get(labelField) ?: 
                                   entryMap.get('label') ?: 
                                   entryMap.get('description') ?: 
                                   entryMap.get('name') ?: 
                                   entryMap.get('text') ?:
                                   value?.toString()
                        [value: value, label: label]
                    } else {
                        [value: entryObj, label: entryObj?.toString()]
                    }
                }.findAll { it.value != null }
            }
            
        } catch (Exception e) {
            ec.logger.warn("GetScreenDetails: Error calling transition ${transitionName}: ${e.message}")
            fieldInfo.optionsError = "Transition call failed: ${e.message}"
        }
    }
}
