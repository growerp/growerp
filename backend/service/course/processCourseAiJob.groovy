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

try {
    String doneMessage
    switch (job.jobType) {
        case 'OUTLINE': doneMessage = runOutline(); break
        case 'LESSONS': doneMessage = runLessons(); break
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
