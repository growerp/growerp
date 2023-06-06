/*
 * This software is in the public domain under CC0 1.0 Universal plus a 
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
package org.moqui.fop

import groovy.transform.CompileStatic
import org.apache.batik.transcoder.TranscoderInput
import org.apache.batik.transcoder.TranscoderOutput
import org.apache.fop.svg.PDFTranscoder
import org.moqui.context.ArtifactAuthorizationException
import org.moqui.context.ArtifactTarpitException
import org.moqui.context.ExecutionContext
import org.moqui.impl.context.ExecutionContextFactoryImpl
import org.moqui.impl.webapp.ScreenResourceNotFoundException
import org.moqui.screen.ScreenRender
import org.moqui.util.StringUtilities
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import javax.servlet.ServletException
import javax.servlet.http.HttpServlet
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse

@CompileStatic
class HtmlRenderServlet extends HttpServlet {
    protected final static Logger logger = LoggerFactory.getLogger(HtmlRenderServlet.class)

    final static Map<String, String> outputToContentType = [ pdf:"application/pdf", svg:"image/svg+xml", png:"image/png" ]

    HtmlRenderServlet() {
        super()
    }

    @Override
    void doPost(HttpServletRequest request, HttpServletResponse response) { doScreenRequest(request, response) }

    @Override
    void doGet(HttpServletRequest request, HttpServletResponse response) { doScreenRequest(request, response) }

    void doScreenRequest(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        ExecutionContextFactoryImpl ecfi =
                (ExecutionContextFactoryImpl) getServletContext().getAttribute("executionContextFactory")
        String moquiWebappName = getServletContext().getInitParameter("moqui-name")

        if (ecfi == null || moquiWebappName == null) {
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "System is initializing, try again soon.")
            return
        }

        long startTime = System.currentTimeMillis()

        if (logger.traceEnabled) logger.trace("Start request to [${request.getPathInfo()}] at time [${startTime}] in session [${request.session.id}] thread [${Thread.currentThread().id}:${Thread.currentThread().name}]")

        ExecutionContext ec = ecfi.getExecutionContext()
        ec.initWebFacade(moquiWebappName, request, response)
        ec.web.requestAttributes.put("moquiRequestStartTime", startTime)
        String htmlUrl = ec.web.getWebappRootUrl(true, null) + ec.web.getPathInfo()

        String filename = ec.web.parameters.get("filename") as String

        String output = ec.web.parameters.get("output")
        if (!output || !outputToContentType.containsKey(output)) output = "pdf"
        String contentType = outputToContentType.get(output)

        String pageFormat = ec.web.parameters.pageFormat
        if (!pageFormat || !HtmlRenderer.pdRectangles.containsKey(pageFormat)) pageFormat = "LETTER"
        String scaleStr = ec.web.parameters.scale

        String mediaType = ec.web.parameters.mediaType

        // default hideNav to 'true'
        if (!ec.context.hideNav) ec.context.hideNav = "true"
        // include images? default false
        boolean includeImages = ec.web.parameters.includeImages == "true"
        // use FOP PDFTranscoder? default false
        boolean useFopPdfTranscoder = ec.web.parameters.fopPdf == "true"

        String htmlText = null
        try {
            ArrayList<String> pathInfoList = ec.web.getPathInfoList()
            ScreenRender sr = ec.screen.makeRender().webappName(moquiWebappName).renderMode("html")
                    .rootScreenFromHost(request.getServerName()).screenPath(pathInfoList)
            htmlText = sr.render()

            // logger.warn("======== HTML content from ${pathInfo}:\n${htmlText}")
            if (logger.traceEnabled) logger.trace("HTML content:\n${htmlText}")

            response.setContentType(contentType)
            if (output == "svg") response.setCharacterEncoding("UTF-8")
            if (filename) {
                String utfFilename = StringUtilities.encodeAsciiFilename(filename)
                response.setHeader("Content-Disposition", "attachment; filename=\"${filename}\"; filename*=utf-8''${utfFilename}")
            } else {
                response.setHeader("Content-Disposition", "inline")
            }

            HtmlRenderer htmlRenderer = new HtmlRenderer().setWindowSize(pageFormat)
            if (mediaType) htmlRenderer.setMediaType(mediaType)
            htmlRenderer.setLoadImages(includeImages, false)
            htmlRenderer.setSourceString(htmlText, new URL(htmlUrl))
            try {
                if (scaleStr) htmlRenderer.setRenderScale(scaleStr as float)
            } catch (Throwable t) {
                logger.warn("Error parsing scale ${scaleStr}: ${t.toString()}")
            }

            // special case disable authz for resource access
            boolean enableAuthz = !ecfi.getExecutionContext().getArtifactExecution().disableAuthz()
            try {
                if ("svg".equals(output)) {
                    htmlRenderer.renderSvg(response.getWriter())
                } else if ("png".equals(output)) {
                    htmlRenderer.renderImage(response.getOutputStream(), output)
                } else if (useFopPdfTranscoder) {
                    StringWriter svgWriter = new StringWriter()
                    htmlRenderer.renderSvg(svgWriter)

                    PDFTranscoder transcoder = new PDFTranscoder();
                    // NOTE: any way to get a StringReader without going through String?
                    // (copy StringWriter to String, make StringReader from String)
                    // StringWriter.getBuffer() gets a StringBuffer, but would still have to go to String for StringReader
                    String svgString = svgWriter.toString()
                    if (logger.traceEnabled) logger.trace("Produced SVG:\n${svgString}")
                    transcoder.transcode(new TranscoderInput(new StringReader(svgString)),
                            new TranscoderOutput(response.getOutputStream()));
                } else {
                    // images cause issues, seems broken in cssbox-pdf
                    htmlRenderer.renderPdf(response.getOutputStream())
                }
            } finally {
                if (enableAuthz) ecfi.getExecutionContext().getArtifactExecution().enableAuthz()
            }

            if (logger.infoEnabled) logger.info("Finished HTML Render request to ${pathInfoList}, content type ${response.getContentType()} in ${System.currentTimeMillis() - startTime}ms; session ${request.session.id} thread ${Thread.currentThread().id}:${Thread.currentThread().name}")
        } catch (ArtifactAuthorizationException e) {
            // SC_UNAUTHORIZED 401 used when authc/login fails, use SC_FORBIDDEN 403 for authz failures
            // See ScreenRenderImpl.checkWebappSettings for authc and SC_UNAUTHORIZED handling
            logger.warn((String) "Web Access Forbidden (no authz): " + e.message)
            response.sendError(HttpServletResponse.SC_FORBIDDEN, e.message)
        } catch (ArtifactTarpitException e) {
            logger.warn((String) "Web Too Many Requests (tarpit): " + e.message)
            if (e.getRetryAfterSeconds()) response.addIntHeader("Retry-After", e.getRetryAfterSeconds())
            // NOTE: there is no constant on HttpServletResponse for 429; see RFC 6585 for details
            response.sendError(429, e.message)
        } catch (ScreenResourceNotFoundException e) {
            logger.warn((String) "Web Resource Not Found: " + e.message)
            response.sendError(HttpServletResponse.SC_NOT_FOUND, e.message)
        } catch (Throwable t) {
            logger.error("Error transforming HTML content:\n${htmlText}", t)
            if (ec.message.hasError()) {
                String errorsString = ec.message.errorsString
                logger.error(errorsString, t)
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, errorsString)
            } else {
                throw t
            }
        } finally {
            // make sure everything is cleaned up
            ec.destroy()
        }
    }
}
