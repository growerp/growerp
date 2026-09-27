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

/** The language rule of a prompt: the course language when set, else [fallback]. */
def languageLine = { def course, String fallback ->
    if (!course?.languageId) return "- Write in the language of ${fallback}."
    String name = Locale.forLanguageTag(course.languageId as String).getDisplayLanguage(Locale.ENGLISH)
    return "- Write in ${name ?: course.languageId}."
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
${input.notes ? "\nCHANGES THE AUTHOR ASKS FOR:\n${input.notes}\n" : ''}
SOURCE MATERIAL:
${sourceText(sources, "${course.title} ${lesson.title}", CourseAiUtil.MAX_LESSON_SOURCE_CHARS) ?: '(none)'}

RULES:
- Write the complete lesson in Markdown: short intro, sections with ## headings, concrete
  examples, and a short summary at the end. No top level # title.
- Match the length to the reading time.
- Base facts on the source material when it covers the topic; never invent facts about the
  author's company or products.
- Do not repeat what other lessons in the outline cover.
${languageLine(course, 'the course title')}

Answer with JSON only: {"content": "the markdown lesson", "keyPoints": ["3 to 5 short takeaways"]}"""
        // one lesson failing should not lose the others: skip it and report it
        try {
            def written = CourseAiUtil.askJson(ec, ownerPartyId, prompt,
                [content: "## ${lesson.title}\n\nTest lesson content.", keyPoints: ['First takeaway', 'Second takeaway']])
            if (!(written instanceof Map) || !written.content) throw new Exception("The AI returned no content")
            svc('growerp.100.CourseServices100.update#CourseLesson',
                [lessonId: lesson.lessonId, content: written.content,
                 keyPoints: JsonOutput.toJson(written.keyPoints ?: []), changeReason: 'AI_LESSONS',
                 clearReviewNotes: true])
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
        String lessonText = lessons.collect { "## [${it.lessonId}] ${it.title}\n${it.content ?: ''}" }.join('\n\n')
        if (lessonText.length() > 30000) lessonText = lessonText.substring(0, 30000)
        String prompt = """You are an experienced teacher writing the quiz at the end of a course module.

COURSE: ${course.title}
DIFFICULTY: ${course.difficulty ?: 'BEGINNER'}
MODULE: ${module.title}
LESSONS OF THE MODULE (lesson id in brackets):
${lessonText}

RULES:
- Write exactly ${count} multiple choice questions that test understanding of the lessons
  above, not trivia; each question is answered by the lesson text.
- 4 options per question, exactly one correct; wrong options must be plausible.
- Vary the position of the correct option.
- A one or two sentence explanation of why the correct option is right.
- lessonId: the id of the lesson that answers the question.
${languageLine(course, 'the lessons')}

Answer with JSON only:
{"questions": [{"question": "", "options": ["", "", "", ""], "correctIndex": 0, "explanation": "", "lessonId": ""}]}"""
        def quiz = CourseAiUtil.askJson(ec, ownerPartyId, prompt,
            [questions: (1..count).collect { n ->
                [question: "Test question ${n} of ${module.title}?", options: ['Right', 'Wrong 1', 'Wrong 2', 'Wrong 3'],
                 correctIndex: 0, explanation: 'Test explanation.', lessonId: lessons ? lessons[0].lessonId : null] }])
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
                 correctIndex: q.correctIndex, explanation: q.explanation, sequenceNum: n + 1,
                 lessonId: lessons.find { it.lessonId == q.lessonId }?.lessonId])
        }
        written += questions.size()
    }
    return "${written} quiz questions written for ${modules.size()} module${modules.size() == 1 ? '' : 's'}"
}

// ---------------------------------------------------------------------------------------------
// EXERCISE: hands-on exercises per module and a capstone project for the whole course
// ---------------------------------------------------------------------------------------------
def runExercise = {
    String courseId = job.courseId
    def course = ec.entity.find("growerp.course.Course").condition("courseId", courseId).disableAuthz().one()
    def modules = ec.entity.find("growerp.course.CourseModule").condition("courseId", courseId)
        .orderBy("sequenceNum").disableAuthz().list()
        .findAll { !input.moduleIds || it.moduleId in input.moduleIds }
    if (!modules) throw new Exception('No modules to write exercises for')
    // exercises learners already handed work in for are kept, the others are replaced
    def submitted = ec.entity.find("growerp.course.CourseSubmission").condition("courseId", courseId)
        .disableAuthz().list()*.exerciseId.unique()
    def replace = { Closure filter ->
        ec.entity.find("growerp.course.CourseExercise").condition("courseId", courseId).disableAuthz().list()
            .findAll { filter(it) && !(it.exerciseId in submitted) }.each { it.delete() }
    }
    def create = { Map ex, String moduleId, String lessonId, String defaultType ->
        String type = ex.exerciseType in ['TEXT', 'CODE', 'PROJECT'] ? ex.exerciseType : defaultType
        svc('growerp.100.CourseExerciseServices100.create#CourseExercise',
            [courseId: courseId, moduleId: moduleId, lessonId: lessonId, exerciseType: type,
             title: ex.title, prompt: ex.prompt, rubric: ex.rubric])
    }
    String common = """RULES:
- Exercises make the learner APPLY what was taught to a realistic situation, not repeat facts.
- exerciseType CODE when the learner has to write code, otherwise TEXT.
- prompt: the task in Markdown, with the situation, what to hand in and roughly how long it takes.
- rubric: 3 to 5 grading criteria for the grader (the learner does not see them), with what a
  good answer contains.
${languageLine(course, 'the lessons')}"""
    int written = 0
    int steps = modules.size() + (input.moduleIds ? 0 : 1)
    modules.eachWithIndex { module, int index ->
        progress((int) (5 + 90 * index / steps), "Writing the exercises of module ${index + 1} of ${modules.size()}: ${module.title}")
        def lessons = ec.entity.find("growerp.course.CourseLesson").condition("moduleId", module.moduleId)
            .orderBy("sequenceNum").disableAuthz().list()
        String lessonText = lessons.collect { "## [${it.lessonId}] ${it.title}\n${it.content ?: ''}" }.join('\n\n')
        if (lessonText.length() > 30000) lessonText = lessonText.substring(0, 30000)
        String prompt = """You are an experienced teacher writing practice exercises for a course module.

COURSE: ${course.title}
AUDIENCE: ${course.audience ?: 'not specified'}
DIFFICULTY: ${course.difficulty ?: 'BEGINNER'}
MODULE: ${module.title}
LESSONS OF THE MODULE (lesson id in brackets):
${lessonText}

Write 1 or 2 exercises for this module; lessonId is the id of the lesson it practices most.
${common}

Answer with JSON only:
{"exercises": [{"lessonId": "", "exerciseType": "TEXT", "title": "", "prompt": "", "rubric": ""}]}"""
        def answer = CourseAiUtil.askJson(ec, ownerPartyId, prompt,
            [exercises: [[lessonId: lessons ? lessons[0].lessonId : null, exerciseType: 'TEXT',
                title: "Test exercise of ${module.title}".toString(),
                prompt: 'Apply the lesson to your own situation.', rubric: 'Uses the lesson.']]])
        def exercises = (answer instanceof Map ? answer.exercises : null)?.findAll { it instanceof Map && it.title && it.prompt }
        if (!exercises) throw new Exception("The AI returned no usable exercises for ${module.title}")
        replace { it.moduleId == module.moduleId }
        exercises.each { Map ex ->
            create(ex, module.moduleId, lessons.find { it.lessonId == ex.lessonId }?.lessonId, 'TEXT')
            written++
        }
    }
    if (!input.moduleIds) {
        progress(90, "Writing the capstone project")
        def allModules = ec.entity.find("growerp.course.CourseModule").condition("courseId", courseId)
            .orderBy("sequenceNum").disableAuthz().list()
        String prompt = """You are an experienced teacher writing the capstone project of an online course: the
learner builds something real that combines what the whole course teaches.

COURSE: ${course.title}
OBJECTIVES: ${course.objectives ?: 'not specified'}
AUDIENCE: ${course.audience ?: 'not specified'}
DIFFICULTY: ${course.difficulty ?: 'BEGINNER'}
MODULES: ${allModules*.title.join('; ')}

Write one capstone project, exerciseType PROJECT, with the deliverable the learner hands in as
text (a plan, document, code or a description with links).
${common}

Answer with JSON only: {"title": "", "prompt": "", "rubric": ""}"""
        def project = CourseAiUtil.askJson(ec, ownerPartyId, prompt,
            [title: "Capstone of ${course.title}".toString(), prompt: 'Build something with what you learned.',
             rubric: 'Applies the whole course.'])
        if (project instanceof Map && project.title && project.prompt) {
            replace { !it.moduleId }
            create(project + [exerciseType: 'PROJECT'], null, null, 'PROJECT')
            written++
        }
    }
    return "${written} exercise${written == 1 ? '' : 's'} written"
}

// ---------------------------------------------------------------------------------------------
// TRANSLATE: a copy of the course in another language (modules, slides, lessons, quizzes,
// exercises); videos, cover and price are made again for the copy by the author
// ---------------------------------------------------------------------------------------------
def runTranslate = {
    String target = input.targetLanguage as String
    if (!target) throw new Exception('No language to translate into')
    String targetName = Locale.forLanguageTag(target).getDisplayLanguage(Locale.ENGLISH) ?: target
    def source = ec.entity.find("growerp.course.Course").condition("courseId", job.courseId).disableAuthz().one()
    def modules = ec.entity.find("growerp.course.CourseModule").condition("courseId", source.courseId)
        .orderBy("sequenceNum").disableAuthz().list()
    def lessons = ec.entity.find("growerp.course.CourseLesson").condition("courseId", source.courseId)
        .orderBy("sequenceNum").disableAuthz().list()
    def questions = ec.entity.find("growerp.course.CourseQuizQuestion").condition("courseId", source.courseId)
        .orderBy("sequenceNum").disableAuthz().list()
    def exercises = ec.entity.find("growerp.course.CourseExercise").condition("courseId", source.courseId)
        .orderBy("sequenceNum").disableAuthz().list()
    def slurper = new JsonSlurper()

    /** the same JSON with its text values translated; test mode returns it as it is */
    def translate = { Map data ->
        String prompt = """Translate the text values of the JSON below into ${targetName}.

RULES:
- Keep the JSON structure and all keys exactly as they are; translate only the text values.
- Keep Markdown formatting, code, URLs, numbers, product and company names unchanged.
- Translate naturally for the course audience, not word for word.

JSON:
${JsonOutput.toJson(data)}

Answer with the translated JSON only."""
        def translated = CourseAiUtil.askJson(ec, ownerPartyId, prompt, data)
        if (!(translated instanceof Map)) throw new Exception('The AI returned no translation')
        return translated as Map
    }

    int steps = 1 + modules.size() + lessons.size()
    int step = 0
    progress(2, "Translating the course into ${targetName}")
    Map meta = translate([title: source.title, description: source.description ?: '',
        objectives: source.objectives ?: '', audience: source.audience ?: ''])
    if (CourseAiUtil.testMode()) meta.title = "[${target}] ${meta.title}".toString()
    def created = svc('growerp.100.CourseServices100.create#Course',
        [title: meta.title ?: source.title, description: meta.description ?: null,
         objectives: meta.objectives ?: null, audience: meta.audience ?: null,
         targetPersonaId: source.targetPersonaId, difficulty: source.difficulty,
         estimatedDuration: source.estimatedDuration, languageId: target,
         sourceCourseId: source.courseId, requireInstructorReview: source.requireInstructorReview,
         sequentialUnlock: source.sequentialUnlock, pacing: source.pacing])
    String newCourseId = created.courseId
    step++

    Map moduleIds = [:]   // source moduleId: new moduleId
    Map lessonIds = [:]
    for (module in modules) {
        progress((int) (5 + 90 * step / steps), "Translating module ${module.sequenceNum}: ${module.title}")
        List slides = module.slides ? slurper.parseText(module.slides as String) as List : []
        Map moduleT = translate([title: module.title, description: module.description ?: '', slides: slides])
        def newModule = svc('growerp.100.CourseServices100.create#CourseModule',
            [courseId: newCourseId, title: moduleT.title ?: module.title,
             description: moduleT.description ?: null, sequenceNum: module.sequenceNum,
             estimatedDuration: module.estimatedDuration, dueDays: module.dueDays,
             slides: slides ? JsonOutput.toJson(moduleT.slides ?: slides) : null])
        moduleIds[module.moduleId] = newModule.moduleId
        step++
        for (lesson in lessons.findAll { it.moduleId == module.moduleId }) {
            progress((int) (5 + 90 * step / steps), "Translating lesson: ${lesson.title}")
            List keyPoints = lesson.keyPoints ? slurper.parseText(lesson.keyPoints as String) as List : []
            Map lessonT = translate([title: lesson.title, content: lesson.content ?: '', keyPoints: keyPoints])
            def newLesson = svc('growerp.100.CourseServices100.create#CourseLesson',
                [moduleId: newModule.moduleId, title: lessonT.title ?: lesson.title,
                 content: lessonT.content ?: null, keyPoints: JsonOutput.toJson(lessonT.keyPoints ?: keyPoints),
                 sequenceNum: lesson.sequenceNum, estimatedDuration: lesson.estimatedDuration,
                 imageUrl: lesson.imageUrl])
            lessonIds[lesson.lessonId] = newLesson.lessonId
            step++
        }
        // the quiz of the module, same correct answers
        def moduleQuestions = questions.findAll { it.moduleId == module.moduleId }
        if (moduleQuestions) {
            Map quizT = translate([questions: moduleQuestions.collect { q ->
                [question: q.question, options: slurper.parseText(q.optionsJson ?: '[]'),
                 explanation: q.explanation ?: ''] }])
            moduleQuestions.eachWithIndex { q, int n ->
                Map t = (quizT.questions instanceof List && n < quizT.questions.size()) ? quizT.questions[n] as Map : [:]
                List options = t.options instanceof List && t.options.size() == slurper.parseText(q.optionsJson ?: '[]').size() ?
                    t.options : slurper.parseText(q.optionsJson ?: '[]')
                svc('growerp.100.CourseQuizServices100.create#CourseQuizQuestion',
                    [moduleId: newModule.moduleId, question: t.question ?: q.question, options: options,
                     correctIndex: q.correctIndex, explanation: t.explanation ?: q.explanation,
                     sequenceNum: q.sequenceNum, lessonId: lessonIds[q.lessonId]])
            }
        }
    }
    // exercises of the modules and the capstone
    if (exercises) {
        progress(95, "Translating the exercises")
        Map exT = translate([exercises: exercises.collect { e ->
            [title: e.title, prompt: e.prompt ?: '', rubric: e.rubric ?: ''] }])
        exercises.eachWithIndex { e, int n ->
            Map t = (exT.exercises instanceof List && n < exT.exercises.size()) ? exT.exercises[n] as Map : [:]
            svc('growerp.100.CourseExerciseServices100.create#CourseExercise',
                [courseId: newCourseId, moduleId: moduleIds[e.moduleId], lessonId: lessonIds[e.lessonId],
                 exerciseType: e.exerciseType ?: 'TEXT', title: t.title ?: e.title,
                 prompt: t.prompt ?: e.prompt, rubric: t.rubric ?: e.rubric, sequenceNum: e.sequenceNum])
        }
    }
    return "Translated into ${targetName}: ${meta.title ?: source.title}"
}

// ---------------------------------------------------------------------------------------------
// REVIEW: check the lessons for outdated or wrong statements against the (refreshed) sources;
// the findings go on the lesson as review notes for the author
// ---------------------------------------------------------------------------------------------
def runReview = {
    String courseId = job.courseId
    def course = ec.entity.find("growerp.course.Course").condition("courseId", courseId).disableAuthz().one()
    def lessons = ec.entity.find("growerp.course.CourseLesson").condition("courseId", courseId)
        .orderBy("sequenceNum").disableAuthz().list()
        .findAll { it.content && (!input.lessonIds || it.lessonId in input.lessonIds) }
    if (!lessons) throw new Exception('No written lessons to check')
    // web pages the course was made from may have changed: read them again
    def sources = ec.entity.find("growerp.course.CourseSource").condition("courseId", courseId)
        .orderBy("createdDate").disableAuthz().list()
    if (!CourseAiUtil.testMode()) {
        for (source in sources.findAll { it.sourceType == 'URL' && it.location }) {
            try {
                String text = CourseAiUtil.fetchUrlText(source.location as String)
                if (text?.trim()) { source.content = text.take(CourseAiUtil.MAX_SOURCE_CHARS); source.update() }
            } catch (Exception e) {
                ec.logger.warn("Course review could not read ${source.location}: ${e.message}")
            }
        }
    }
    int flagged = 0
    lessons.eachWithIndex { lesson, int index ->
        progress((int) (5 + 90 * index / lessons.size()), "Checking lesson ${index + 1} of ${lessons.size()}: ${lesson.title}")
        String prompt = """You are a subject expert reviewing one lesson of an online course for content that is
outdated, no longer correct, or missing an important recent development. Today is ${ec.user.nowTimestamp.toString().take(10)}.

COURSE: ${course.title}
LESSON: ${lesson.title}
LESSON TEXT:
${lesson.content}

SOURCE MATERIAL (may be more recent):
${sourceText(sources, "${course.title} ${lesson.title}", CourseAiUtil.MAX_LESSON_SOURCE_CHARS) ?: '(none)'}

RULES:
- Only report real problems: facts, prices, versions, laws, tools or practices that changed or
  are wrong. Style and wording are not problems.
- text: the statement of the lesson, quoted briefly; suggestion: what it should say now.
- No problems: an empty issues list.
- summary: one sentence; write it and the suggestions in the language of the lesson.

Answer with JSON only: {"summary": "", "issues": [{"text": "", "suggestion": ""}]}"""
        def review = CourseAiUtil.askJson(ec, ownerPartyId, prompt,
            [summary: 'Test review.', issues: index == 0 ? [[text: 'Test statement', suggestion: 'Test update']] : []])
        def issues = (review instanceof Map ? review.issues : null)?.findAll { it instanceof Map && it.text }
        if (issues) {
            svc('growerp.100.CourseServices100.update#CourseLesson', [lessonId: lesson.lessonId,
                reviewNotes: JsonOutput.toJson([summary: review.summary, issues: issues])])
            flagged++
        } else {
            svc('growerp.100.CourseServices100.update#CourseLesson', [lessonId: lesson.lessonId, clearReviewNotes: true])
        }
    }
    course.lastReviewedDate = ec.user.nowTimestamp
    course.update()
    return flagged ? "${flagged} of ${lessons.size()} lessons may need an update" :
        "${lessons.size()} lessons checked, nothing outdated found"
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
${languageLine(course, 'the lessons')}

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

// ---------------------------------------------------------------------------------------------
// PROMO: cover image, landing page, email sequence and social posts for the course
// ---------------------------------------------------------------------------------------------
def runPromo = {
    String courseId = job.courseId
    def course = ec.entity.find("growerp.course.Course").condition("courseId", courseId).disableAuthz().one()
    def modules = ec.entity.find("growerp.course.CourseModule").condition("courseId", courseId)
        .orderBy("sequenceNum").disableAuthz().list()
    List parts = input.parts ?: ['COVER', 'LANDING', 'EMAIL', 'SOCIAL']
    List made = [], failed = []
    // one part failing does not stop the others, except when the tokens ran out
    def attempt = { String label, Closure work ->
        try {
            work()
            made.add(label)
        } catch (Exception e) {
            if (CourseAiUtil.isAllowanceError(e)) throw e
            ec.logger.warn("Course promo ${label} failed: ${e.message}")
            ec.message.clearErrors()
            failed.add(label)
        }
    }

    if ('COVER' in parts) {
        progress(5, 'Making the cover image')
        attempt('cover image') {
            byte[] image
            if (CourseAiUtil.testMode()) {
                def CourseVideoUtil = ec.resource.script("component://growerp/service/course/CourseVideoUtil.groovy", null)
                File file = File.createTempFile("cover", ".png")
                try {
                    CourseVideoUtil.writeTitleSlide(file, 'Online course', course.title as String)
                    image = file.bytes
                } finally {
                    file.delete()
                }
            } else {
                def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)
                image = GeminiAiUtil.callGeminiImage(ec, """Create a wide 16:9 cover illustration for an
online course. Course: ${course.title}. ${course.description ?: ''}
Audience: ${course.audience ?: 'professionals'}.
Style: modern, clean, friendly flat illustration with a clear focal subject and calm colors.
Do not put any text, letters or logos in the image.""", [ownerPartyId: ownerPartyId, purpose: 'course cover'])
            }
            // a fixed location per course; the version in the url makes browsers load a new one
            String location = "dbresource://C${course.ownerPartyId}/courses/${courseId}/cover.png"
            ec.transaction.runRequireNew(120, "Could not save the cover image", {
                ec.resource.getLocationReference(location).putBytes(image)
            })
            svc('growerp.100.CourseServices100.update#Course', [courseId: courseId,
                coverImageUrl: "/courseMedia/cover?c=${courseId}&v=${System.currentTimeMillis()}".toString()])
        }
    }

    if ('LANDING' in parts) {
        progress(25, 'Writing the landing page')
        attempt('landing page') {
            if (CourseAiUtil.testMode()) {
                svc('create#growerp.landing.LandingPage', [ownerPartyId: ownerPartyId,
                    title: "${course.title}".toString(), headline: "Test landing page of ${course.title}".toString(),
                    status: 'DRAFT', ctaActionType: 'url', ctaButtonLink: "/courses/${courseId}".toString(),
                    createdDate: ec.user.nowTimestamp])
            } else {
                String description = "${course.title}: ${course.description ?: ''}".toString()
                if (description.length() > 500) description = description.substring(0, 500)
                if (description.length() < 20) description = "Online course: ${description}".toString()
                svc('growerp.100.LandingPageServices100.generate#LandingPageWithAI',
                    [businessDescription: description, targetAudience: course.audience,
                     courseUrl: "/courses/${courseId}".toString(),
                     courseDescription: "${course.title}\n${course.description ?: ''}\nObjectives:\n${course.objectives ?: ''}\nModules:\n" +
                         modules.collect { "- ${it.title}: ${it.description ?: ''}" }.join('\n')])
            }
        }
    }

    // the course media generator writes one platform at a time, as DRAFT course media
    Map platforms = [:]
    if ('EMAIL' in parts) platforms.EMAIL = 'email sequence'
    if ('SOCIAL' in parts) { platforms.LINKEDIN = 'LinkedIn post'; platforms.TWITTER = 'X post' }
    platforms.eachWithIndex { platform, label, int index ->
        progress((int) (45 + 50 * index / platforms.size()), "Writing the ${label}")
        attempt(label) {
            if (CourseAiUtil.testMode()) {
                svc('create#growerp.course.CourseMedia', [ownerPartyId: ownerPartyId, courseId: courseId,
                    platform: platform, mediaType: platform == 'EMAIL' ? 'SEQUENCE' : 'POST',
                    title: "Test ${label} of ${course.title}".toString(),
                    generatedContent: "Test ${label}.".toString(), status: 'DRAFT',
                    createdDate: ec.user.nowTimestamp, lastModifiedDate: ec.user.nowTimestamp])
            } else {
                svc('growerp.100.CourseServices100.generate#CourseMedia', [courseId: courseId, platform: platform])
            }
        }
    }

    if (!made) throw new Exception("Nothing could be made: ${failed.join(', ')}")
    return "Promo ready: ${made.join(', ')}" + (failed ? "; failed (try again): ${failed.join(', ')}" : '')
}

try {
    String doneMessage
    switch (job.jobType) {
        case 'OUTLINE': doneMessage = runOutline(); break
        case 'LESSONS': doneMessage = runLessons(); break
        case 'QUIZ': doneMessage = runQuiz(); break
        case 'SLIDES': doneMessage = runSlides(); break
        case 'VIDEO': doneMessage = runVideo(); break
        case 'PROMO': doneMessage = runPromo(); break
        case 'EXERCISE': doneMessage = runExercise(); break
        case 'TRANSLATE': doneMessage = runTranslate(); break
        case 'REVIEW': doneMessage = runReview(); break
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
