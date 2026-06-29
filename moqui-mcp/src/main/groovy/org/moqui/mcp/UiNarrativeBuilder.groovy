/*
 * This software is in public domain under CC0 1.0 Universal plus a 
 * Grant of Patent License.
 * 
 * To the extent possible under law, author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
package org.moqui.mcp

import org.moqui.impl.screen.ScreenDefinition
import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * Builds UI narrative for MCP screen responses.
 * Creates structured, story-like descriptions that guide LLM on how to invoke actions.
 */
class UiNarrativeBuilder {
    protected final static Logger logger = LoggerFactory.getLogger(UiNarrativeBuilder.class)
    
    private int countForms(Map semanticState) {
        if (!semanticState?.data) return 0
        int count = 0
        semanticState.data.keySet().each { k ->
            if (k.toString().toLowerCase().contains('form')) {
                count++
            }
        }
        return count
    }
    
    private int countLists(Map semanticState) {
        if (!semanticState?.data) return 0
        int count = 0
        semanticState.data.keySet().each { k ->
            if (k.toString().toLowerCase().contains('list')) {
                count++
            }
        }
        return count
    }

    Map<String, Object> buildNarrative(ScreenDefinition screenDef, Map<String, Object> semanticState, String currentPath) {
        def narrative = [:]
        
        narrative.screen = describeScreen(screenDef, semanticState)
        narrative.actions = describeActions(screenDef, semanticState, currentPath)
        narrative.navigation = describeLinks(semanticState, currentPath)
        narrative.notes = describeNotes(semanticState, currentPath)
        
        return narrative
    }

    String describeScreen(ScreenDefinition screenDef, Map<String, Object> semanticState) {
        def screenName = screenDef?.getScreenName() ?: "Screen"
        def sb = new StringBuilder()
        
        sb.append("${screenName} displays ")
        
        def formCount = countForms(semanticState)
        def listCount = countLists(semanticState)
        def itemCount = countItems(semanticState)
        
        if (listCount > 0 && itemCount > 0) {
            sb.append("${itemCount} item${itemCount > 1 ? 's' : ''} in ${listCount} list${listCount > 1 ? 's' : ''}")
            if (formCount > 0) sb.append(" with a search form")
        } else if (formCount > 0) {
            sb.append("a form with ${formCount} field${formCount > 1 ? 's' : ''}")
        } else {
            sb.append("information")
        }
        
        sb.append(". ")
        
        def forms = semanticState?.data
        if (forms) {
            def maxForms = 10
            def formNames = forms.keySet().findAll { k -> k.contains('Form') || k.contains('form') }
            if (formNames) {
                def formNamesToDescribe = formNames.take(maxForms + 1)
                def fields = getFormFieldNames(forms, formNamesToDescribe[0])
                if (fields) {
                    sb.append("Form contains: ${fields.join(', ')}. ")
                }
            }
        }
        
        def links = semanticState?.data?.links
        if (links && links.size() > 0) {
            def linkTypes = links.collect { l -> l.type?.toString() ?: 'navigation' }.unique()
            if (linkTypes) {
                def maxTypes = 15
                sb.append("Available links: ${linkTypes.take(maxTypes).join(', ')}. ")
            }
        }
        
        return sb.toString()
    }

    List<String> describeActions(ScreenDefinition screenDef, Map<String, Object> semanticState, String currentPath) {
        def actions = []

        def transitions = semanticState?.actions
        if (transitions) {
            transitions.each { trans ->
                def transName = trans.name?.toString()
                def service = trans.service?.toString()
                def actionType = classifyActionType(trans, semanticState)

                if (transName) {
                    if (actionType == 'service-action' && service) {
                        actions << buildServiceActionNarrative(transName, service, currentPath, semanticState)
                    } else if (actionType == 'form-action') {
                        actions << buildFormActionNarrative(transName, currentPath, semanticState)
                    } else if (actionType == 'screen-transition') {
                        actions << buildScreenTransitionNarrative(transName, currentPath, semanticState)
                    } else if (service) {
                        actions << buildServiceActionNarrative(transName, service, currentPath, semanticState)
                    }
                }
            }
        }

        def forms = semanticState?.data
        if (forms) {
            def formNames = forms.keySet().findAll { k -> k.contains('Form') || k.contains('form') }
            formNames.each { formName ->
                actions << buildFormSubmitNarrative(formName, currentPath, semanticState)
            }
        }

        if (actions.isEmpty()) {
            actions << "No explicit actions available on this screen. Use navigation links to explore."
        }

        return actions
    }

    private String classifyActionType(def trans, Map semanticState) {
        def transName = trans.name?.toString()?.toLowerCase() ?: ''
        def service = trans.service?.toString()

        // Delete actions are special
        if (transName.contains('delete')) return 'delete-action'

        // Service actions
        if (service) return 'service-action'

        // Form actions (built-in)
        if (transName.startsWith('form') || transName == 'find' || transName == 'search') {
            return 'form-action'
        }

        // Screen transitions
        return 'screen-transition'
    }

    List<String> describeLinks(Map<String, Object> semanticState, String currentPath) {
        def navigation = []
        
        def links = semanticState?.data?.links
        if (links && links.size() > 0) {
            def sortedLinks = links.sort { a, b -> (a.text <=> b.text) }
            
            def linksToTake = 50
            sortedLinks.take(linksToTake).each { link ->
                def linkText = link.text?.toString()
                def linkPath = link.path?.toString()
                def linkType = link.type?.toString() ?: 'navigation'
                
                if (linkPath) {
                    if (linkType == 'action' || linkPath.startsWith('#')) {
                        def actionName = linkPath.startsWith('#') ? linkPath.substring(1) : linkPath
                        navigation << "To ${linkText.toLowerCase()}, use action '${actionName}' (type: action)."
                    } else if (linkType == 'delete') {
                        navigation << "To ${linkText.toLowerCase() ?: 'delete'}, call moqui_render_screen(path='${linkPath}') (type: delete)."
                    } else if (linkType == 'external') {
                        navigation << "To ${linkText.toLowerCase() ?: 'external link'}, visit ${linkPath} (type: external)."
                    } else if (linkType == 'button') {
                        navigation << "To ${linkText.toLowerCase()}, click button action (type: button)."
                    } else {
                        navigation << "To ${linkText.toLowerCase()}, call moqui_render_screen(path='${linkPath}') (type: navigation)."
                    }
                }
            }
        }

        if (navigation.isEmpty()) {
            def parentPath = getParentPath(currentPath)
            if (parentPath) {
                navigation << "To go back, call moqui_browse_screens(path='${parentPath}')."
            }
        }

        return navigation
    }

    List<String> describeNotes(Map<String, Object> semanticState, String currentPath) {
        def notes = []
        
        def data = semanticState?.data
        if (data) {
            data.each { key, value ->
                if (value instanceof Map && value.containsKey('_truncated') && value._truncated == true) {
                    def total = value._totalCount ?: 0
                    def shown = value._items?.size() ?: 0
                    notes << "List truncated: showing ${shown} of ${total} item${total > 1 ? 's' : ''}. Use pagination for more."
                }
            }
        }
        
        def actions = semanticState?.actions
        if (actions && actions.size() > 5) {
            notes << "This screen has ${actions.size()} actions. Use semanticState.actions for complete list."
        }
        
        // Add note about moqui_get_screen_details for dropdown options
        def formData = semanticState?.data
        if (formData && formData.containsKey('formMetadata') && formData.formMetadata instanceof Map) {
            def formMetadata = formData.formMetadata
            def allFields = []
            formMetadata.each { formName, formInfo ->
                if (formInfo instanceof Map && formInfo.containsKey('fields')) {
                    def fields = formInfo.fields
                    if (fields instanceof Collection) {
                        def dynamicFields = fields.findAll { f -> f instanceof Map && f.containsKey('dynamicOptions') }
                        if (dynamicFields) {
                            def fieldNames = dynamicFields.collect { it.name }.take(3)
                            allFields.addAll(fieldNames)
                        }
                    }
                }
            }
            if (allFields) {
                def uniqueFields = allFields.unique().take(5)
                notes << "Fields with autocomplete: ${uniqueFields.join(', ')}. Use moqui_get_screen_details(path='${currentPath}', fieldName='${uniqueFields[0]}') to get field-specific options."
            }
        }
        
        def parameters = semanticState?.parameters
        if (parameters && parameters.size() > 0) {
            def requiredParams = parameters.findAll { k, v -> k.toString().toLowerCase().contains('id') }
            if (requiredParams.size() > 0) {
                notes << "Required parameters: ${requiredParams.keySet().join(', ')}."
            }
        }
        
        // Hint about global nav and search
        notes << "Global nav (Messages, Tasks, Calendar, Notifications) available in response.globalNav. Use moqui_search_screens(query='...') to find other screens."
        
        return notes
    }

    private String buildServiceActionNarrative(String actionName, String service, String currentPath, Map semanticState) {
        def actionLower = actionName.toLowerCase()
        def verb = actionLower.startsWith('create') ? 'create' : actionLower.startsWith('update') ? 'update' : actionLower.startsWith('delete') ? 'delete' : 'execute'
        
        def params = extractServiceParameters(service, semanticState)
        
        def sb = new StringBuilder()
        sb.append("To ${verb} ")
        
        def object = extractObjectFromAction(actionName)
        sb.append(object.toLowerCase())
        sb.append(", call moqui_render_screen(path='${currentPath}', action='${actionName}'")
        
        if (params) {
            sb.append(", parameters={${params}}")
        }
        
        sb.append("). ")
        sb.append("This invokes service '${service}' via transition.")
        
        return sb.toString()
    }

    private String buildTransitionActionNarrative(String actionName, String currentPath, Map semanticState) {
        def actionLower = actionName.toLowerCase()
        def verb = actionLower.startsWith('create') ? 'create' : actionLower.startsWith('update') ? 'update' : actionLower.startsWith('delete') ? 'delete' : 'process'
        
        def params = extractTransitionParameters(actionName, semanticState)
        
        def sb = new StringBuilder()
        sb.append("To ${verb} ")
        
        def object = extractObjectFromAction(actionName)
        sb.append(object.toLowerCase())
        sb.append(", call moqui_render_screen(path='${currentPath}', action='${actionName}'")
        
        if (params) {
            sb.append(", parameters={${params}}")
        }
        
        sb.append("). ")
        sb.append("This triggers the '${actionName}' transition on this screen.")
        
        return sb.toString()
    }

    private String buildFormSubmitNarrative(String formName, String currentPath, Map semanticState) {
        def formFriendly = formFriendlyName(formName)
        def params = extractFormParameters(formName, semanticState)

        def sb = new StringBuilder()
        sb.append("To submit ${formFriendly.toLowerCase()}, call moqui_render_screen(path='${currentPath}', parameters={${params}}). ")
        sb.append("This filters or processes ${formFriendly.toLowerCase()} form.")

        return sb.toString()
    }

    private String buildFormActionNarrative(String actionName, String currentPath, Map semanticState) {
        def actionLower = actionName.toLowerCase()
        def verb = actionLower.startsWith('find') ? 'find' : actionLower.startsWith('search') ? 'search' : 'filter'

        def params = extractTransitionParameters(actionName, semanticState)

        def sb = new StringBuilder()
        sb.append("To ${verb} ")
        sb.append("results, call moqui_render_screen(path='${currentPath}', action='${actionName}'")

        if (params) {
            sb.append(", parameters={${params}}")
        }

        sb.append("). ")
        sb.append("This is a built-in form action (type: form-action).")

        return sb.toString()
    }

    private String buildScreenTransitionNarrative(String actionName, String currentPath, Map semanticState) {
        def params = extractTransitionParameters(actionName, semanticState)

        def sb = new StringBuilder()
        sb.append("To execute '${actionName}', call moqui_render_screen(path='${currentPath}', action='${actionName}'")

        if (params) {
            sb.append(", parameters={${params}}")
        }

        sb.append("). ")
        sb.append("This triggers a screen transition (type: screen-transition).")

        return sb.toString()
    }

    
    private int countItems(Map semanticState) {
        if (!semanticState?.data) return 0
        def total = 0
        semanticState.data.each { k, v ->
            if (v instanceof Map && v.containsKey('_totalCount')) {
                total += v._totalCount as Integer
            } else if (v instanceof List) {
                total += v.size()
            }
        }
        return total
    }
    
    private List<String> getFormFieldNames(Map forms, String formName) {
        def form = forms[formName]
        if (!form) return []
        
        if (form instanceof Map) {
            def result = []
            form.keySet().each { k ->
                if (!k.toString().startsWith('_') && result.size() < 5) {
                    result.add(k.toString())
                }
            }
            return result
        }
        
        return []
    }
    
    private String extractServiceParameters(String service, Map semanticState) {
        def params = []
        def allParams = semanticState?.parameters
        
        if (allParams) {
            def paramKeys = []
            allParams.keySet().each { k ->
                if (paramKeys.size() < 3) {
                    paramKeys.add(k.toString())
                }
            }
            paramKeys.each { key ->
                def value = allParams[key]
                if (value != null) {
                    def valStr = value instanceof String ? "'${value}'" : value.toString()
                    params << "${key}: ${valStr}"
                }
            }
        }
        
        return params.join(', ')
    }

    private String extractTransitionParameters(String actionName, Map semanticState) {
        def params = []
        def allParams = semanticState?.parameters
        
        if (allParams) {
            def paramKeys = allParams.keySet().take(3)
            paramKeys.each { key ->
                def value = allParams[key]
                if (value != null) {
                    def valStr = value instanceof String ? "'${value}'" : value.toString()
                    params << "${key}: ${valStr}"
                }
            }
        }
        
        return params.join(', ')
    }

    private String extractFormParameters(String formName, Map semanticState) {
        def form = semanticState?.data?.get(formName)
        if (!form) return '...'
        
        def params = []
        if (form instanceof Map) {
            def fieldNames = []
            form.keySet().each { k ->
                if (!k.toString().startsWith('_') && fieldNames.size() < 3) {
                    fieldNames.add(k.toString())
                }
            }
            fieldNames.each { key ->
                def value = form[key]
                if (value != null) {
                    def valStr = value instanceof String ? "'${value}'" : value.toString()
                    params << "${key}: ${valStr}"
                }
            }
        }
        
        if (params.isEmpty()) params << '...'
        
        return params.join(', ')
    }

    private String extractObjectFromAction(String actionName) {
        def actionLower = actionName.toLowerCase()
        
        def patterns = [
            /create(.+)/,
            /update(.+)/,
            /delete(.+)/,
            /find(.+)/,
            /search(.+)/
        ]
        
        for (pattern in patterns) {
            def m = actionLower =~ pattern
            if (m.find()) {
                def object = m.group(1)
                if (object) {
                    def words = object.split('(?=[A-Z])')
                    def cleaned = words.findAll { w -> w.length() > 0 }.join(' ')
                    return cleaned ?: 'item'
                }
            }
        }
        
        return 'item'
    }

    private String formFriendlyName(String formName) {
        def name = formName.replace('Form', '').replace('form', '')
        def words = name.split('(?=[A-Z])')
        return words.findAll { w -> w.length() > 0 }.join(' ') ?: 'Form'
    }

    private String getParentPath(String path) {
        if (!path || path == 'root') return null
        
        def parts = path.split('\\.')
        if (parts.length > 1) {
            return parts[0..-2].join('.')
        }
        
        return 'root'
    }
}
