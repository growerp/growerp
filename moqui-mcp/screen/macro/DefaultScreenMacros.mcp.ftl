<#--
    Moqui MCP Optimized Macros
    Renders screens in Markdown format optimized for LLM consumption.
-->

<#include "DefaultScreenMacros.any.ftl"/>

<#macro @element></#macro>

<#macro screen>
    <#recurse>
</#macro>

<#macro widgets>
    <#recurse>
</#macro>

<#macro "fail-widgets"><#recurse></#macro>

 <#-- ================ Subscreens ================ -->
<#macro "subscreens-menu">
    <#if mcpSemanticData??>
        <#list sri.getActiveScreenDef().getMenuSubscreensItems() as subscreen>
            <#if subscreen.name?has_content>
                <#assign urlInstance = sri.buildUrl(subscreen.name)>
                <#if urlInstance.isPermitted()>
                    <#assign fullPath = urlInstance.sui.fullPathNameList![]>
                    <#assign slashPath = "">
                    <#list fullPath as pathPart><#assign slashPath = slashPath + (slashPath?has_content)?then("/", "") + pathPart></#list>

                    <#assign linkText = subscreen.menuTitle?has_content?then(subscreen.menuTitle, subscreen.name)>

                    <#assign linkType = "navigation">
                    <#assign dummy = ec.resource.expression("mcpSemanticData.links.add([text: '" + (linkText!"")?js_string + "', path: '" + (slashPath!"")?js_string + "', type: '" + linkType + "'])", "")!>
                </#if>
            </#if>
        </#list>
    </#if>
</#macro>
<#macro "subscreens-active">${sri.renderSubscreen()}</#macro>
<#macro "subscreens-panel">${sri.renderSubscreen()}</#macro>

<#-- ================ Section ================ -->
<#macro section>${sri.renderSection(.node["@name"])}</#macro>
<#macro "section-iterate">${sri.renderSection(.node["@name"])}</#macro>
<#macro "section-include">${sri.renderSectionInclude(.node)}</#macro>

<#-- ================ Containers ================ -->
<#macro container>
<#recurse>
</#macro>

<#macro "container-box">
<#if .node["box-header"]?has_content>### <#recurse .node["box-header"][0]></#if>
<#if .node["box-body"]?has_content><#recurse .node["box-body"][0]></#if>
<#if .node["box-body-nopad"]?has_content><#recurse .node["box-body-nopad"][0]></#if>
</#macro>

<#macro "container-row"><#list .node["row-col"] as rowColNode><#recurse rowColNode></#list></#macro>

<#macro "container-panel">
<#if .node["panel-header"]?has_content>### <#recurse .node["panel-header"][0]></#if>
<#if .node["panel-left"]?has_content><#recurse .node["panel-left"][0]></#if>
<#recurse .node["panel-center"][0]>
<#if .node["panel-right"]?has_content><#recurse .node["panel-right"][0]></#if>
<#if .node["panel-footer"]?has_content><#recurse .node["panel-footer"][0]></#if>
</#macro>

<#macro "container-dialog">
[Button: ${ec.resource.expand(.node["@button-text"], "")}]
<#recurse>
</#macro>

<#-- ================== Standalone Fields ==================== -->
<#macro link>
    <#assign linkNode = .node>
    <#if linkNode["@condition"]?has_content><#assign conditionResult = ec.getResource().condition(linkNode["@condition"], "")><#else><#assign conditionResult = true></#if>
    <#if conditionResult>
        <#assign urlInstance = sri.makeUrlByType(linkNode["@url"]!"", linkNode["@url-type"]!"transition", linkNode, "true")>
        <#assign linkText = "">
        <#if linkNode["@text"]?has_content>
            <#assign linkText = ec.getResource().expand(linkNode["@text"], "")>
        <#elseif linkNode["@entity-name"]?has_content>
            <#assign linkText = sri.getFieldEntityValue(linkNode)>
        </#if>
        <#if !linkText?has_content && .node?parent?node_name?ends_with("-field")>
             <#assign linkText = sri.getFieldValueString(.node?parent?parent)>
        </#if>

        <#-- Convert path to slash notation for moqui_render_screen (matches browser URLs) -->
        <#assign fullPath = urlInstance.sui.fullPathNameList![]>
        <#assign slashPath = "">
        <#list fullPath as pathPart><#assign slashPath = slashPath + (slashPath?has_content)?then("/", "") + pathPart></#list>
        
        <#assign paramStr = urlInstance.getParameterString()>
        <#if paramStr?has_content><#assign slashPath = slashPath + "?" + paramStr></#if>
        
        [${linkText}](${slashPath})<#t>
        <#if mcpSemanticData??>
            <#assign linkType = "navigation">
            <#if slashPath?starts_with("#")><#assign linkType = "action"></#if>
            <#if slashPath?starts_with("http://") || slashPath?starts_with("https://")><#assign linkType = "external"></#if>
            <#if .node["@icon"]?has_content && .node["@icon"]?contains("trash")><#assign linkType = "delete"></#if>
            <#assign dummy = ec.resource.expression("mcpSemanticData.links.add([text: '" + (linkText!"")?js_string + "', path: '" + (slashPath!"")?js_string + "', type: '" + linkType + "'])", "")!>
        </#if>
    </#if>
</#macro>

<#macro image>![${.node["@alt"]!""}](${(.node["@url"]!"")})</#macro>

<#macro label>
<#assign text = ec.resource.expand(.node["@text"], "")>
<#assign type = .node["@type"]!"span">
<#if type == "h1"># ${text}
<#elseif type == "h2">## ${text}
<#elseif type == "h3">### ${text}
<#elseif type == "p">${text}
<#else>${text}</#if>
</#macro>

<#-- ======================= Form ========================= -->
<#macro "form-single">
    <#assign formNode = sri.getFormNode(.node["@name"])>
     <#assign mapName = (formNode["@map"]!"fieldValues")>
    <#assign formMap = ec.resource.expression(mapName, "")!>
    
    <#if mcpSemanticData??>
        <#assign formName = (.node["@name"]!"")?string>
        <#assign fieldMetaList = []>
        <#assign dummy = ec.resource.expression("if (mcpSemanticData.formMetadata == null) mcpSemanticData.formMetadata = [:]; mcpSemanticData.formMetadata.put('" + formName?js_string + "', [name: '" + formName?js_string + "', map: '" + (mapName!"")?js_string + "'])", "")!>
        <#-- Store the actual form data (current entity values) in semanticData -->
        <#if formMap?has_content>
            <#assign dummy = ec.context.put("tempFormMapData", formMap)!>
            <#assign dummy = ec.resource.expression("mcpSemanticData.put('" + formName?js_string + "_data', tempFormMapData)", "")!>
        </#if>
    </#if>
    <#t>${sri.pushSingleFormMapContext(mapName)}
    <#list formNode["field"] as fieldNode>
        <#assign fieldSubNode = "">
        <#list fieldNode["conditional-field"] as csf><#if ec.resource.condition(csf["@condition"], "")><#assign fieldSubNode = csf><#break></#if></#list>
        <#if !fieldSubNode?has_content><#assign fieldSubNode = fieldNode["default-field"][0]!></#if>
        <#if fieldSubNode?has_content && !fieldSubNode["ignored"]?has_content && !fieldSubNode["hidden"]?has_content && !fieldSubNode["submit"]?has_content && fieldSubNode?parent["@hide"]! != "true">
            <#assign title><@fieldTitle fieldSubNode/></#assign>
            
            <#if mcpSemanticData??>
                <#assign fieldMeta = {"name": (fieldNode["@name"]!""), "title": (title!), "required": (fieldNode["@required"]! == "true")}>
                
                <#if fieldSubNode["text-line"]?has_content><#assign fieldMeta = fieldMeta + {"type": "text"}></#if>
                <#if fieldSubNode["text-area"]?has_content><#assign fieldMeta = fieldMeta + {"type": "textarea"}></#if>
                <#if fieldSubNode["drop-down"]?has_content>
                    <#-- Get the actual drop-down node (getFieldOptions expects the widget node, not its parent) -->
                    <#assign dropdownNodeList = fieldSubNode["drop-down"]>
                    <#assign dropdownNode = (dropdownNodeList?is_sequence)?then(dropdownNodeList[0], dropdownNodeList)>
                    
                    <#-- Evaluate any 'set' nodes from widget-template-include before getting options -->
                    <#-- These set variables like enumTypeId needed by entity-options -->
                    <#-- Note: set nodes are appended to fieldSubNode after template expansion -->
                    <#assign setNodes = fieldSubNode["set"]!>
                    <#list setNodes as setNode>
                        <#if setNode["@field"]?has_content>
                            <#assign dummy = sri.setInContext(setNode)>
                        </#if>
                    </#list>
                    <#-- Get dropdown options - pass the drop-down node, not fieldSubNode -->
                    <#assign dropdownOptions = sri.getFieldOptions(dropdownNode)!>
                    <#assign skipTruncation = (ec.context.mcpFullOptions!false) == true>
                    <#if (dropdownOptions?size!0) gt 0>
                        <#-- Build options list from the LinkedHashMap -->
                        <#-- Truncate if > 10 unless mcpFullOptions is set (for get_screen_details) -->
                        <#assign optionsList = []>
                        <#assign totalOptions = dropdownOptions?size>
                        <#assign optionLimit = skipTruncation?then(999999, 10)>
                        <#assign optionCount = 0>
                        <#-- Use entrySet() to iterate Java LinkedHashMap - avoids FreeMarker exposing method names as keys -->
                        <#list dropdownOptions.entrySet() as entry>
                            <#if optionCount lt optionLimit>
                                <#assign optionsList = optionsList + [{"value": entry.getKey(), "label": entry.getValue()}]>
                            </#if>
                            <#assign optionCount = optionCount + 1>
                        </#list>
                        <#if (totalOptions gt 10) && !skipTruncation>
                            <#assign fieldMeta = fieldMeta + {"type": "dropdown", "options": optionsList, "optionsTruncated": true, "totalOptions": totalOptions, "fetchHint": "Use moqui_get_screen_details(fieldName='" + (fieldNode["@name"]!"") + "') for all " + totalOptions + " options"}>
                        <#else>
                            <#assign fieldMeta = fieldMeta + {"type": "dropdown", "options": optionsList}>
                        </#if>
                    <#else>
                        <#-- No static options - check for dynamic-options -->
                        <#assign dynamicOptionsList = dropdownNode["dynamic-options"]!>
                        
                        <#if dynamicOptionsList?has_content && dynamicOptionsList?size gt 0>
                             <#assign dynamicOptionNode = dynamicOptionsList[0]>
                             
                            <#-- Try to extract transition metadata for better autocomplete support -->
                            <#assign transitionMetadata = {}>
                            <#if dynamicOptionNode["@transition"]?has_content>
                                <#assign activeScreenDef = sri.getActiveScreenDef()!>
                                <#if activeScreenDef?has_content>
                                    <#assign transitionItem = activeScreenDef.getTransitionItem(dynamicOptionNode["@transition"]!"", null)!>
                                    <#if transitionItem?has_content>
                                        <#assign serviceName = transitionItem.getSingleServiceName()!"">
                                        <#if serviceName?has_content && serviceName != "">
                                            <#assign transitionMetadata = transitionMetadata + {"serviceName": serviceName}>
                                        </#if>
                                    </#if>
                                </#if>
                            </#if>
                            
                            <#-- Capture depends-on with parameter attribute -->
                            <#assign dependsOnList = []>
                            <#list dynamicOptionNode["depends-on"]! as depNode>
                                <#assign depField = depNode["@field"]!"">
                                <#assign depParameter = depNode["@parameter"]!depField>
                                <#assign dependsOnItem = depField + "|" + depParameter>
                                <#assign dependsOnList = dependsOnList + [dependsOnItem]>
                            </#list>
                            <#assign dependsOnJson = '[]'>
                            <#if dependsOnList?size gt 0>
                                <#assign dependsOnJson = '['>
                                <#list dependsOnList as dep>
                                    <#if dep_index gt 0><#assign dependsOnJson = dependsOnJson + ', '></#if>
                                    <#assign dependsOnJson = dependsOnJson + '"' + dep + '"'>
                                </#list>
                                <#assign dependsOnJson = dependsOnJson + ']'>
                            </#if>
                            
                            <#-- Build dynamicOptions metadata -->
                            <#assign fieldMeta = fieldMeta + {"type": "dropdown", "dynamicOptions": {
                                "transition": (dynamicOptionNode["@transition"]!""),
                                "serverSearch": (dynamicOptionNode["@server-search"]! == "true"),
                                "minLength": (dynamicOptionNode["@min-length"]!"0"),
                                "parameterMap": ((dynamicOptionNode["@parameter-map"]!"")?js_string)!"",
                                "dependsOn": dependsOnJson
                            } + transitionMetadata}>
                        <#else>
                            <#assign fieldMeta = fieldMeta + {"type": "dropdown"}>
                        </#if>
                    </#if>
                </#if>
                 <#if fieldSubNode["check"]?has_content><#assign fieldMeta = fieldMeta + {"type": "checkbox"}></#if>
                <#if fieldSubNode["radio"]?has_content><#assign fieldMeta = fieldMeta + {"type": "radio"}></#if>
                <#if fieldSubNode["date-find"]?has_content><#assign fieldMeta = fieldMeta + {"type": "date"}></#if>
                <#if fieldSubNode["display"]?has_content || fieldSubNode["display-entity"]?has_content><#assign fieldMeta = fieldMeta + {"type": "display"}></#if>
                <#if fieldSubNode["link"]?has_content><#assign fieldMeta = fieldMeta + {"type": "link"}></#if>
                <#if fieldSubNode["file"]?has_content><#assign fieldMeta = fieldMeta + {"type": "file-upload"}></#if>
                <#if fieldSubNode["hidden"]?has_content><#assign fieldMeta = fieldMeta + {"type": "hidden"}></#if>
                
                <#assign fieldMetaList = fieldMetaList + [fieldMeta]>
            </#if>
            
            * **${title}**: <#recurse fieldSubNode>
        </#if>
    </#list>
    
    <#if mcpSemanticData?? && fieldMetaList?has_content>
        <#assign formName = (.node["@name"]!"")?string>
        <#assign dummy = ec.context.put("tempFieldMetaList", fieldMetaList)!>
        <#assign dummy = ec.resource.expression("def formMeta = mcpSemanticData.formMetadata?.get('" + formName?js_string + "'); if (formMeta != null) formMeta.put('fields', tempFieldMetaList)", "")!>
    </#if>
    
    <#t>${sri.popContext()}
</#macro>

<#macro "form-list">
    <#assign formInstance = sri.getFormInstance(.node["@name"])>
    <#assign formListInfo = formInstance.makeFormListRenderInfo()>
    <#assign formNode = formListInfo.getFormNode()>
    <#assign formListColumnList = formListInfo.getAllColInfo()>
    <#assign listObject = formListInfo.getListObject(false)!>
    <#assign totalItems = (listObject?size)!0>
    <#-- Get pagination variables from context (set by Moqui's XmlActions) -->
    <#assign listName = formNode["@list"]!"">
    <#assign pageIndex = (ec.context[listName + "PageIndex"])!0>
    <#assign pageSize = (ec.context[listName + "PageSize"])!20>
    <#assign listCount = (ec.context[listName + "Count"])!totalItems>
    <#assign pageMaxIndex = (ec.context[listName + "PageMaxIndex"])!0>
    
    <#if mcpSemanticData??>
        <#assign formName = (.node["@name"]!"")?string>
        <#assign displayedItems = (totalItems > 50)?then(50, totalItems)>
        <#assign isTruncated = (totalItems > 50)>
        <#assign hasMorePages = (pageIndex < pageMaxIndex)>
        <#assign columnNames = []>
        <#list formListColumnList as columnFieldList>
            <#assign fieldNode = columnFieldList[0]>
            <#assign columnNames = columnNames + [fieldNode["@name"]!""]>
        </#list>
        
        <#-- Extract Field Metadata for form-list - distinguish header (search) from display fields -->
        <#assign fieldMetaList = []>
        <#list formListColumnList as columnFieldList>
            <#assign fieldNode = columnFieldList[0]>
            <#-- Check if this field has a header-field with search widgets -->
            <#assign headerFieldNode = fieldNode["header-field"][0]!>
            <#assign hasSearchWidget = false>
            <#if headerFieldNode?has_content>
                <#-- Check for search-capable widgets in header-field -->
                <#if headerFieldNode["text-find"]?has_content || headerFieldNode["text-line"]?has_content || 
                     headerFieldNode["drop-down"]?has_content || headerFieldNode["date-find"]?has_content ||
                     headerFieldNode["date-period"]?has_content || headerFieldNode["range-find"]?has_content>
                    <#assign hasSearchWidget = true>
                </#if>
            </#if>
            <#assign fieldSubNode = headerFieldNode!fieldNode["default-field"][0]!fieldNode["conditional-field"][0]!>
            
            <#if fieldSubNode?has_content && !fieldSubNode["ignored"]?has_content && !fieldSubNode["hidden"]?has_content>
                <#assign title><@fieldTitle fieldSubNode/></#assign>
                <#assign fieldMeta = {"name": (fieldNode["@name"]!""), "title": (title!), "required": (fieldNode["@required"]! == "true"), "searchable": hasSearchWidget}>
                
                <#if fieldSubNode["text-line"]?has_content><#assign fieldMeta = fieldMeta + {"type": "text"}></#if>
                <#if fieldSubNode["text-find"]?has_content><#assign fieldMeta = fieldMeta + {"type": "text-search"}></#if>
                <#if fieldSubNode["text-area"]?has_content><#assign fieldMeta = fieldMeta + {"type": "textarea"}></#if>
                <#if fieldSubNode["date-find"]?has_content><#assign fieldMeta = fieldMeta + {"type": "date-search"}></#if>
                <#if fieldSubNode["date-period"]?has_content><#assign fieldMeta = fieldMeta + {"type": "date-period"}></#if>
                <#if fieldSubNode["range-find"]?has_content><#assign fieldMeta = fieldMeta + {"type": "range-search"}></#if>
                <#if fieldSubNode["drop-down"]?has_content>
                    <#-- Evaluate any 'set' nodes from widget-template-include before getting options -->
                    <#list fieldSubNode["set"]! as setNode>
                        <#if setNode["@field"]?has_content>
                            <#assign dummy = sri.setInContext(setNode)>
                        </#if>
                    </#list>
                    <#assign dropdownOptions = sri.getFieldOptions(fieldSubNode)!>
                    <#if dropdownOptions?has_content && dropdownOptions?size gt 0>
                        <#-- Convert LinkedHashMap<String,String> to list of {value, label} objects -->
                        <#-- Truncate if > 10 unless mcpFullOptions is set (for get_screen_details) -->
                        <#assign optionsList = []>
                        <#assign totalOptions = dropdownOptions?size>
                        <#assign skipTruncation = (ec.context.mcpFullOptions!false) == true>
                        <#assign optionLimit = skipTruncation?then(999999, 10)>
                        <#assign optionCount = 0>
                        <#list dropdownOptions?keys as optKey>
                            <#if optionCount lt optionLimit>
                                <#assign optionsList = optionsList + [{"value": optKey, "label": dropdownOptions[optKey]!optKey}]>
                            </#if>
                            <#assign optionCount = optionCount + 1>
                        </#list>
                        <#if (totalOptions gt 10) && !skipTruncation>
                            <#assign fieldMeta = fieldMeta + {"type": "dropdown", "options": optionsList, "optionsTruncated": true, "totalOptions": totalOptions, "fetchHint": "Use moqui_get_screen_details(fieldName='" + (fieldNode["@name"]!"") + "') for all " + totalOptions + " options"}>
                        <#else>
                            <#assign fieldMeta = fieldMeta + {"type": "dropdown", "options": optionsList}>
                        </#if>
                    <#else>
                        <#assign dropdownNode = fieldSubNode["drop-down"]!>
                        
                        <#-- Robust dynamic-options extraction -->
                        <#assign actualDropdown = (dropdownNode?is_sequence)?then(dropdownNode[0]!dropdownNode, dropdownNode)>
                        <#assign dynamicOptionsList = actualDropdown["dynamic-options"]!>
                        
                        <#if dynamicOptionsList?has_content && dynamicOptionsList?size gt 0>
                             <#assign dynamicOptionNode = dynamicOptionsList[0]>
                             
                            <#-- Try to extract transition metadata for better autocomplete support -->
                            <#assign transitionMetadata = {}>
                            <#if dynamicOptionNode["@transition"]?has_content>
                                <#assign activeScreenDef = sri.getActiveScreenDef()!>
                                <#if activeScreenDef?has_content>
                                    <#assign transitionItem = activeScreenDef.getTransitionItem(dynamicOptionNode["@transition"]!"", null)!>
                                    <#if transitionItem?has_content>
                                        <#assign serviceName = transitionItem.getSingleServiceName()!"">
                                        <#if serviceName?has_content && serviceName != "">
                                            <#assign transitionMetadata = transitionMetadata + {"serviceName": serviceName}>
                                        </#if>
                                    </#if>
                                </#if>
                            </#if>
                            <#assign dependsOnList = []>
                            <#list dynamicOptionNode["depends-on"]! as depNode>
                                <#assign depField = depNode["@field"]!"">
                                <#assign depParameter = depNode["@parameter"]!depField>
                                <#assign dependsOnItem = depField + "|" + depParameter>
                                <#assign dependsOnList = dependsOnList + [dependsOnItem]>
                            </#list>
                            <#assign dependsOnJson = '[]'>
                            <#if dependsOnList?size gt 0>
                                <#assign dependsOnJson = '['>
                                <#list dependsOnList as dep><#if dep_index gt 0><#assign dependsOnJson = dependsOnJson + ', '></#if><#assign dependsOnJson = dependsOnJson + '"' + dep + '"'></#list>
                                <#assign dependsOnJson = dependsOnJson + ']'>
                            </#if>
                            <#assign fieldMeta = fieldMeta + {"type": "dropdown", "dynamicOptions": {
                                "transition": (dynamicOptionNode["@transition"]!""),
                                "serverSearch": (dynamicOptionNode["@server-search"]! == "true"),
                                "minLength": (dynamicOptionNode["@min-length"]!"0"),
                                "parameterMap": ((dynamicOptionNode["@parameter-map"]!"")?js_string)!"",
                                "dependsOn": dependsOnJson
                            } + transitionMetadata}>
                        <#else>
                            <#assign fieldMeta = fieldMeta + {"type": "dropdown"}>
                        </#if>
                    </#if>
                </#if>
                <#if fieldSubNode["check"]?has_content><#assign fieldMeta = fieldMeta + {"type": "checkbox"}></#if>
                <#if fieldSubNode["radio"]?has_content><#assign fieldMeta = fieldMeta + {"type": "radio"}></#if>
                <#if fieldSubNode["date-find"]?has_content><#assign fieldMeta = fieldMeta + {"type": "date"}></#if>
                <#if fieldSubNode["display"]?has_content || fieldSubNode["display-entity"]?has_content><#assign fieldMeta = fieldMeta + {"type": "display"}></#if>
                <#if fieldSubNode["link"]?has_content><#assign fieldMeta = fieldMeta + {"type": "link"}></#if>
                <#if fieldSubNode["file"]?has_content><#assign fieldMeta = fieldMeta + {"type": "file-upload"}></#if>
                <#if fieldSubNode["hidden"]?has_content><#assign fieldMeta = fieldMeta + {"type": "hidden"}></#if>
                
                <#assign fieldMetaList = fieldMetaList + [fieldMeta]>
            </#if>
        </#list>

        <#assign dummy = ec.context.put("tempListObject", listObject)!>
        <#assign dummy = ec.context.put("tempColumnNames", columnNames)!>
        <#assign dummy = ec.context.put("tempFieldMetaList", fieldMetaList)!>
        <#assign dummy = ec.resource.expression("mcpSemanticData.put('" + formName?js_string + "', tempListObject); if (mcpSemanticData.formMetadata == null) mcpSemanticData.formMetadata = [:]; mcpSemanticData.formMetadata.put('" + formName?js_string + "', [name: '" + formName?js_string + "', type: 'form-list', map: '', fields: tempFieldMetaList, pageIndex: " + pageIndex + ", pageSize: " + pageSize + ", pageMaxIndex: " + pageMaxIndex + ", listCount: " + listCount + "]); if (mcpSemanticData.listMetadata == null) mcpSemanticData.listMetadata = [:]; mcpSemanticData.listMetadata.put('" + formName?js_string + "', [name: '" + formName?js_string + "', totalItems: " + totalItems + ", displayedItems: " + displayedItems + ", truncated: " + isTruncated?string + ", columns: tempColumnNames])", "")!>
    </#if>
    
    <#-- Header Row -->
    <#list formListColumnList as columnFieldList>
        <#assign fieldNode = columnFieldList[0]>
        <#assign fieldSubNode = fieldNode["header-field"][0]!fieldNode["default-field"][0]!fieldNode["conditional-field"][0]!>
        <#t>| <@fieldTitle fieldSubNode/><#t>
    </#list>
    |
    <#list formListColumnList as columnFieldList>| --- </#list>|
    <#-- Data Rows -->
    <#list listObject as listEntry>
        <#if (listEntry_index >= 50)><#break></#if>
        <#t>${sri.startFormListRow(formListInfo, listEntry, listEntry_index, listEntry_has_next)}
        <#list formListColumnList as columnFieldList>
            <#t>| <#list columnFieldList as fieldNode><@formListSubField fieldNode/><#if fieldNode_has_next> </#if></#list><#t>
        </#list>
        |
        <#t>${sri.endFormListRow()}
    </#list>
    <#t>${sri.safeCloseList(listObject)}
</#macro>

<#macro formListSubField fieldNode>
    <#list fieldNode["conditional-field"] as fieldSubNode>
        <#if ec.resource.condition(fieldSubNode["@condition"], "")>
            <#t><@formListWidget fieldSubNode/>
            <#return>
        </#if>
    </#list>
    <#if fieldNode["default-field"]?has_content>
        <#t><@formListWidget fieldNode["default-field"][0]/>
    </#if>
</#macro>

<#macro formListWidget fieldSubNode>
    <#if fieldSubNode["ignored"]?has_content || fieldSubNode["hidden"]?has_content || fieldSubNode?parent["@hide"]! == "true"><#return></#if>
    <#if fieldSubNode["submit"]?has_content>
        <#assign submitText = fieldSubNode["@title"]!fieldSubNode?parent["@title"]!fieldSubNode?parent["@name"]!>
        <#assign screenName = (sri.getActiveScreenDef().getName())!"">
        <#assign formName = (fieldSubNode?parent?parent["@name"])!"">
        <#assign fieldName = (fieldSubNode?parent["@name"])!"">
        [${submitText}](#${screenName}.${formName}.${fieldName})
    <#else>
        <#recurse fieldSubNode>
    </#if>
</#macro>

<#macro fieldTitle fieldSubNode>
    <#assign titleValue><#if fieldSubNode["@title"]?has_content>${fieldSubNode["@title"]}<#else><#list fieldSubNode?parent["@name"]?split("(?=[A-Z])", "r") as nameWord>${nameWord?cap_first?replace("Id", "ID")}<#if nameWord_has_next> </#if></#list></#if></#assign>
    <#t>${ec.l10n.localize(titleValue)}
</#macro>

<#-- ================== Form Field Widgets ==================== -->
<#macro "check">
    <#assign options = sri.getFieldOptions(.node)!>
    <#assign currentValue = sri.getFieldValueString(.node)!>
    <#t>${(options[currentValue])!currentValue}
</#macro>

<#macro "date-find"></#macro>
<#macro "date-time">
    <#assign javaFormat = .node["@format"]!>
    <#if !javaFormat?has_content>
        <#if .node["@type"]! == "time"><#assign javaFormat="HH:mm">
        <#elseif .node["@type"]! == "date"><#assign javaFormat="yyyy-MM-dd">
        <#else><#assign javaFormat="yyyy-MM-dd HH:mm"></#if>
    </#if>
    <#assign fieldValue = sri.getFieldValueString(.node?parent?parent, .node["@default-value"]!"", javaFormat)>
    <#t>${fieldValue}
</#macro>

<#macro "display">
    <#assign fieldValue = "">
    <#if .node["@text"]?has_content>
        <#assign textMap = {}>
        <#if .node["@text-map"]?has_content><#assign textMap = ec.getResource().expression(.node["@text-map"], {})!></#if>
        <#assign fieldValue = ec.getResource().expand(.node["@text"], "", textMap, false)>
        <#if .node["@currency-unit-field"]?has_content>
            <#assign fieldValue = ec.getL10n().formatCurrency(fieldValue, ec.getResource().expression(.node["@currency-unit-field"], ""))>
        </#if>
    <#else>
        <#assign fieldValue = (sri.getFieldValueString(.node))!"">
    </#if>
    <#t>${fieldValue}
</#macro>

<#macro "display-entity">
    <#t>${sri.getFieldEntityValue(.node)}
</#macro>

<#macro "drop-down">
    <#assign options = sri.getFieldOptions(.node)!>
    <#assign currentValue = sri.getFieldValueString(.node)!>
    <#t>${(options[currentValue])!currentValue}
</#macro>

<#macro "text-area"><#t>${(sri.getFieldValueString(.node))!""}</#macro>
<#macro "text-line"><#t>${(sri.getFieldValueString(.node))!""}</#macro>
<#macro "text-find"><#t>${(sri.getFieldValueString(.node))!""}</#macro>
<#macro "submit"></#macro>
<#macro "password"></#macro>
<#macro "hidden"></#macro>
