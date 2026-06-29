/*
 * This software is in the public domain under CC0 1.0 Universal plus a 
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

import groovy.transform.CompileStatic

/**
 * MCP-specific ScreenTest interface for simulating screen web requests
 * This is separate from the core Moqui ScreenTest system and tailored for MCP needs
 */
@CompileStatic
interface McpScreenTest {
    McpScreenTest rootScreen(String screenLocation)
    McpScreenTest baseScreenPath(String screenPath)
    McpScreenTest renderMode(String outputType)
    McpScreenTest encoding(String characterEncoding)
    McpScreenTest macroTemplate(String macroTemplateLocation)
    McpScreenTest baseLinkUrl(String baseLinkUrl)
    McpScreenTest servletContextPath(String scp)
    McpScreenTest skipJsonSerialize(boolean skip)
    McpScreenTest webappName(String wan)
    
    McpScreenTestRender render(String screenPath, Map<String, Object> parameters, String requestMethod)
    void renderAll(List<String> screenPathList, Map<String, Object> parameters, String requestMethod)
    
    List<String> getNoRequiredParameterPaths(Set<String> screensToSkip)
    
    long getRenderCount()
    long getErrorCount()
    long getRenderTotalChars()
    long getStartTime()
}