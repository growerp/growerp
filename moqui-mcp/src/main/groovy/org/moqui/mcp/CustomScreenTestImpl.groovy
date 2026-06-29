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
import org.moqui.impl.context.ExecutionContextFactoryImpl
import org.moqui.impl.context.ExecutionContextImpl
import org.moqui.context.WebFacade
import org.moqui.util.ContextStack
import org.moqui.impl.screen.ScreenUrlInfo
import org.moqui.impl.screen.ScreenFacadeImpl
import org.moqui.impl.screen.ScreenDefinition
import org.moqui.screen.ScreenRender
import org.moqui.BaseArtifactException
import org.moqui.util.MNode
import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * MCP-specific ScreenTest implementation for simulating screen web requests
 * This provides a proper web context for screen rendering in MCP environment
 * using the MCP component's WebFacadeStub instead of the framework's buggy one
 */
class CustomScreenTestImpl implements McpScreenTest {
    
    protected final static Logger logger = LoggerFactory.getLogger(CustomScreenTestImpl.class)
    
    protected final ExecutionContextFactoryImpl ecfi
    protected final ScreenFacadeImpl sfi
    // see FtlTemplateRenderer.MoquiTemplateExceptionHandler, others
    final List<String> errorStrings = ["[Template Error", "FTL stack trace", "Could not find subscreen or transition"]

    protected String rootScreenLocation = null
    protected ScreenDefinition rootScreenDef = null
    protected String baseScreenPath = null
    protected List<String> baseScreenPathList = null
    protected ScreenDefinition baseScreenDef = null

    protected String outputType = null
    protected String characterEncoding = null
    protected String macroTemplateLocation = null
    protected String baseLinkUrl = null
    protected String servletContextPath = null
    protected String webappName = null
    protected boolean skipJsonSerialize = false
    protected String authUsername = null
    protected static final String hostname = "localhost"

    long renderCount = 0, errorCount = 0, totalChars = 0, startTime = System.currentTimeMillis()

    final Map<String, Object> sessionAttributes = [:]

    CustomScreenTestImpl(ExecutionContextFactoryImpl ecfi) {
        this.ecfi = ecfi
        sfi = ecfi.screenFacade

        // init default webapp, root screen
        webappName('webroot')
    }
    
    /**
     * Create WebFacade using our properly implemented WebFacadeStub
     * instead of the framework's version that has null contextPath issues
     */
    protected WebFacade createWebFacade(ExecutionContextFactoryImpl ecfi, Map<String, Object> parameters, 
                                       Map<String, Object> sessionAttributes, String requestMethod, String screenPath) {
        if (logger.isDebugEnabled()) {
            logger.debug("CustomScreenTestImpl.createWebFacade() called with parameters: ${parameters?.keySet()}, sessionAttributes: ${sessionAttributes?.keySet()}, requestMethod: ${requestMethod}, screenPath: ${screenPath}")
        }
        
        // Use our MCP component's WebFacadeStub which properly handles null contextPath
        return new org.moqui.mcp.WebFacadeStub(ecfi, parameters, sessionAttributes, requestMethod, screenPath)
    }

    /**
     * Patch ScreenRender instance to handle null fieldNode in getFieldValueString.
     * This is a workaround for upstream Moqui bug where widget-template-include
     * creates widget nodes with incomplete parent chain.
     */
    protected static void patchScreenRenderForNullFieldNode(ScreenRender screenRender) {
        try {
            def sriImpl = screenRender
            def originalGetFieldValueString = sriImpl.&getFieldValueString

            sriImpl.metaClass.getFieldValueString = { MNode widgetNode ->
                if (widgetNode != null && widgetNode.parent != null && widgetNode.parent.parent != null) {
                    return originalGetFieldValueString(widgetNode)
                } else {
                    String defaultValue = widgetNode?.attribute("default-value") ?: ""
                    return delegate.ec.resourceFacade.expandNoL10n(defaultValue, null)
                }
            }

            def originalGetFieldValueClass = sriImpl.&getFieldValueClass
            sriImpl.metaClass.getFieldValueClass = { MNode fieldNodeWrapper ->
                if (fieldNodeWrapper == null) return "String"
                return originalGetFieldValueClass(fieldNodeWrapper)
            }

            def originalGetFieldEntityValue = sriImpl.&getFieldEntityValue
            sriImpl.metaClass.getFieldEntityValue = { MNode widgetNode ->
                if (widgetNode != null && widgetNode.parent != null && widgetNode.parent.parent != null) {
                    return originalGetFieldEntityValue(widgetNode)
                } else {
                    return delegate.getDefaultText(widgetNode)
                }
            }

            logger.debug("Patched ScreenRender with null fieldNode protection")
        } catch (Throwable t) {
            logger.warn("Failed to patch ScreenRender: ${t.getMessage()}", t)
        }
    }

    @Override
    McpScreenTest rootScreen(String screenLocation) {
        rootScreenLocation = screenLocation
        rootScreenDef = sfi.getScreenDefinition(rootScreenLocation)
        if (rootScreenDef == null) throw new IllegalArgumentException("Root screen not found: ${rootScreenLocation}")
        baseScreenDef = rootScreenDef
        return this
    }
    
    protected static List<String> pathToList(String path) {
        List<String> pathList = new ArrayList<>()
        if (path && path.contains('/')) {
            String[] pathSegments = path.split('/')
            for (String segment in pathSegments) {
                if (segment && segment.trim().length() > 0) {
                    pathList.add(segment)
                }
            }
        }
        return pathList
    }

    @Override
    McpScreenTest baseScreenPath(String screenPath) {
        if (!rootScreenLocation) throw new BaseArtifactException("No rootScreen specified")
        baseScreenPath = screenPath
        if (baseScreenPath.endsWith("/")) baseScreenPath = baseScreenPath.substring(0, baseScreenPath.length() - 1)
        if (baseScreenPath) {
            baseScreenPathList = ScreenUrlInfo.parseSubScreenPath(rootScreenDef, rootScreenDef, pathToList(baseScreenPath), baseScreenPath, [:], sfi)
            if (baseScreenPathList == null) throw new BaseArtifactException("Error in baseScreenPath, could find not base screen path ${baseScreenPath} under ${rootScreenDef.location}")
            for (String screenName in baseScreenPathList) {
                ScreenDefinition.SubscreensItem ssi = baseScreenDef.getSubscreensItem(screenName)
                if (ssi == null) throw new BaseArtifactException("Error in baseScreenPath, could not find ${screenName} under ${baseScreenDef.location}")
                baseScreenDef = sfi.getScreenDefinition(ssi.location)
                if (baseScreenDef == null) throw new BaseArtifactException("Error in baseScreenPath, could not find screen ${screenName} at ${ssi.location}")
            }
        }
        return this
    }
    
    @Override McpScreenTest renderMode(String outputType) { this.outputType = outputType; return this }
    @Override McpScreenTest encoding(String characterEncoding) { this.characterEncoding = characterEncoding; return this }
    @Override McpScreenTest macroTemplate(String macroTemplateLocation) { this.macroTemplateLocation = macroTemplateLocation; return this }
    @Override McpScreenTest baseLinkUrl(String baseLinkUrl) { this.baseLinkUrl = baseLinkUrl; return this }
    @Override McpScreenTest servletContextPath(String scp) { this.servletContextPath = scp; return this }
    @Override McpScreenTest skipJsonSerialize(boolean skip) { this.skipJsonSerialize = skip; return this }
    
    McpScreenTest auth(String username) { this.authUsername = username; return this }

    @Override
    McpScreenTest webappName(String wan) {
        webappName = wan

        // set a default root screen based on config for "localhost"
        MNode webappNode = ecfi.getWebappNode(webappName)
        for (MNode rootScreenNode in webappNode.children("root-screen")) {
            if (hostname.matches(rootScreenNode.attribute('host'))) {
                String rsLoc = rootScreenNode.attribute('location')
                rootScreen(rsLoc)
                break
            }
        }

        return this
    }

    @Override
    List<String> getNoRequiredParameterPaths(Set<String> screensToSkip) {
        if (!rootScreenLocation) throw new IllegalStateException("No rootScreen specified")

        List<String> noReqParmLocations = baseScreenDef.nestedNoReqParmLocations("", screensToSkip)
        // logger.info("======= rootScreenLocation=${rootScreenLocation}\nbaseScreenPath=${baseScreenPath}\nbaseScreenDef: ${baseScreenDef.location}\nnoReqParmLocations: ${noReqParmLocations}")
        return noReqParmLocations
    }

    @Override
    void renderAll(List<String> screenPathList, Map<String, Object> parameters, String requestMethod) {
        // NOTE: using single thread for now, doesn't actually make a lot of difference in overall test run time
        int threads = 1
        def output
        if (threads == 1) {
            for (String screenPath in screenPathList) {
                McpScreenTestRender str = render(screenPath, parameters, requestMethod)
                output = str.getOutput()
                logger.info("Rendered ${screenPath} in ${str.getRenderTime()}ms, ${output?.length()} characters")
            }
        } else {
            ExecutionContextImpl eci = ecfi.getEci()
            ArrayList<java.util.concurrent.Future> threadList = new ArrayList<java.util.concurrent.Future>(threads)
            int screenPathListSize = screenPathList.size()
            for (int si = 0; si < screenPathListSize; si++) {
                String screenPath = (String) screenPathList.get(si)
                threadList.add(eci.runAsync({
                    McpScreenTestRender str = render(screenPath, parameters, requestMethod)
                    logger.info("Rendered ${screenPath} in ${str.getRenderTime()}ms, ${str.getOutput()?.length()} characters")
                }))
                if (threadList.size() == threads || (si + 1) == screenPathList.size()) {
                    for (int i = 0; i < threadList.size(); i++) { ((java.util.concurrent.Future) threadList.get(i)).get() }
                    threadList.clear()
                }
            }
        }
    }

    long getRenderCount() { return renderCount }
    long getErrorCount() { return errorCount }
    long getRenderTotalChars() { return totalChars }
    long getStartTime() { return startTime }
    
    /**
     * Override render method to use our custom ScreenTestRenderImpl
     */
    @Override
    McpScreenTestRender render(String screenPath, Map<String, Object> parameters, String requestMethod) {
        if (!rootScreenLocation) throw new IllegalArgumentException("No rootScreenLocation specified")
        return new CustomScreenTestRenderImpl(this, screenPath, parameters, requestMethod).render()
    }
    
    /**
     * Custom ScreenTestRenderImpl that uses our WebFacadeStub
     */
    static class CustomScreenTestRenderImpl implements McpScreenTestRender {
        protected final CustomScreenTestImpl sti
        String screenPath = (String) null
        Map<String, Object> parameters = [:]
        String requestMethod = (String) null

        ScreenRender screenRender = (ScreenRender) null
        String outputString = (String) null
        Object jsonObj = null
        long renderTime = 0
        Map postRenderContext = (Map) null
        protected List<String> errorMessages = []

        CustomScreenTestRenderImpl(CustomScreenTestImpl sti, String screenPath, Map<String, Object> parameters, String requestMethod) {
            this.sti = sti
            this.screenPath = screenPath
            if (parameters != null) this.parameters.putAll(parameters)
            this.requestMethod = requestMethod
        }

        McpScreenTestRender render() {
            // render in separate thread with an independent ExecutionContext so it doesn't muck up the current one
            ExecutionContextFactoryImpl ecfi = sti.ecfi
            ExecutionContextImpl localEci = ecfi.getEci()
            String username = localEci.userFacade.getUsername()
            if (!username && sti.authUsername) username = sti.authUsername
            
            org.apache.shiro.subject.Subject loginSubject = localEci.userFacade.getCurrentSubject()
            boolean authzDisabled = localEci.artifactExecutionFacade.getAuthzDisabled()
            CustomScreenTestRenderImpl stri = this
            Throwable threadThrown = null

            Thread newThread = new Thread("CustomScreenTestRender") {
                @Override void run() {
                    try {
                        ExecutionContextImpl threadEci = ecfi.getEci()
                        if (loginSubject != null) {
                            logger.info("CustomScreenTestRender: Login subject for ${username}")
                            threadEci.userFacade.internalLoginSubject(loginSubject)
                        } else if (username != null && !username.isEmpty()) {
                            logger.info("CustomScreenTestRender: Login user ${username}")
                            threadEci.userFacade.internalLoginUser(username)
                        } else {
                            logger.warn("CustomScreenTestRender: No user to login!")
                        }
                        
                        if (threadEci.userFacade.userId) {
                            logger.info("CustomScreenTestRender: Logged in as ${threadEci.userFacade.username} (${threadEci.userFacade.userId})")
                        } else {
                            logger.warn("CustomScreenTestRender: Failed to login, userId is null")
                        }

                        if (authzDisabled) threadEci.artifactExecutionFacade.disableAuthz()
                        // as this is used for server-side transition calls don't do tarpit checks
                        threadEci.artifactExecutionFacade.disableTarpit()
                        renderInternalCustom(threadEci, stri)
                        threadEci.destroy()
                    } catch (Throwable t) {
                        threadThrown = t
                    }
                }
            }
            newThread.start()
            newThread.join()
            if (threadThrown != null) throw threadThrown
            return this
        }
        
        private static void renderInternalCustom(ExecutionContextImpl eci, CustomScreenTestRenderImpl stri) {
            CustomScreenTestImpl csti = stri.sti
            long startTime = System.currentTimeMillis()

            // parse the screenPath
            def screenPathList
            // Special handling for non-webroot root screens with subscreens
            if (csti.rootScreenLocation != null && !csti.rootScreenLocation.contains("webroot.xml") && stri.screenPath.contains('/')) {
                // For non-webroot roots with subscreens, build path list directly
                // rootScreenDef is the parent screen, screenPath is the subscreen path
                screenPathList = new ArrayList<>()
                // Add root screen path (already a full component:// path)
                //screenPathList.add(csti.rootScreenDef.location)
                // Add subscreen path segments
                String[] pathSegments = stri.screenPath.split('/')
                for (String segment in pathSegments) {
                    if (segment && segment.trim().length() > 0) {
                        screenPathList.add(segment)
                    }
                }
                logger.info("Custom screen path parsing for non-webroot root: ${screenPathList}")
              } else {
                  // For webroot or other cases, use ScreenUrlInfo.parseSubScreenPath for resolution
                  // Convert screenPath to list for parseSubScreenPath
                  List<String> inputPathList = new ArrayList<>()
                  if (stri.screenPath && stri.screenPath.contains('/')) {
                      String[] pathSegments = stri.screenPath.split('/')
                      for (String segment in pathSegments) {
                          if (segment && segment.trim().length() > 0) {
                              inputPathList.add(segment)
                          }
                      }
                  }

                  // Use Moqui's parseSubScreenPath to resolve actual screen path
                  // Note: pass null for fromPathList since stri.screenPath is already relative to root or from screen
                  screenPathList = ScreenUrlInfo.parseSubScreenPath(csti.rootScreenDef, csti.baseScreenDef,
                          null, stri.screenPath, stri.parameters, csti.sfi)
             }
            if (screenPathList == null) throw new BaseArtifactException("Could not find screen path ${stri.screenPath} under base screen ${csti.baseScreenDef.location}")

            // push the context
            ContextStack cs = eci.getContext()
            cs.push()
            
            // Create a persistent map for semantic data that survives nested pops
            Map<String, Object> mcpSemanticData = new HashMap<>()
            mcpSemanticData.put("links", new ArrayList<>())
            mcpSemanticData.put("formMetadata", new HashMap<>())
            mcpSemanticData.put("listMetadata", new HashMap<>())
            cs.put("mcpSemanticData", mcpSemanticData)
            
            // create the WebFacadeStub using our custom method
            org.moqui.mcp.WebFacadeStub wfs = (org.moqui.mcp.WebFacadeStub) csti.createWebFacade(csti.ecfi, stri.parameters, csti.sessionAttributes, stri.requestMethod, stri.screenPath)
            // set stub on eci, will also put parameters in the context
            eci.setWebFacade(wfs)
            
            // Put web facade objects in context for screen access
            cs.put("html_scripts", wfs.getHtmlScripts())
            cs.put("html_stylesheets", wfs.getHtmlStyleSheets())
            // make ScreenRender
            ScreenRender screenRender = csti.sfi.makeRender()
            // Patch ScreenRender to handle null fieldNode in getFieldValueString
            patchScreenRenderForNullFieldNode(screenRender)
            stri.screenRender = screenRender
            // pass through various settings
            if (csti.rootScreenLocation != null && csti.rootScreenLocation.length() > 0) screenRender.rootScreen(csti.rootScreenLocation)
            if (csti.outputType != null && csti.outputType.length() > 0) screenRender.renderMode(csti.outputType)
            if (csti.characterEncoding != null && csti.characterEncoding.length() > 0) screenRender.encoding(csti.characterEncoding)
            if (csti.macroTemplateLocation != null && csti.macroTemplateLocation.length() > 0) screenRender.macroTemplate(csti.macroTemplateLocation)
            if (csti.baseLinkUrl != null && csti.baseLinkUrl.length() > 0) screenRender.baseLinkUrl(csti.baseLinkUrl)
            if (csti.servletContextPath != null && csti.servletContextPath.length() > 0) screenRender.servletContextPath(csti.servletContextPath)
            screenRender.webappName(csti.webappName)
            if (csti.skipJsonSerialize) {
                // Set skipJsonSerialize on our WebFacadeStub
                wfs.skipJsonSerialize = true
            }

            // set the screenPath
            screenRender.screenPath(screenPathList as java.util.List<String>)

            // do the render
            try {
                logger.info("Starting render for ${screenPathList} with root ${csti.rootScreenLocation}")
                screenRender.render(wfs.getRequest(), wfs.getResponse())
                
                // IMMEDIATELY capture errors after render - before anything can clear them
                // This is critical for transition validation errors which get cleared during redirect handling
                if (eci.message.hasError()) {
                    List<String> immediateErrors = new ArrayList<>(eci.message.getErrors())
                    if (immediateErrors.size() > 0) {
                        stri.errorMessages.addAll(immediateErrors)
                        logger.warn("Captured ${immediateErrors.size()} errors immediately after render: ${immediateErrors}")
                    }
                }
                List<org.moqui.context.ValidationError> immediateValErrors = eci.message.getValidationErrors()
                if (immediateValErrors != null && immediateValErrors.size() > 0) {
                    for (org.moqui.context.ValidationError ve : immediateValErrors) {
                        String errMsg = ve.getMessage() ?: "${ve.getField()}: Validation error"
                        stri.errorMessages.add(errMsg)
                    }
                    logger.warn("Captured ${immediateValErrors.size()} validation errors immediately after render")
                }
                
                // get the response text from the WebFacadeStub
                stri.outputString = wfs.getResponseText()
                stri.jsonObj = wfs.getResponseJsonObj()
                logger.info("Render finished. Output length: ${stri.outputString?.length()}, JSON: ${stri.jsonObj != null}")
            } catch (Throwable t) {
                String errMsg = "Exception in render of ${stri.screenPath}: ${t.toString()}"
                logger.warn(errMsg, t)
                stri.errorMessages.add(errMsg)
                csti.errorCount++
                if (stri.outputString == null) stri.outputString = "RENDER_EXCEPTION: " + errMsg
            }
            // calc renderTime
            stri.renderTime = System.currentTimeMillis() - startTime

            // capture everything currently in the context stack before popping
            stri.postRenderContext = new HashMap<>(cs)
            // pop the context stack, get rid of var space
            cs.pop()

            // check, pass through, error messages from ExecutionContext
            if (eci.message.hasError()) {
                stri.errorMessages.addAll(eci.message.getErrors())
                eci.message.clearErrors()
                StringBuilder sb = new StringBuilder("Error messages from ${stri.screenPath}: ")
                for (String errorMessage in stri.errorMessages) sb.append("\n").append(errorMessage)
                logger.warn(sb.toString())
                csti.errorCount += stri.errorMessages.size()
            }
            
            // Also check errors saved to session by saveMessagesToSession() during transition redirects
            // This captures validation errors that occur during service calls but get cleared before we check
            if (wfs instanceof WebFacadeStub) {
                def savedErrors = wfs.getSavedErrors()
                if (savedErrors && savedErrors.size() > 0) {
                    stri.errorMessages.addAll(savedErrors)
                    StringBuilder sb = new StringBuilder("Saved error messages from ${stri.screenPath}: ")
                    for (String errorMessage in savedErrors) sb.append("\n").append(errorMessage)
                    logger.warn(sb.toString())
                    csti.errorCount += savedErrors.size()
                }
                def savedValidationErrors = wfs.getSavedValidationErrors()
                if (savedValidationErrors && savedValidationErrors.size() > 0) {
                    // Convert ValidationError objects to string messages
                    for (def ve in savedValidationErrors) {
                        def errMsg = ve.message ?: "${ve.field}: Validation error"
                        stri.errorMessages.add(errMsg)
                        csti.errorCount++
                    }
                    logger.warn("Saved validation errors from ${stri.screenPath}: ${savedValidationErrors.size()} errors")
                }
            }

            // check for error strings in output
            if (stri.outputString != null) for (String errorStr in csti.errorStrings) if (stri.outputString.contains(errorStr)) {
                String errMsg = "Found error [${errorStr}] in output from ${stri.screenPath}"
                stri.errorMessages.add(errMsg)
                csti.errorCount++
                logger.warn(errMsg)
            }

            // update stats
            csti.renderCount++
            if (stri.outputString != null) csti.totalChars += stri.outputString.length()
        }

        @Override ScreenRender getScreenRender() { return screenRender }
        @Override String getOutput() { return outputString }
        @Override Object getJsonObject() { return jsonObj }
        @Override long getRenderTime() { return renderTime }
        @Override Map getPostRenderContext() { return postRenderContext }
        @Override List<String> getErrorMessages() { return errorMessages }

        @Override
        boolean assertContains(String text) {
            if (!outputString) return false
            return outputString.contains(text)
        }
        @Override
        boolean assertNotContains(String text) {
            if (!outputString) return true
            return !outputString.contains(text)
        }
        @Override
        boolean assertRegex(String regex) {
            if (!outputString) return false
            return outputString.matches(regex)
        }
    }
}
