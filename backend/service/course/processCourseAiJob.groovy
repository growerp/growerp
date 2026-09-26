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

// Background worker of growerp.100.CourseAiServices100.create#CourseAiJob.
// Runs without a transaction: every service it calls commits on its own, so a failure half
// way leaves the work done so far (a course with some lessons written) in place.

import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import org.moqui.context.ExecutionContext

ExecutionContext ec = context.ec
def CourseAiUtil = ec.resource.script("component://growerp/service/course/CourseAiUtil.groovy", null)
final String STATUS_SERVICE = 'growerp.100.CourseAiServices100.update#CourseAiJobStatus'

// the caller commits the row just before firing this worker; allow for the commit not being
// visible on this thread the very first moment
def job = null
for (int attempt = 0; attempt < 10 && job == null; attempt++) {
    job = ec.entity.find("growerp.course.CourseAiJob").condition("jobId", jobId)
        .useCache(false).disableAuthz().one()
    if (job == null) Thread.sleep(500)
}
if (job == null) {
    ec.logger.error("process#CourseAiJob: job ${jobId} not found")
    return
}
String ownerPartyId = job.ownerPartyId
Map input = new JsonSlurper().parseText(job.inputJson as String ?: '{}') as Map

def progress = { Integer percent, String message, Map extra = [:] ->
    ec.service.sync().name(STATUS_SERVICE)
        .parameters([jobId: jobId, status: 'RUNNING', progressPercent: percent,
                     statusMessage: message] + extra).call()
}
// a service error is left in ec.message: turn it into an exception so the job fails
def svc = { String serviceName, Map parameters ->
    def result = ec.service.sync().name(serviceName).parameters(parameters).call()
    if (ec.message.hasError()) {
        String errors = ec.message.getErrorsString()
        ec.message.clearErrors()
        throw new Exception("${serviceName}: ${errors}")
    }
    return result
}

/** Source material of a course as one text block, cut to the prompt budget. */
def sourceText = { List sources, String query, int maxChars = CourseAiUtil.MAX_SOURCE_CHARS ->
    StringBuilder sb = new StringBuilder()
    for (source in sources) {
        if (source.sourceType == 'KB') continue
        if (!source.content) continue
        sb.append("\n--- ${source.sourceType}: ${source.title ?: source.location ?: ''} ---\n")
        sb.append(source.content).append('\n')
    }
    if (sources.any { it.sourceType == 'KB' } && query
            && ec.service.isServiceDefined('AdkKnowledgeServices.search#AdkKnowledge')) {
        try {
            def found = ec.service.sync().name('AdkKnowledgeServices.search#AdkKnowledge')
                .parameters([ownerPartyId: ownerPartyId, query: query, limit: 6]).call()
            for (Map r in (found?.results ?: [])) {
                sb.append("\n--- KNOWLEDGE BASE: ${r.title ?: ''} ---\n").append(r.text).append('\n')
            }
        } catch (Exception e) {
            ec.logger.warn("Course AI knowledge search failed: ${e.message}")
        }
        ec.message.clearErrors()
    }
    String text = sb.toString()
    return text.length() > maxChars ? text.substring(0, maxChars) + '\n[...source material cut...]' : text
}

def personaText = { String personaId ->
    if (!personaId) return ''
    def persona = ec.entity.find("growerp.marketing.MarketingPersona").condition("personaId", personaId)
        .disableAuthz().one()
    if (!persona) return ''
    return "Persona ${persona.name}: demographics ${persona.demographics ?: '-'}; " +
        "pain points ${persona.painPoints ?: '-'}; goals ${persona.goals ?: '-'}"
}

// ---------------------------------------------------------------------------------------------
// OUTLINE: create the course, its sources, modules and lesson stubs
// ---------------------------------------------------------------------------------------------
def runOutline = {
    progress(5, 'Reading the source material')
    List sources = []
    if (input.curriculum) sources.add([sourceType: 'CURRICULUM', title: 'Curriculum', content: input.curriculum])
    if (input.notes) sources.add([sourceType: 'NOTE', title: 'Notes', content: input.notes])
    for (Map f in (input.files ?: [])) {
        sources.add([sourceType: 'FILE', title: f.fileName, location: f.fileName, content: f.text])
    }
    for (String url in (input.urls ?: [])) {
        try {
            sources.add([sourceType: 'URL', title: url, location: url,
                         content: CourseAiUtil.testMode() ? "Test content of ${url}" : CourseAiUtil.fetchUrlText(url)])
        } catch (Exception e) {
            throw new Exception("Could not read ${url}: ${e.message}")
        }
    }
    if (input.useKnowledgeBase) sources.add([sourceType: 'KB', title: 'Company knowledge base'])

    progress(30, 'Designing the course outline with AI')
    String prompt = """You are an experienced instructional designer. Design the outline of an
online course.

COURSE TITLE: ${input.title}
TARGET AUDIENCE: ${input.audience ?: 'not specified'} ${personaText(input.targetPersonaId)}
DIFFICULTY: ${input.difficulty ?: 'BEGINNER'}

CURRICULUM / TOPICS REQUESTED BY THE AUTHOR:
${input.curriculum ?: '(none: derive the topics from the title and the source material)'}

SOURCE MATERIAL:
${sourceText(sources, "${input.title} ${input.curriculum ?: ''}".take(500)) ?: '(none)'}

RULES:
- Follow the author's curriculum when given: keep its order and topics, split it into modules.
- 3 to 8 modules, each with 2 to 6 lessons; each lesson 5 to 20 minutes.
- Every lesson gets a brief of 2-4 sentences saying exactly what it teaches; a writer will
  later write the lesson from this brief alone.
- Base the content on the source material where it covers a topic; do not invent facts about
  the author's company or products.
- Write in the language of the course title and curriculum.

Answer with JSON only, in this shape:
{"description": "2-3 sentence course description for the catalog",
 "objectives": "markdown bullet list of 3-6 learning objectives",
 "modules": [{"title": "", "description": "one sentence",
   "lessons": [{"title": "", "brief": "", "estimatedDuration": 10}]}]}"""
    def outline = CourseAiUtil.askJson(ec, ownerPartyId, prompt,
        [description: "Test course about ${input.title}", objectives: '- Learn the basics',
         modules: [[title: 'Getting started', description: 'The basics',
                    lessons: [[title: 'Introduction', brief: 'What this course is about.', estimatedDuration: 5],
                              [title: 'First steps', brief: 'The first practical steps.', estimatedDuration: 10]]],
                   [title: 'Going further', description: 'Next steps',
                    lessons: [[title: 'Advanced topics', brief: 'Beyond the basics.', estimatedDuration: 15]]]]])
    if (!(outline instanceof Map) || !outline.modules) throw new Exception('The AI returned no course outline')

    progress(70, 'Creating the course, modules and lessons')
    // only now create the course: a failed AI call leaves nothing behind
    def created = svc('growerp.100.CourseServices100.create#Course',
        [title: input.title, audience: input.audience, targetPersonaId: input.targetPersonaId,
         difficulty: input.difficulty ?: 'BEGINNER'])
    String courseId = created.courseId
    ec.service.sync().name(STATUS_SERVICE).parameters([jobId: jobId, courseId: courseId]).call()
    for (Map s in sources) {
        svc('create#growerp.course.CourseSource', s + [courseId: courseId, createdDate: ec.user.nowTimestamp])
    }
    // uploaded documents also become company knowledge, for the AI chat and later courses
    if (!CourseAiUtil.testMode() && ec.service.isServiceDefined('AdkKnowledgeServices.ingest#AdkKnowledge')) {
        for (Map f in (input.files ?: [])) {
            try {
                ec.service.sync().name('AdkKnowledgeServices.ingest#AdkKnowledge')
                    .parameters([ownerPartyId: ownerPartyId, title: f.fileName, text: f.text,
                                 sourceType: 'course', sourceId: courseId]).call()
            } catch (Exception e) {
                ec.logger.warn("Could not add ${f.fileName} to the knowledge base: ${e.message}")
            }
            ec.message.clearErrors()
        }
    }

    int totalMinutes = 0
    outline.modules.eachWithIndex { Map module, int moduleIndex ->
        def moduleResult = svc('growerp.100.CourseServices100.create#CourseModule',
            [courseId: courseId, title: module.title ?: "Module ${moduleIndex + 1}",
             description: module.description, sequenceNum: moduleIndex + 1])
        int moduleMinutes = 0
        (module.lessons ?: []).eachWithIndex { Map lesson, int lessonIndex ->
            int minutes = (lesson.estimatedDuration ?: 10) as int
            moduleMinutes += minutes
            svc('growerp.100.CourseServices100.create#CourseLesson',
                [moduleId: moduleResult.moduleId, title: lesson.title ?: "Lesson ${lessonIndex + 1}",
                 content: lesson.brief, sequenceNum: lessonIndex + 1, estimatedDuration: minutes])
        }
        svc('growerp.100.CourseServices100.update#CourseModule',
            [moduleId: moduleResult.moduleId, estimatedDuration: moduleMinutes])
        totalMinutes += moduleMinutes
    }
    svc('growerp.100.CourseServices100.update#Course',
        [courseId: courseId, description: outline.description, objectives: outline.objectives,
         estimatedDuration: totalMinutes])
    return "Outline ready: ${outline.modules.size()} modules"
}

// ---------------------------------------------------------------------------------------------
// LESSONS: write content + key points, one lesson at a time
// ---------------------------------------------------------------------------------------------
def runLessons = {
    String courseId = job.courseId
    def course = ec.entity.find("growerp.course.Course").condition("courseId", courseId).disableAuthz().one()
    def modules = ec.entity.find("growerp.course.CourseModule").condition("courseId", courseId)
        .orderBy("sequenceNum").disableAuthz().list()
    def lessons = ec.entity.find("growerp.course.CourseLesson").condition("courseId", courseId)
        .disableAuthz().list()
    def sources = ec.entity.find("growerp.course.CourseSource").condition("courseId", courseId)
        .orderBy("createdDate").disableAuthz().list()
    StringBuilder outlineText = new StringBuilder()
    List todo = []
    for (module in modules) {
        outlineText.append("Module ${module.sequenceNum}: ${module.title}\n")
        for (lesson in lessons.findAll { it.moduleId == module.moduleId }.sort { it.sequenceNum }) {
            outlineText.append("  - ${lesson.title}\n")
            if (!input.lessonIds || lesson.lessonId in input.lessonIds) todo.add([module: module, lesson: lesson])
        }
    }
    if (!todo) throw new Exception('No lessons to write')
    List failed = []

    todo.eachWithIndex { Map item, int index ->
        def lesson = item.lesson
        progress((int) (5 + 90 * index / todo.size()),
            "Writing lesson ${index + 1} of ${todo.size()}: ${lesson.title}")
        String prompt = """You are an expert teacher writing one lesson of an online course.

COURSE: ${course.title}
TARGET AUDIENCE: ${course.audience ?: 'not specified'} ${personaText(course.targetPersonaId)}
DIFFICULTY: ${course.difficulty ?: 'BEGINNER'}
COURSE OUTLINE:
${outlineText}
THIS LESSON: ${lesson.title} (module "${item.module.title}", about ${lesson.estimatedDuration ?: 10} minutes reading)
LESSON BRIEF / CURRENT TEXT:
${lesson.content ?: '(none)'}

SOURCE MATERIAL:
${sourceText(sources, "${course.title} ${lesson.title}", CourseAiUtil.MAX_LESSON_SOURCE_CHARS) ?: '(none)'}

RULES:
- Write the complete lesson in Markdown: short intro, sections with ## headings, concrete
  examples, and a short summary at the end. No top level # title.
- Match the length to the reading time.
- Base facts on the source material when it covers the topic; never invent facts about the
  author's company or products.
- Do not repeat what other lessons in the outline cover.
- Write in the language of the course title.

Answer with JSON only: {"content": "the markdown lesson", "keyPoints": ["3 to 5 short takeaways"]}"""
        // one lesson failing should not lose the others: skip it and report it
        try {
            def written = CourseAiUtil.askJson(ec, ownerPartyId, prompt,
                [content: "## ${lesson.title}\n\nTest lesson content.", keyPoints: ['First takeaway', 'Second takeaway']])
            if (!(written instanceof Map) || !written.content) throw new Exception("The AI returned no content")
            svc('growerp.100.CourseServices100.update#CourseLesson',
                [lessonId: lesson.lessonId, content: written.content,
                 keyPoints: JsonOutput.toJson(written.keyPoints ?: [])])
        } catch (Exception e) {
            // no tokens left: the other lessons would fail the same way
            if (CourseAiUtil.isAllowanceError(e)) throw e
            ec.logger.warn("Course AI could not write lesson ${lesson.lessonId} ${lesson.title}: ${e.message}")
            ec.message.clearErrors()
            failed.add(lesson.title)
        }
    }
    int writtenCount = todo.size() - failed.size()
    if (writtenCount == 0) throw new Exception("No lesson could be written, try again")
    return "${writtenCount} lesson${writtenCount == 1 ? '' : 's'} written" +
        (failed ? ", not written (try again): ${failed.join(', ')}" : '')
}

// ---------------------------------------------------------------------------------------------
// QUIZ: multiple choice questions per module, from the lesson content
// ---------------------------------------------------------------------------------------------
def runQuiz = {
    String courseId = job.courseId
    def course = ec.entity.find("growerp.course.Course").condition("courseId", courseId).disableAuthz().one()
    def modules = ec.entity.find("growerp.course.CourseModule").condition("courseId", courseId)
        .orderBy("sequenceNum").disableAuthz().list()
        .findAll { !input.moduleIds || it.moduleId in input.moduleIds }
    if (!modules) throw new Exception('No modules to write a quiz for')
    int count = (input.questionsPerModule ?: 5) as int
    int written = 0
    modules.eachWithIndex { module, int index ->
        progress((int) (5 + 90 * index / modules.size()), "Writing the quiz of module ${index + 1} of ${modules.size()}: ${module.title}")
        def lessons = ec.entity.find("growerp.course.CourseLesson").condition("moduleId", module.moduleId)
            .orderBy("sequenceNum").disableAuthz().list()
        String lessonText = lessons.collect { "## ${it.title}\n${it.content ?: ''}" }.join('\n\n')
        if (lessonText.length() > 30000) lessonText = lessonText.substring(0, 30000)
        String prompt = """You are an experienced teacher writing the quiz at the end of a course module.

COURSE: ${course.title}
DIFFICULTY: ${course.difficulty ?: 'BEGINNER'}
MODULE: ${module.title}
LESSONS OF THE MODULE:
${lessonText}

RULES:
- Write exactly ${count} multiple choice questions that test understanding of the lessons
  above, not trivia; each question is answered by the lesson text.
- 4 options per question, exactly one correct; wrong options must be plausible.
- Vary the position of the correct option.
- A one or two sentence explanation of why the correct option is right.
- Write in the language of the lessons.

Answer with JSON only:
{"questions": [{"question": "", "options": ["", "", "", ""], "correctIndex": 0, "explanation": ""}]}"""
        def quiz = CourseAiUtil.askJson(ec, ownerPartyId, prompt,
            [questions: (1..count).collect { n ->
                [question: "Test question ${n} of ${module.title}?", options: ['Right', 'Wrong 1', 'Wrong 2', 'Wrong 3'],
                 correctIndex: 0, explanation: 'Test explanation.'] }])
        def questions = (quiz instanceof Map ? quiz.questions : null)?.findAll { Map q ->
            q.question && q.options instanceof List && q.options.size() >= 2 &&
                q.correctIndex instanceof Number && q.correctIndex >= 0 && q.correctIndex < q.options.size() }
        if (!questions) throw new Exception("The AI returned no usable questions for ${module.title}")
        // replace the quiz of the module
        ec.entity.find("growerp.course.CourseQuizQuestion").condition("moduleId", module.moduleId)
            .disableAuthz().deleteAll()
        questions.eachWithIndex { Map q, int n ->
            svc('growerp.100.CourseQuizServices100.create#CourseQuizQuestion',
                [moduleId: module.moduleId, question: q.question, options: q.options,
                 correctIndex: q.correctIndex, explanation: q.explanation, sequenceNum: n + 1])
        }
        written += questions.size()
    }
    return "${written} quiz questions written for ${modules.size()} module${modules.size() == 1 ? '' : 's'}"
}

// ---------------------------------------------------------------------------------------------
// SLIDES: a slide deck per module; the speaker notes are the narration of the course video
// ---------------------------------------------------------------------------------------------
def runSlides = {
    String courseId = job.courseId
    def course = ec.entity.find("growerp.course.Course").condition("courseId", courseId).disableAuthz().one()
    def modules = ec.entity.find("growerp.course.CourseModule").condition("courseId", courseId)
        .orderBy("sequenceNum").disableAuthz().list()
        .findAll { !input.moduleIds || it.moduleId in input.moduleIds }
    if (!modules) throw new Exception('No modules to make slides for')
    int slideCount = 0
    modules.eachWithIndex { module, int index ->
        progress((int) (5 + 90 * index / modules.size()), "Making the slides of module ${index + 1} of ${modules.size()}: ${module.title}")
        def lessons = ec.entity.find("growerp.course.CourseLesson").condition("moduleId", module.moduleId)
            .orderBy("sequenceNum").disableAuthz().list()
        String lessonText = lessons.collect { "## ${it.title}\n${it.content ?: ''}" }.join('\n\n')
        if (lessonText.length() > 30000) lessonText = lessonText.substring(0, 30000)
        String prompt = """You are an experienced trainer turning a course module into a presentation.

COURSE: ${course.title}
TARGET AUDIENCE: ${course.audience ?: 'not specified'}
MODULE ${module.sequenceNum}: ${module.title}
LESSONS OF THE MODULE:
${lessonText}

RULES:
- 1 or 2 slides per lesson plus a closing summary slide; no title slide (it is added).
- A slide has a short title (max 8 words) and 2 to 5 bullets of max 12 words each.
- "notes" is what the presenter says with the slide: 60 to 120 words of natural spoken
  explanation that adds to the bullets instead of reading them out. It becomes the voice-over
  of the course video, so no stage directions, no markdown.
- Follow the order of the lessons; only use facts from the lessons.
- Write in the language of the lessons.

Answer with JSON only:
{"slides": [{"title": "", "bullets": ["", ""], "notes": ""}]}"""
        def deck = CourseAiUtil.askJson(ec, ownerPartyId, prompt,
            [slides: lessons.collect { l ->
                [title: l.title as String, bullets: ['Test bullet one', 'Test bullet two'],
                 notes: "Test narration of ${l.title}."] } +
                [[title: 'Summary', bullets: ['Test summary'], notes: 'Test closing narration.']]])
        def slides = (deck instanceof Map ? deck.slides : null)?.findAll { it instanceof Map && it.title }
            ?.collect { Map sl -> [title: sl.title, bullets: (sl.bullets ?: []).collect { it as String },
                                   notes: sl.notes ?: ''] }
        if (!slides) throw new Exception("The AI returned no slides for ${module.title}")
        svc('growerp.100.CourseServices100.update#CourseModule',
            [moduleId: module.moduleId, slides: JsonOutput.toJson(slides)])
        slideCount += slides.size()
    }
    return "${slideCount} slides made for ${modules.size()} module${modules.size() == 1 ? '' : 's'}"
}

// ---------------------------------------------------------------------------------------------
// VIDEO: per module, the slides with their speaker notes spoken, as one mp4
// ---------------------------------------------------------------------------------------------
def runVideo = {
    def CourseVideoUtil = ec.resource.script("component://growerp/service/course/CourseVideoUtil.groovy", null)
    def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)
    CourseVideoUtil.checkFfmpeg()
    String courseId = job.courseId
    def course = ec.entity.find("growerp.course.Course").condition("courseId", courseId).disableAuthz().one()
    def slurper = new JsonSlurper()
    def modules = ec.entity.find("growerp.course.CourseModule").condition("courseId", courseId)
        .orderBy("sequenceNum").disableAuthz().list()
        .findAll { (!input.moduleIds || it.moduleId in input.moduleIds) && it.slides }
        .collect { [module: it, slides: slurper.parseText(it.slides as String) as List] }
        .findAll { it.slides }
    if (!modules) throw new Exception('Make the slides first: the video shows the slides and speaks their notes')
    String companyPartyId = svc('growerp.100.GeneralServices100.get#RelatedCompanyAndOwner', [:]).companyPartyId
    int totalSlides = modules.sum { it.slides.size() + 1 } as int
    int doneSlides = 0
    modules.each { Map item ->
        def module = item.module
        File dir = java.nio.file.Files.createTempDirectory("course-video").toFile()
        try {
            // the title slide introduces the module, then every slide with its notes
            List parts = [[image: { File f -> CourseVideoUtil.writeTitleSlide(f, course.title, "Module ${module.sequenceNum}: ${module.title}") },
                           narration: "Module ${module.sequenceNum}: ${module.title}."]]
            item.slides.eachWithIndex { Map slide, int n ->
                List bullets = (slide.bullets ?: []).collect { it as String }
                parts.add([image: { File f -> CourseVideoUtil.writeSlide(f, slide.title as String, bullets,
                                        "${course.title} · ${module.title}", n + 1, item.slides.size()) },
                           narration: slide.notes ?: ([slide.title] + bullets).join('. ')])
            }
            List segments = []
            parts.eachWithIndex { Map part, int n ->
                progress((int) (5 + 90 * doneSlides / totalSlides),
                    "Module ${module.sequenceNum}: speaking slide ${n + 1} of ${parts.size()}")
                File image = new File(dir, "slide${n}.png")
                part.image.call(image)
                byte[] pcm = CourseAiUtil.testMode() ? CourseVideoUtil.silence(part.narration as String) :
                    GeminiAiUtil.callGeminiTts(ec, part.narration as String,
                        [ownerPartyId: ownerPartyId, purpose: 'course video'])
                File audio = new File(dir, "slide${n}.pcm")
                audio.bytes = pcm
                File segment = new File(dir, "segment${n}.mp4")
                CourseVideoUtil.writeSegment(image, audio, segment)
                segments.add(segment)
                doneSlides++
            }
            progress((int) (5 + 90 * doneSlides / totalSlides), "Module ${module.sequenceNum}: joining the video")
            File video = new File(dir, "module.mp4")
            CourseVideoUtil.concat(segments, video)

            // a new token per video: an old link stops working when the video is made again
            String token = UUID.randomUUID().toString().replace('-', '')
            String location = "dbresource://C${companyPartyId}/courses/${courseId}/video-${module.moduleId}-${token}.mp4"
            byte[] bytes = video.bytes
            ec.transaction.runRequireNew(600, "Could not save the video of ${module.title}", {
                ec.resource.getLocationReference(location).putBytes(bytes)
                def current = ec.entity.find("growerp.course.CourseModule").condition("moduleId", module.moduleId)
                    .forUpdate(true).disableAuthz().one()
                String old = current.videoLocation
                current.videoLocation = location
                current.videoToken = token
                current.update()
                if (old) ec.resource.getLocationReference(old).delete()
            })
            ec.logger.info("Course video of module ${module.moduleId}: ${bytes.length} bytes, ${parts.size()} slides")
        } finally {
            dir.deleteDir()
        }
    }
    return "${modules.size()} video${modules.size() == 1 ? '' : 's'} made"
}

try {
    String doneMessage
    switch (job.jobType) {
        case 'OUTLINE': doneMessage = runOutline(); break
        case 'LESSONS': doneMessage = runLessons(); break
        case 'QUIZ': doneMessage = runQuiz(); break
        case 'SLIDES': doneMessage = runSlides(); break
        case 'VIDEO': doneMessage = runVideo(); break
        default: throw new Exception("Unknown AI job type ${job.jobType}")
    }
    ec.service.sync().name(STATUS_SERVICE).parameters([jobId: jobId, status: 'DONE',
        progressPercent: 100, statusMessage: doneMessage, completedDate: ec.user.nowTimestamp]).call()
    ec.logger.info("process#CourseAiJob ${jobId} ${job.jobType}: ${doneMessage}")
} catch (Throwable t) {
    ec.logger.error("process#CourseAiJob ${jobId} ${job.jobType} failed", t)
    ec.message.clearErrors()
    ec.service.sync().name(STATUS_SERVICE).parameters([jobId: jobId, status: 'ERROR',
        statusMessage: 'Failed', errorMessage: (t.message ?: t.toString()).take(4000),
        errorCode: CourseAiUtil.isAllowanceError(t) ? 'AI_ALLOWANCE' : null,
        completedDate: ec.user.nowTimestamp]).call()
}
