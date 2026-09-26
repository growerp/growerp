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

import javax.imageio.ImageIO
import java.awt.Color
import java.awt.Font
import java.awt.Graphics2D
import java.awt.RenderingHints
import java.awt.image.BufferedImage
import java.util.concurrent.TimeUnit

/**
 * Narrated course video: slide images drawn with Java2D, one ffmpeg segment per slide with
 * its narration, joined into one mp4. The look follows the slide pdf of the app.
 */
class CourseVideoUtil {
    static final int WIDTH = 1280
    static final int HEIGHT = 720
    // raw pcm as returned by Gemini text-to-speech
    static final int SAMPLE_RATE = 24000
    static final Color ACCENT = new Color(0x37, 0x47, 0x4F) // blueGrey800

    static String ffmpeg() { return System.getenv("FFMPEG_PATH") ?: "ffmpeg" }

    /** Throws when ffmpeg cannot be run on this server. */
    static void checkFfmpeg() {
        try {
            run([ffmpeg(), "-version"], null, 20)
        } catch (Exception e) {
            throw new Exception("ffmpeg is not installed on the server, it is needed to make videos (${e.message})")
        }
    }

    /** The slide of a module title. */
    static void writeTitleSlide(File file, String courseTitle, String moduleTitle) {
        BufferedImage image = new BufferedImage(WIDTH, HEIGHT, BufferedImage.TYPE_INT_RGB)
        Graphics2D g = graphics(image)
        g.color = ACCENT
        g.fillRect(0, 0, WIDTH, HEIGHT)
        g.color = new Color(0xE0, 0xE0, 0xE0)
        g.font = new Font(Font.SANS_SERIF, Font.PLAIN, 30)
        int y = drawWrapped(g, courseTitle, 80, 280, WIDTH - 160, 40)
        g.color = Color.WHITE
        g.font = new Font(Font.SANS_SERIF, Font.BOLD, 56)
        drawWrapped(g, moduleTitle, 80, y + 50, WIDTH - 160, 68)
        g.dispose()
        ImageIO.write(image, "png", file)
    }

    /** A content slide: title, accent bar, bullets, footer with position. */
    static void writeSlide(File file, String title, List<String> bullets, String footer, int number, int total) {
        BufferedImage image = new BufferedImage(WIDTH, HEIGHT, BufferedImage.TYPE_INT_RGB)
        Graphics2D g = graphics(image)
        g.color = Color.WHITE
        g.fillRect(0, 0, WIDTH, HEIGHT)
        g.color = ACCENT
        g.font = new Font(Font.SANS_SERIF, Font.BOLD, 46)
        int y = drawWrapped(g, title, 80, 110, WIDTH - 160, 56)
        g.fillRect(80, y - 20, 110, 5)
        y += 45
        g.font = new Font(Font.SANS_SERIF, Font.PLAIN, 32)
        for (String bullet in bullets) {
            if (y > HEIGHT - 110) break
            g.color = ACCENT
            g.fillOval(88, y - 20, 12, 12)
            g.color = new Color(0x21, 0x21, 0x21)
            y = drawWrapped(g, bullet, 125, y, WIDTH - 205, 44) + 18
        }
        g.color = new Color(0x75, 0x75, 0x75)
        g.font = new Font(Font.SANS_SERIF, Font.PLAIN, 16)
        g.drawString(footer.length() > 110 ? footer.substring(0, 110) + '…' : footer, 80, HEIGHT - 40)
        String position = "${number} / ${total}"
        g.drawString(position, WIDTH - 80 - g.fontMetrics.stringWidth(position), HEIGHT - 40)
        g.dispose()
        ImageIO.write(image, "png", file)
    }

    /** Silence of about the time it takes to read [text] aloud, used instead of speech in test mode. */
    static byte[] silence(String text) {
        int words = (text ?: '').split(/\s+/).findAll { it }.size()
        double seconds = Math.max(1.5d, words * 0.4d)
        return new byte[((int) (seconds * SAMPLE_RATE)) * 2]
    }

    /** One video segment: the slide image for as long as its narration lasts, plus a short pause. */
    static void writeSegment(File image, File pcm, File out) {
        run([ffmpeg(), "-y", "-loop", "1", "-framerate", "2", "-i", image.path,
             "-f", "s16le", "-ar", "${SAMPLE_RATE}", "-ac", "1", "-i", pcm.path,
             "-af", "apad=pad_dur=0.7", "-c:v", "libx264", "-tune", "stillimage", "-preset", "veryfast",
             "-pix_fmt", "yuv420p", "-r", "25", "-c:a", "aac", "-b:a", "96k", "-ar", "44100",
             "-shortest", out.path], null, 300)
    }

    /** Join the segments (same encoding) into one mp4 that can start playing while it loads. */
    static void concat(List<File> segments, File out) {
        File list = new File(out.parentFile, "segments.txt")
        list.text = segments.collect { "file '${it.name}'" }.join("\n") + "\n"
        run([ffmpeg(), "-y", "-f", "concat", "-safe", "0", "-i", list.name, "-c", "copy",
             "-movflags", "+faststart", out.name], out.parentFile, 300)
    }

    private static Graphics2D graphics(BufferedImage image) {
        Graphics2D g = image.createGraphics()
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON)
        g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON)
        return g
    }

    /** Draws [text] word wrapped from baseline [y]; returns the baseline after the last line. */
    private static int drawWrapped(Graphics2D g, String text, int x, int y, int maxWidth, int lineHeight) {
        def metrics = g.fontMetrics
        StringBuilder line = new StringBuilder()
        for (String word in (text ?: '').split(/\s+/)) {
            String candidate = line ? "${line} ${word}" : word
            if (line && metrics.stringWidth(candidate) > maxWidth) {
                g.drawString(line.toString(), x, y)
                y += lineHeight
                line = new StringBuilder(word)
            } else {
                line = new StringBuilder(candidate)
            }
        }
        if (line) {
            g.drawString(line.toString(), x, y)
            y += lineHeight
        }
        return y
    }

    private static void run(List command, File dir, int timeoutSeconds) {
        ProcessBuilder pb = new ProcessBuilder(command.collect { it.toString() })
        if (dir) pb.directory(dir)
        pb.redirectErrorStream(true)
        Process process = pb.start()
        // drain the output, ffmpeg blocks when its pipe is full
        StringBuilder output = new StringBuilder()
        Thread reader = Thread.start { process.inputStream.eachLine { output.append(it).append('\n') } }
        if (!process.waitFor(timeoutSeconds, TimeUnit.SECONDS)) {
            process.destroyForcibly()
            throw new Exception("${command[0]} took longer than ${timeoutSeconds}s")
        }
        reader.join(5000)
        if (process.exitValue() != 0) {
            String tail = output.length() > 1500 ? output.substring(output.length() - 1500) : output.toString()
            throw new Exception("${command[0]} failed (${process.exitValue()}): ${tail}")
        }
    }
}

// Return the utility class for use by other scripts
return CourseVideoUtil
