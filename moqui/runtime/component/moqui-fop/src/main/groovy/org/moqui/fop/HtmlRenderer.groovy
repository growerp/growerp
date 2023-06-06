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

import cz.vutbr.web.css.MediaSpec
import groovy.transform.CompileStatic
import org.apache.pdfbox.pdmodel.common.PDRectangle
import org.fit.cssbox.css.CSSNorm
import org.fit.cssbox.css.DOMAnalyzer
import org.fit.cssbox.io.*
import org.fit.cssbox.layout.BrowserCanvas
import org.fit.cssbox.layout.BrowserConfig
import org.fit.cssbox.layout.Viewport
import org.fit.cssbox.render.PDFRenderer
import org.fit.cssbox.render.SVGRenderer
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.w3c.dom.Document
import org.xml.sax.SAXException

import javax.imageio.ImageIO
import java.awt.*
import java.nio.charset.StandardCharsets

@CompileStatic
class HtmlRenderer {
    protected final static Logger logger = LoggerFactory.getLogger(HtmlRenderer.class)

    static final Map<String, PDRectangle> pdRectangles =
            [ A0:PDRectangle.A0, A1:PDRectangle.A1, A2:PDRectangle.A2, A3:PDRectangle.A3, A4:PDRectangle.A4,
              A5:PDRectangle.A5, A6:PDRectangle.A6, LEGAL:PDRectangle.LEGAL, LETTER:PDRectangle.LETTER ]
    /* turned out not to need these:
    static PDRectangle dimToPdr(Dimension dim) { return new PDRectangle(dim.width as float, dim.height as float) }
    static final Map<String, Dimension> pageFormatDimensions =
            [ A0:pdrToDim(PDRectangle.A0), A1:pdrToDim(PDRectangle.A1), A2:pdrToDim(PDRectangle.A2),
              A3:pdrToDim(PDRectangle.A3), A4:pdrToDim(PDRectangle.A4), A5:pdrToDim(PDRectangle.A5),
              A6:pdrToDim(PDRectangle.A6), LETTER:pdrToDim(PDRectangle.LETTER), LEGAL:pdrToDim(PDRectangle.LEGAL)]
    */
    static Set<String> mediaTypes = new HashSet<>(['all', 'screen', 'print', 'speech'])

    private DocumentSource docSource = null
    private String mediaType = "screen"
    private PDRectangle windowSizeRaw = PDRectangle.LETTER
    // new Dimension(992, 1284) // NOTE: 992 is the bootstrap md min-width, 1284 = (11/8.5)*992
    private float dimensionScale = 2.0f
    private boolean cropWindow = false
    private boolean loadImages = true
    private boolean loadBackgroundImages = false

    HtmlRenderer() { }

    HtmlRenderer setRenderScale(float scale) { dimensionScale = scale; return this }
    HtmlRenderer setWindowSize(String wsStr) { windowSizeRaw = pdRectangles.get(wsStr); return this }
    HtmlRenderer setWindowSize(PDRectangle pdr) { windowSizeRaw = pdr; return this }
    Dimension getScaledDimension() { return new Dimension(getScaledWidth() as int, getScaledHeight() as int) }
    float getScaledWidth() { return windowSizeRaw.width * dimensionScale }
    float getScaledHeight() { return windowSizeRaw.height * dimensionScale }

    /** Default is 'screen', 'print' also valid */
    HtmlRenderer setMediaType(String media) {
        if (mediaTypes.contains(media)) mediaType = media
        else logger.warn("Ignoring media type ${media}, using previous/default setting ${mediaType}")
        return this
    }
    /** Defaults to false (don't crop at window size) */
    HtmlRenderer setCropWindow(boolean crop) { cropWindow = crop; return this }
    /** Defaults to true (include content), false (don't include background images) */
    HtmlRenderer setLoadImages(boolean content, boolean background) {
        loadImages = content
        loadBackgroundImages = background
        return this
    }

    HtmlRenderer setSourceUrl(String urlString) {
        if (!urlString.startsWith("http:") && !urlString.startsWith("https:") && !urlString.startsWith("ftp:") &&
                !urlString.startsWith("file:")) urlString = "http://" + urlString
        docSource = new DefaultDocumentSource(urlString)
        return this
    }
    HtmlRenderer setSourceString(String htmlString, URL url) {
        ByteArrayInputStream is = new ByteArrayInputStream(htmlString.getBytes(StandardCharsets.UTF_8))
        docSource = new StreamDocumentSource(is, url, "text/html")
        return this
    }

    BrowserCanvas makeContentCanvas() {
        if (docSource == null) throw new IllegalStateException("Cannot render, source not set")

        //Parse the input document
        DOMSource parser = new DefaultDOMSource(docSource)
        Document doc = parser.parse()

        //create the media specification
        MediaSpec media = new MediaSpec(mediaType)
        media.setDimensions(getScaledWidth(), getScaledHeight())
        media.setDeviceDimensions(getScaledWidth(), getScaledHeight())
        System.out.println("HTML Render dedia dimenstions: ${media.getWidth()},${media.getHeight()} device: ${media.getDeviceWidth()},${media.getDeviceHeight()}")

        //Create the CSS analyzer
        DOMAnalyzer da = new DOMAnalyzer(doc, docSource.getURL())
        da.setMediaSpec(media)
        da.attributesToStyles() //convert the HTML presentation attributes to inline styles
        da.addStyleSheet(null, CSSNorm.stdStyleSheet(), DOMAnalyzer.Origin.AGENT) //use the standard style sheet
        da.addStyleSheet(null, CSSNorm.userStyleSheet(), DOMAnalyzer.Origin.AGENT) //use the additional style sheet
        da.addStyleSheet(null, CSSNorm.formsStyleSheet(), DOMAnalyzer.Origin.AGENT) //render form fields using css
        da.getStyleSheets() //load the author style sheets

        BrowserCanvas contentCanvas = new BrowserCanvas(da.getRoot(), da, docSource.getURL())
        contentCanvas.setAutoMediaUpdate(false) //we have a correct media specification, do not update
        BrowserConfig browserConfig = contentCanvas.getConfig()
        browserConfig.setClipViewport(cropWindow)
        browserConfig.setLoadImages(loadImages)
        browserConfig.setLoadBackgroundImages(loadBackgroundImages)

        setDefaultFonts(browserConfig)
        contentCanvas.createLayout(getScaledDimension())

        return contentCanvas
    }

    void renderSvg(Writer out) throws IOException, SAXException {
        try {
            BrowserCanvas contentCanvas = makeContentCanvas()
            Viewport vp = contentCanvas.getViewport()
            //obtain the viewport bounds depending on whether we are clipping to viewport size or using the whole page
            Rectangle contentBounds = vp.getClippedContentBounds()
            SVGRenderer render = new SVGRenderer(contentBounds.width as int, contentBounds.height as int, out)
            try { vp.draw(render) }
            finally { render.close() }
        } finally {
            if (docSource != null) docSource.close()
        }
    }
    /** Render to an image, imageType may be standard Java ImageIO values including 'png' (default), 'jpeg', 'tiff', etc */
    void renderImage(OutputStream out, String imageType) throws IOException, SAXException {
        if (!imageType) imageType = "png"
        try {
            BrowserCanvas contentCanvas = makeContentCanvas()
            ImageIO.write(contentCanvas.getImage(), imageType, out)
        } finally {
            if (docSource != null) docSource.close()
        }
    }

    void renderPdf(OutputStream out) throws IOException, SAXException {
        try {
            BrowserCanvas contentCanvas = makeContentCanvas()
            Viewport vp = contentCanvas.getViewport()
            //obtain the viewport bounds depending on whether we are clipping to viewport size or using the whole page
            Rectangle contentBounds = vp.getClippedContentBounds()
            PDFRenderer render = new PDFRenderer(contentBounds.width as int, contentBounds.height as int, out, windowSizeRaw)
            try { vp.draw(render) }
            finally { render.close() }
        } finally {
            if (docSource != null) docSource.close()
        }
    }


    /** Sets some common fonts as the defaults for generic font families. */
    static protected void setDefaultFonts(BrowserConfig config) {
        config.setDefaultFont(Font.SERIF, "Times New Roman")
        config.setDefaultFont(Font.SANS_SERIF, "Arial")
        config.setDefaultFont(Font.MONOSPACED, "Courier New")
    }
}
