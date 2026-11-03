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
package org.moqui.adk

import groovy.transform.ThreadInterrupt
import groovy.transform.TimedInterrupt
import org.codehaus.groovy.ast.ClassNode
import org.codehaus.groovy.ast.CodeVisitorSupport
import org.codehaus.groovy.ast.ModuleNode
import org.codehaus.groovy.ast.Parameter
import org.codehaus.groovy.ast.expr.*
import org.codehaus.groovy.ast.stmt.*
import org.codehaus.groovy.control.CompilationUnit
import org.codehaus.groovy.control.CompilerConfiguration
import org.codehaus.groovy.control.Phases
import org.codehaus.groovy.control.customizers.ASTTransformationCustomizer
import org.codehaus.groovy.control.customizers.SecureASTCustomizer
import org.codehaus.groovy.runtime.InvokerHelper
import org.moqui.context.ExecutionContext
import org.moqui.impl.actions.XmlAction
import org.moqui.impl.context.ExecutionContextFactoryImpl
import org.moqui.util.ContextBinding
import org.moqui.util.ContextStack
import org.moqui.util.MNode
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import java.security.MessageDigest
import java.sql.Timestamp
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeoutException

/**
 * Program mode of an agent: a Moqui XML-actions program, generated once by an LLM from the
 * agent's instruction, that scheduled and test runs execute instead of an LLM run.
 *
 * A company admin may write or change the program, so it runs in a sandbox:
 * <ul>
 * <li>validate: only a small set of XML elements; every Groovy expression in an attribute is
 *     parsed and checked against a whitelist (no ec/context, no classes, constructors or
 *     static calls, only listed method names); service names are literals the agent may call.</li>
 * <li>every service-call is rewritten to {@link #GOVERNED_SERVICE}, which passes the call
 *     through the agent's governance gate (tool mode, allowlist, write policy, approvals,
 *     tenant pinning, audit log) before it runs as the company's AI agent user.</li>
 * <li>the generated Groovy is compiled by its own class loader with a SecureASTCustomizer and a
 *     time limit, and runs in an isolated variable scope.</li>
 * </ul>
 */
class AdkProgram {
    protected final static Logger logger = LoggerFactory.getLogger(AdkProgram.class)

    static final String GOVERNED_SERVICE = 'AdkProgramServices.call#GovernedService'
    static final long TIME_LIMIT_SECONDS = 60
    /** bytes a run may allocate (service calls included) before the watchdog stops it */
    static final long MEMORY_LIMIT_BYTES = 256L * 1024L * 1024L
    /** checked after every <set>: a value doubled in a loop stops here */
    static final int MAX_TEXT_LENGTH = 1_000_000
    static final int MAX_LIST_SIZE = 100_000

    /** element name → allowed attributes */
    static final Map<String, Set<String>> ELEMENTS = [
            'actions'        : [] as Set,
            'set'            : ['field', 'from', 'value', 'default-value', 'type', 'set-if-empty'] as Set,
            'if'             : ['condition'] as Set,
            'then'           : [] as Set,
            'else-if'        : ['condition'] as Set,
            'else'           : [] as Set,
            'iterate'        : ['list', 'entry', 'key'] as Set,
            'break'          : [] as Set,
            'continue'       : [] as Set,
            'service-call'   : ['name', 'in-map', 'out-map'] as Set,
            'order-map-list' : ['list'] as Set,
            'order-by'       : ['field-name'] as Set,
            'filter-map-list': ['list', 'to-list'] as Set,
            'field-map'      : ['field-name', 'from', 'value'] as Set,
            'return'         : ['error', 'message'] as Set,
            'check-errors'   : [] as Set,
    ]
    /** element → the parents it may appear in (others: any allowed element) */
    static final Map<String, Set<String>> PARENTS = [
            'then'     : ['if'] as Set,
            'else-if'  : ['if'] as Set,
            'else'     : ['if'] as Set,
            'order-by' : ['order-map-list'] as Set,
            'field-map': ['filter-map-list'] as Set,
    ]
    static final Set<String> EXPRESSION_ATTRS = ['set@from', 'if@condition', 'else-if@condition', 'iterate@list',
            'service-call@in-map', 'order-map-list@list', 'filter-map-list@list', 'field-map@from'] as Set
    static final Set<String> TEXT_ATTRS = ['set@value', 'set@default-value', 'field-map@value', 'return@message'] as Set
    static final Set<String> NAME_ATTRS = ['iterate@entry', 'iterate@key', 'service-call@out-map',
            'filter-map-list@to-list', 'field-map@field-name'] as Set

    static final Set<String> SET_TYPES = ['String', 'Integer', 'Long', 'BigDecimal', 'Double', 'Boolean',
            'Timestamp', 'Date', 'List', 'Map', 'Set'] as Set
    static final Set<String> CAST_TYPES = SET_TYPES + (['int', 'long', 'double', 'boolean'] as Set)
    /** methods an expression may call; nothing that runs code, reflects or changes state */
    static final Set<String> METHODS = ['size', 'isEmpty', 'findAll', 'find', 'any', 'every', 'collect',
            'collectEntries', 'groupBy', 'countBy', 'count', 'sum', 'max', 'min', 'sort',
            'toSorted', 'reverse', 'take', 'drop', 'first', 'last', 'unique', 'toUnique', 'join', 'inject',
            'subList', 'contains', 'containsKey', 'get', 'keySet', 'values', 'entrySet',
            'startsWith', 'endsWith', 'toUpperCase', 'toLowerCase', 'trim', 'substring', 'replace', 'split',
            'indexOf', 'length', 'plus', 'minus', 'div', 'abs', 'round',
            'setScale', 'intValue', 'longValue', 'toString', 'compareTo', 'equals', 'before', 'after',
            'getTime', 'isNumber', 'toBigDecimal', 'toInteger', 'toLong', 'asBoolean'] as Set
    /** functions the runner provides (see {@link #helpers}) */
    static final Set<String> HELPERS = ['daysAgo', 'toTimestamp', 'formatDate', 'formatNumber', 'times'] as Set
    static final Set<String> DENIED_NAMES = ['ec', 'context', 'result', 'binding', 'out', 'args', 'this', 'super',
            'metaClass', 'delegate', 'owner', 'thisObject', 'class', 'declaringClass', 'classLoader',
            'properties', 'protectionDomain', 'call_service_result', 'find_one_result'] as Set
    static final Set<String> ASSIGN_OPS = ['=', '+=', '-=', '*=', '/=', '%=', '**=', '<<=', '>>=', '>>>=',
            '&=', '|=', '^=', '?=', '=~', '==~'] as Set
    /** 'x' * 1000000000 or [1] * 1000000000 fills the memory: multiply only numbers, with times() */
    static final Set<String> MULTIPLY_OPS = ['*', '**'] as Set

    static final String NAME_RX = /[a-z][A-Za-z0-9_]*/
    static final String READ_VERBS_RX = /^(get|find|search|view|list|check|calculate|validate|count|export)$/

    /** compiled program classes by sha256 of the rewritten program */
    private static final Map<String, Class> compiled = Collections.synchronizedMap(
            new LinkedHashMap<String, Class>(64, 0.75f, true) {
                protected boolean removeEldestEntry(Map.Entry e) { size() > 200 }
            })
    /** active runs by id, read by the governed service call */
    private static final Map<String, Map> runs = new ConcurrentHashMap<>()

    // ── validate ─────────────────────────────────────────────────────────────

    /**
     * Check a program against the sandbox rules and the agent's tool access.
     * @return [issues: [level, field, message]..., rewritten: the program with every service-call
     *         routed through the governance gate, null when there are errors]
     */
    static Map validate(ExecutionContext ec, String programText, String toolMode, String serviceAllowlist,
                        String writePolicy) {
        List<Map> issues = []
        Closure err = { String m -> issues << [level: 'error', field: 'programText', message: m] }
        if (!programText?.trim()) { err('The program is empty.'); return [issues: issues] }
        if (programText.contains('\\')) { err('The program may not contain a backslash.'); return [issues: issues] }
        MNode root
        try { root = MNode.parseText('agentProgram', programText) }
        catch (Throwable t) { err("The program is not valid XML: ${t.message}"); return [issues: issues] }
        if (root?.getName() != 'actions') { err('The program must start with <actions>.'); return [issues: issues] }

        int[] serviceCalls = [0]
        checkNode(ec, root, null, toolMode ?: 'readOnly', serviceAllowlist ?: '', writePolicy ?: 'approve',
                err, serviceCalls)
        if (serviceCalls[0] == 0) err('The program calls no service.')
        if (issues) return [issues: issues]

        String rewritten = rewrite(root)
        try { compile(ec, rewritten) }
        catch (Throwable t) { err("The program does not compile: ${t.message?.take(300)}") }
        return [issues: issues, rewritten: issues ? null : rewritten]
    }

    private static void checkNode(ExecutionContext ec, MNode node, MNode parent, String toolMode,
                                  String allowlist, String writePolicy, Closure err, int[] serviceCalls) {
        String name = node.getName()
        Set<String> allowedAttrs = ELEMENTS[name]
        if (allowedAttrs == null) { err("<${name}> is not allowed in a program."); return }
        if (PARENTS[name] && !PARENTS[name].contains(parent?.getName())) {
            err("<${name}> is not allowed inside <${parent?.getName()}>."); return
        }
        if (node.getText()?.trim()) err("<${name}> may not contain text; put values in attributes.")
        node.getAttributes().each { String attr, String value ->
            String key = "${name}@${attr}"
            if (!allowedAttrs.contains(attr)) { err("<${name}> has no attribute ${attr} in a program."); return }
            if (EXPRESSION_ATTRS.contains(key)) checkExpression(value, key).each { err(it) }
            else if (TEXT_ATTRS.contains(key)) checkText(value, key).each { err(it) }
            else if (NAME_ATTRS.contains(key)) { if (!isName(value)) err("${key} '${value}' must be a plain name.") }
        }
        switch (name) {
            case 'set':
                String field = node.attribute('field')
                if (!field || !(field ==~ /${NAME_RX}(\.[A-Za-z][A-Za-z0-9_]*)*/) ||
                        field.split(/\./).any { DENIED_NAMES.contains(it) })
                    err("set@field '${field}' must be a plain name like total or row.total.")
                if (node.attribute('type') && !SET_TYPES.contains(node.attribute('type')))
                    err("set@type must be one of ${SET_TYPES.join(', ')}.")
                if (node.attribute('set-if-empty') && !(node.attribute('set-if-empty') in ['true', 'false']))
                    err('set@set-if-empty must be true or false.')
                break
            case 'iterate':
                if (!node.attribute('list') || !node.attribute('entry')) err('<iterate> needs list and entry.')
                break
            case 'order-by':
                if (!(node.attribute('field-name') ==~ /[+-]?[A-Za-z][A-Za-z0-9_]*/))
                    err("order-by@field-name '${node.attribute('field-name')}' must be a field name, optionally with - for descending.")
                break
            case 'return':
                if (node.attribute('error') && !(node.attribute('error') in ['true', 'false']))
                    err('return@error must be true or false.')
                break
            case 'service-call':
                serviceCalls[0]++
                checkService(ec, node.attribute('name'), toolMode, allowlist, writePolicy, err)
                break
        }
        node.getChildren().each { checkNode(ec, it, node, toolMode, allowlist, writePolicy, err, serviceCalls) }
    }

    private static boolean isName(String value) {
        return value && value ==~ NAME_RX && !DENIED_NAMES.contains(value)
    }

    private static void checkService(ExecutionContext ec, String serviceName, String toolMode, String allowlist,
                                     String writePolicy, Closure err) {
        if (!serviceName || !(serviceName ==~ /growerp\.[A-Za-z0-9_.]+#[A-Za-z0-9_]+/)) {
            err("Service '${serviceName}' is not a growerp.* service name."); return
        }
        if (!ec.service.isServiceDefined(serviceName)) { err("Service '${serviceName}' does not exist."); return }
        String verb = ec.service.getServiceDefinition(serviceName)?.verb ?: serviceName.substring(0, serviceName.indexOf('#'))
        boolean write = !(verb ==~ READ_VERBS_RX)
        if (write && toolMode == 'readOnly') err("The agent is read-only, so the program may not call ${serviceName}.")
        else if (write && writePolicy == 'block') err("Writes are blocked for this agent, so the program may not call ${serviceName}.")
        else if (toolMode == 'scoped' && !matchesAllowlist(serviceName, allowlist))
            err("'${serviceName}' is not in this agent's allowed-service list.")
    }

    static boolean matchesAllowlist(String serviceName, String allowlist) {
        return (allowlist ?: '').split(/[,\s]+/).findAll { it }.any { String g ->
            // quote the literal parts, '*' → '.*' (quoting the whole glob would keep '*' literal)
            def rx = '^' + g.split(/\*/, -1).collect { it ? java.util.regex.Pattern.quote(it) : '' }.join('.*') + '$'
            serviceName ==~ rx
        }
    }

    /** Problems of one Groovy expression, empty when it passes the whitelist. */
    static List<String> checkExpression(String source, String where) {
        if (!source?.trim()) return ["${where} is empty.".toString()]
        ModuleNode module
        try {
            CompilationUnit cu = new CompilationUnit(new CompilerConfiguration())
            cu.addSource('AdkProgramExpression', source)
            cu.compile(Phases.CONVERSION)
            module = cu.getAST().getModules()[0]
        } catch (Throwable t) {
            return ["${where} is not a valid expression: ${source.take(80)}".toString()]
        }
        if (module.getImports() || module.getStarImports() || module.getStaticImports() ||
                module.getStaticStarImports() || module.getMethods() || module.getClasses().size() > 1)
            return ["${where} may only hold an expression.".toString()]
        List<Statement> statements = module.getStatementBlock().getStatements()
        if (statements.size() != 1 || !(statements[0] instanceof ExpressionStatement))
            return ["${where} must be one expression.".toString()]
        ExpressionChecker checker = new ExpressionChecker()
        statements[0].visit(checker)
        return checker.problems.unique().collect { "${where}: ${it}".toString() }
    }

    /** Problems of a text attribute, which Moqui evaluates as a Groovy GString. */
    static List<String> checkText(String text, String where) {
        if (text == null) return []
        if (text.contains('"""') || text.contains("'''") || text.endsWith('"'))
            return ["${where} may not contain triple quotes or end with a quote.".toString()]
        if (!text.contains('$')) return []
        return checkExpression('"""' + text + '"""', where)
    }

    /** Whitelist walk over a parsed expression. */
    static class ExpressionChecker extends CodeVisitorSupport {
        List<String> problems = []
        void bad(String m) { problems << m }

        @Override void visitMethodCallExpression(MethodCallExpression call) {
            String name = call.getMethodAsString()
            if (name == null) { bad('a computed method name is not allowed'); return }
            if (call.isImplicitThis()) {
                if (!HELPERS.contains(name)) bad("function ${name}() is not available (use ${HELPERS.join(', ')})")
                call.getArguments().visit(this)
                return
            }
            if (!METHODS.contains(name)) bad("method ${name}() is not allowed")
            super.visitMethodCallExpression(call)
        }
        @Override void visitStaticMethodCallExpression(StaticMethodCallExpression call) { bad("static call ${call.getMethod()} is not allowed") }
        @Override void visitConstructorCallExpression(ConstructorCallExpression call) { bad('new objects are not allowed') }
        @Override void visitClassExpression(ClassExpression expression) { bad("class ${expression.getType().getName()} is not allowed") }
        @Override void visitAttributeExpression(AttributeExpression expression) { bad('.@ field access is not allowed') }
        @Override void visitMethodPointerExpression(MethodPointerExpression expression) { bad('method pointers are not allowed') }
        @Override void visitMethodReferenceExpression(MethodReferenceExpression expression) { bad('method references are not allowed') }
        @Override void visitLambdaExpression(LambdaExpression expression) { bad('lambdas are not allowed, use a closure') }
        @Override void visitRangeExpression(RangeExpression expression) { bad('ranges are not allowed') }
        @Override void visitDeclarationExpression(DeclarationExpression expression) { bad('declarations are not allowed, use <set>') }
        @Override void visitArrayExpression(ArrayExpression expression) { bad('arrays are not allowed') }
        @Override void visitPrefixExpression(PrefixExpression expression) { bad('++ and -- are not allowed') }
        @Override void visitPostfixExpression(PostfixExpression expression) { bad('++ and -- are not allowed') }

        @Override void visitVariableExpression(VariableExpression expression) {
            String name = expression.getName()
            if (DENIED_NAMES.contains(name) || name.startsWith('_') || Character.isUpperCase(name.charAt(0)))
                bad("${name} is not available in a program")
        }
        @Override void visitPropertyExpression(PropertyExpression expression) {
            String name = expression.getPropertyAsString()
            if (name == null) bad('a computed property name is not allowed')
            else if (DENIED_NAMES.contains(name) || name.startsWith('_')) bad("property ${name} is not allowed")
            super.visitPropertyExpression(expression)
        }
        @Override void visitBinaryExpression(BinaryExpression expression) {
            String op = expression.getOperation().getText()
            if (ASSIGN_OPS.contains(op)) bad("operator ${op} is not allowed, use <set>")
            if (MULTIPLY_OPS.contains(op)) bad("operator ${op} is not allowed, use times(a, b)")
            if (op == '[' && expression.getRightExpression() instanceof ConstantExpression &&
                    DENIED_NAMES.contains((expression.getRightExpression() as ConstantExpression).getValue() as String))
                bad('this key is not allowed')
            super.visitBinaryExpression(expression)
        }
        @Override void visitCastExpression(CastExpression expression) {
            if (!CAST_TYPES.contains(expression.getType().getName())) bad("conversion to ${expression.getType().getName()} is not allowed")
            super.visitCastExpression(expression)
        }
        @Override void visitClosureExpression(ClosureExpression expression) {
            (expression.getParameters() ?: [] as Parameter[]).each { Parameter p ->
                if (!p.isDynamicTyped() && !CAST_TYPES.contains(p.getType().getName()))
                    bad("closure parameter type ${p.getType().getName()} is not allowed")
                if (DENIED_NAMES.contains(p.getName()) || p.getName().startsWith('_')) bad("closure parameter ${p.getName()} is not allowed")
            }
            super.visitClosureExpression(expression)
        }
        @Override void visitForLoop(ForStatement s) { bad('loops are not allowed, use <iterate>') }
        @Override void visitWhileLoop(WhileStatement s) { bad('loops are not allowed, use <iterate>') }
        @Override void visitDoWhileLoop(DoWhileStatement s) { bad('loops are not allowed, use <iterate>') }
        @Override void visitTryCatchFinally(TryCatchStatement s) { bad('try/catch is not allowed') }
        @Override void visitThrowStatement(ThrowStatement s) { bad('throw is not allowed') }
        @Override void visitSynchronizedStatement(SynchronizedStatement s) { bad('synchronized is not allowed') }
        @Override void visitSwitch(SwitchStatement s) { bad('switch is not allowed') }
        @Override void visitAssertStatement(AssertStatement s) { bad('assert is not allowed') }
    }

    // ── rewrite + compile ────────────────────────────────────────────────────

    /** The program as XML with every service-call routed through the governance gate. */
    static String rewrite(MNode root) {
        StringBuilder sb = new StringBuilder()
        int[] counter = [0]
        writeNode(root, sb, counter)
        return sb.toString()
    }

    private static void writeNode(MNode node, StringBuilder sb, int[] counter) {
        if (node.getName() == 'service-call') {
            String n = "__adkOut${++counter[0]}"
            String inMap = node.attribute('in-map') ?: '[:]'
            sb.append('<service-call name="').append(GOVERNED_SERVICE).append('" in-map="')
              .append(xmlEscape("[runId: __adkRunId, serviceName: '${node.attribute('name')}', inMap: (${inMap})]"))
              .append('" out-map="').append(n).append('"/>')
            if (node.attribute('out-map'))
                sb.append('<set field="').append(node.attribute('out-map')).append('" from="').append(n).append('?.result"/>')
            return
        }
        if (node.getName() == 'set') {
            sb.append('<set')
            node.getAttributes().each { String k, String v -> sb.append(' ').append(k).append('="').append(xmlEscape(v)).append('"') }
            sb.append('/><set field="__adkSize" from="__adkCheckSize(').append(node.attribute('field').split(/\./)[0]).append(')"/>')
            return
        }
        sb.append('<').append(node.getName())
        node.getAttributes().each { String k, String v ->
            // the template appends .iterator() etc.: rows ?: [] must stay one expression
            if (k == 'list') v = "(${v})"
            sb.append(' ').append(k).append('="').append(xmlEscape(v)).append('"')
        }
        sb.append('>')
        node.getChildren().each { writeNode(it, sb, counter) }
        sb.append('</').append(node.getName()).append('>')
    }

    private static String xmlEscape(String v) {
        return (v ?: '').replace('&', '&amp;').replace('"', '&quot;').replace('<', '&lt;').replace('>', '&gt;')
    }

    /** Compile a rewritten program in its own class loader: SecureASTCustomizer + time limit. */
    static Class compile(ExecutionContext ec, String rewritten) {
        String key = sha256(rewritten)
        Class cls = compiled.get(key)
        if (cls != null) return cls
        ExecutionContextFactoryImpl ecfi = (ExecutionContextFactoryImpl) ec.factory
        String groovy = new XmlAction(ecfi, rewritten, 'adkProgram').getGroovyString()

        SecureASTCustomizer secure = new SecureASTCustomizer()
        secure.setPackageAllowed(false)
        secure.setMethodDefinitionAllowed(false)
        // exactly the imports of XmlActions.groovy.ftl
        secure.setAllowedImports(['java.sql.Timestamp', 'java.sql.Time'])
        secure.setAllowedStarImports(['java.time.'])
        secure.setAllowedStaticImports([])
        secure.setAllowedStaticStarImports(['org.moqui.util.ObjectUtilities', 'org.moqui.util.CollectionUtilities',
                                            'org.moqui.util.StringUtilities'])
        secure.setDisallowedReceivers(['java.lang.System', 'java.lang.Runtime', 'java.lang.Class',
                'java.lang.ClassLoader', 'java.lang.Thread', 'java.lang.ProcessBuilder', 'java.lang.Process',
                'java.io.File', 'java.nio.file.Files', 'java.nio.file.Paths', 'groovy.lang.GroovyShell',
                'groovy.util.Eval', 'groovy.lang.GroovyClassLoader', 'groovy.lang.Script'])
        CompilerConfiguration conf = new CompilerConfiguration()
        conf.addCompilationCustomizers(secure,
                new ASTTransformationCustomizer([value: TIME_LIMIT_SECONDS], TimedInterrupt),
                // lets the memory watchdog (see run) stop the program at the next loop or closure
                new ASTTransformationCustomizer(ThreadInterrupt))
        GroovyClassLoader loader = new GroovyClassLoader(ecfi.getGroovyClassLoader(), conf)
        cls = loader.parseClass(groovy, 'AdkProgram_' + key.take(16))
        compiled.put(key, cls)
        return cls
    }

    private static String sha256(String text) {
        MessageDigest.getInstance('SHA-256').digest(text.getBytes('UTF-8')).encodeHex().toString()
    }

    // ── generate ─────────────────────────────────────────────────────────────

    static final String SAMPLE_PROGRAM = '''<actions>
    <service-call name="growerp.100.CrmServices100.get#Opportunity" in-map="[limit: 200]" out-map="found"/>
    <set field="stale" from="(found.opportunities ?: []).findAll { toTimestamp(it.lastUpdated) &lt; daysAgo(staleDays) }"/>
    <if condition="!stale">
        <set field="report" value="No stale deals."/>
        <return/>
    </if>
    <order-map-list list="stale"><order-by field-name="-estAmount"/></order-map-list>
    <set field="lines" from="['**Stale deals** (no update for ' + staleDays + ' days)']"/>
    <iterate list="stale" entry="opp">
        <set field="lines" from="lines + ['- ' + opp.opportunityName + ': ' + formatNumber(opp.estAmount) + ', last update ' + formatDate(opp.lastUpdated)]"/>
    </iterate>
    <set field="report" from="lines.join(nl)"/>
</actions>'''

    /** The services a generated program may use: allowlist matches plus names in the instruction. */
    static List<String> programServices(ExecutionContext ec, Map cfg) {
        Set<String> names = new LinkedHashSet<>()
        ((cfg.instruction ?: '') as String).findAll(/growerp\.[A-Za-z0-9_.]+#[A-Za-z0-9_]+/).each { names << (it as String) }
        if (cfg.toolMode == 'scoped' && cfg.serviceAllowlist) {
            // a scan of all service files: fine for a one-time generation
            Set all = ec.service.getKnownServiceNames().findAll { it?.startsWith('growerp.') } as Set
            all.findAll { matchesAllowlist(it as String, cfg.serviceAllowlist as String) }?.sort()?.each { names << (it as String) }
        }
        return names.findAll { ec.service.isServiceDefined(it) }.take(15) as List<String>
    }

    /** One service's parameters for the generation prompt, two levels deep. */
    static String describeService(ExecutionContext ec, String serviceName) {
        def sd = ec.service.getServiceDefinition(serviceName)
        if (sd == null) return "${serviceName}: (not found)"
        Closure describe
        describe = { MNode p, int depth ->
            List<MNode> kids = p.children('parameter')
            String type = p.attribute('type')
            // a List with one Map parameter holds rows: the row fields are read as row.field
            if (type == 'List' && kids.size() == 1 && kids[0].attribute('type') == 'Map') {
                kids = kids[0].children('parameter')
                type = 'list of rows'
            }
            String s = p.attribute('name') + (type ? ':' + type : '') + (p.attribute('required') == 'true' ? '*' : '')
            if (kids && depth < 2) s += ' {' + kids.collect { describe(it, depth + 1) }.join(', ') + '}'
            s
        }
        String ins = sd.getInParameterNames().collect { describe(sd.getInParameter(it), 0) }.join(', ')
        String outs = sd.getOutParameterNames().collect { describe(sd.getOutParameter(it), 0) }.join(', ')
        return "${serviceName}\n  in: ${ins ?: '-'}\n  out: ${outs ?: '-'}"
    }

    static String generationPrompt(ExecutionContext ec, Map cfg, List<String> services) {
        String params = parameterValues(cfg.parameters as String, null).collect { k, v -> "${k} (default ${v})" }.join(', ')
        return """You write a Moqui XML-actions program that does the task below without an AI. It runs on a schedule; the text it sets in the variable report is posted to a chat room.

TASK (the agent's instruction):
${cfg.instruction ?: ''}

SCHEDULED-RUN PROMPT: ${cfg.schedulePrompt ?: '-'}
INPUT PARAMETERS (available as variables with these names): ${params ?: 'none'}

SERVICES the program may call (name, in-parameters, out-parameters; * = required, {..} = fields of list rows or map entries):
${services.collect { describeService(ec, it) }.join('\n')}

RULES
- Answer with the program only, starting with <actions> and ending with </actions>. No markdown fences, no comments.
- Elements: ${ELEMENTS.collect { k, v -> v ? "${k} (${v.join(', ')})" : k }.join('; ')}.
  field-map only inside filter-map-list; order-by only inside order-map-list; then/else-if/else only inside if.
- service-call: name must be one of the services above, parameters in in-map as a Groovy map, the result map in out-map.
  A write that needs approval returns [approvalPending: true]; a test run returns [simulated: true] for writes.
- Attributes from, condition, list and in-map are Groovy expressions. value, default-value and message are text with \${...}.
  Allowed in expressions: literals, list and map literals, variables, property access, + - * / comparisons, && || !, ?:, ?., closures,
  and only these methods: ${METHODS.join(', ')}.
  Functions: daysAgo(days) gives a Timestamp; toTimestamp(value); formatDate(value, pattern='yyyy-MM-dd'); formatNumber(value, decimals=2);
  times(a, b) multiplies two numbers (the * operator is not allowed).
  Variables: parameters (map), each input parameter by name, now (Timestamp), today (LocalDate), nl (a new line).
- Not allowed: new, classes, static calls, assignments (use <set>), ++, * and **, loops (use <iterate>), ranges, backslashes, names starting with _ or a capital.
- Write &lt; for <, &gt; for >, &amp;&amp; for &&. Use nl for new lines, never a backslash.
- Collect lines in a list with <set field="lines" from="lines + [...]"/> and finish with <set field="report" from="lines.join(nl)"/>; report is markdown.
- When there is nothing to report, still set report to a short sentence.

EXAMPLE (another task):
${SAMPLE_PROGRAM}
"""
    }

    /**
     * Let an LLM write the program for an agent: up to three tries, each checked by
     * {@link #validate}; the problems of a try go back to the LLM.
     * @param llm closure(prompt) → the LLM's answer
     * @return [programText, issues, attempts]
     */
    static Map generate(ExecutionContext ec, Map cfg, Closure llm) {
        List<String> services = programServices(ec, cfg)
        if (!services)
            return [issues: [[level: 'error', field: 'programText',
                    message: 'Name the services the program may use in the instruction, or use Scoped tool access with an allowed-service list.']]]
        String prompt = generationPrompt(ec, cfg, services)
        String programText = null
        List<Map> issues = []
        int attempts = 0
        while (attempts < 3) {
            attempts++
            String answer = (llm.call(prompt) ?: '') as String
            int s = answer.indexOf('<actions'), e = answer.lastIndexOf('</actions>')
            programText = (s >= 0 && e > s) ? answer.substring(s, e + '</actions>'.length()) : answer.trim()
            issues = validate(ec, programText, cfg.toolMode as String, cfg.serviceAllowlist as String,
                    cfg.writePolicy as String).issues as List<Map>
            if (!issues) break
            prompt += "\n\nYOUR PREVIOUS PROGRAM:\n${programText}\n\nIT HAS THESE PROBLEMS, fix them and answer with the whole program again:\n" +
                    issues.collect { '- ' + it.message }.join('\n')
        }
        return [programText: programText, issues: issues, attempts: attempts]
    }

    // ── run ──────────────────────────────────────────────────────────────────

    /** Functions a program can call, see {@link #HELPERS}. */
    static Map<String, Closure> helpers() {
        return [
                daysAgo     : { Object days -> new Timestamp(System.currentTimeMillis() - (days as long) * 86400000L) },
                toTimestamp : { Object v ->
                    if (v == null || v instanceof Timestamp) return v
                    if (v instanceof Date) return new Timestamp(((Date) v).getTime())
                    if (v instanceof Number) return new Timestamp(((Number) v).longValue())
                    String s = v.toString().trim()
                    if (!s) return null
                    if (s ==~ /\d{4}-\d{2}-\d{2}/) s += ' 00:00:00'
                    return Timestamp.valueOf(s.replace('T', ' ').replaceAll(/Z$/, '').replaceAll(/[+-]\d{2}:?\d{2}$/, ''))
                },
                formatDate  : { Object v, String pattern = 'yyyy-MM-dd' ->
                    def ts = helpers().toTimestamp.call(v)
                    ts ? new java.text.SimpleDateFormat(pattern).format(ts) : ''
                },
                times       : { Object a, Object b ->
                    a == null || b == null ? null : new BigDecimal(a.toString()).multiply(new BigDecimal(b.toString()))
                },
                formatNumber: { Object v, Integer decimals = 2 ->
                    v == null ? '' : new BigDecimal(v.toString()).setScale(decimals, java.math.RoundingMode.HALF_UP).toPlainString()
                },
        ]
    }

    /** Input parameter values for a run: defaults, overridden by the given ones unless fixed. */
    static Map<String, Object> parameterValues(String parametersJson, Map overrides) {
        Map<String, Object> values = [:]
        if (parametersJson?.trim()) {
            try {
                (new groovy.json.JsonSlurper().parseText(parametersJson) as List).each { p ->
                    if (!(p instanceof Map) || !p.name) return
                    String n = p.name as String
                    values[n] = (!p.fixed && overrides?.containsKey(n)) ? overrides[n] : p.value
                }
            } catch (Exception e) { logger.warn("Agent parameters are not valid JSON: ${e.message}") }
        }
        overrides?.each { k, v -> if (!values.containsKey(k)) values[k as String] = v }
        return values
    }

    /**
     * Run an agent's program as the company's AI agent user.
     * @return [status: done|failed, resultText, error, toolCalls, durationMs]
     */
    static Map run(ExecutionContext ec, Map cfg, boolean dryRun, Map overrides) {
        long start = System.currentTimeMillis()
        Map out = [status: 'failed', toolCalls: [], llmCalls: 0, tokensTotal: 0, dryRun: dryRun]
        Map v = validate(ec, cfg.programText as String, cfg.toolMode as String, cfg.serviceAllowlist as String,
                cfg.writePolicy as String)
        if (!v.rewritten) {
            out.error = (v.issues*.message).join(' ')
            out.durationMs = System.currentTimeMillis() - start
            return out
        }
        String runId = UUID.randomUUID().toString()
        // allocated by finished service calls, and where a running call started (-1: none)
        java.util.concurrent.atomic.AtomicLong serviceBytes = new java.util.concurrent.atomic.AtomicLong()
        java.util.concurrent.atomic.AtomicLong callStart = new java.util.concurrent.atomic.AtomicLong(-1L)
        runs[runId] = [configId: cfg.adkAgentConfigId, dryRun: dryRun, toolCalls: out.toolCalls,
                       serviceBytes: serviceBytes, callStart: callStart]
        boolean pushed = false
        try {
            Class cls = compile(ec, v.rewritten as String)
            Map au = ec.service.sync().name('AdkGovernanceServices.ensure#AgentUser')
                    .parameters([ownerPartyId: cfg.ownerPartyId, adkAgentConfigId: cfg.adkAgentConfigId])
                    .requireNewTransaction(true).disableAuthz().call()
            if (!au?.agentUsername || ec.message.hasError())
                throw new IllegalStateException("No AI agent user for company ${cfg.ownerPartyId}")
            pushed = ec.user.internalLoginUser(au.agentUsername as String, false)
            if (!pushed) throw new IllegalStateException("Could not act as agent user ${au.agentUsername}")

            ContextStack cs = new ContextStack()
            cs.put('ec', ec)
            cs.put('__adkRunId', runId)
            helpers().each { k, c -> cs.put(k, c) }
            Map<String, Object> params = parameterValues(cfg.parameters as String, overrides)
            cs.put('parameters', params)
            params.each { k, val -> if (isName(k) && !HELPERS.contains(k)) cs.put(k, val) }
            cs.put('now', new Timestamp(System.currentTimeMillis()))
            cs.put('today', java.time.LocalDate.now())
            cs.put('nl', '\n')
            cs.put('report', null)
            cs.put('__adkCheckSize', { Object value ->
                if (value instanceof CharSequence && ((CharSequence) value).length() > MAX_TEXT_LENGTH)
                    throw new IllegalStateException("A text in the program grew over ${MAX_TEXT_LENGTH} characters.")
                if ((value instanceof Collection && ((Collection) value).size() > MAX_LIST_SIZE) ||
                        (value instanceof Map && ((Map) value).size() > MAX_LIST_SIZE))
                    throw new IllegalStateException("A list in the program grew over ${MAX_LIST_SIZE} entries.")
                return null
            })
            withMemoryWatchdog(out, serviceBytes, callStart) { InvokerHelper.createScript(cls, new ProgramBinding(cs)).run() }

            def report = cs.get('report')
            out.resultText = (report instanceof Collection ? (report as Collection).join('\n') : report?.toString()) ?: ''
            if (ec.message.hasError()) out.error = ec.message.getErrorsString().trim()
            else out.status = 'done'
        } catch (TimeoutException e) {
            logger.warn("Agent program ${cfg.adkAgentConfigId} stopped on its time limit", e)
            out.error = "The program ran longer than ${TIME_LIMIT_SECONDS} seconds and was stopped."
        } catch (Throwable t) {
            // the watchdog's interrupt can surface as InterruptedException or inside a service call
            if (out.overMemory || t instanceof OutOfMemoryError)
                out.error = "The program used more than ${MEMORY_LIMIT_BYTES >> 20} MB and was stopped."
            else {
                logger.warn("Agent program ${cfg.adkAgentConfigId} failed", t)
                out.error = ec.message.hasError() ? ec.message.getErrorsString().trim() : (t.message ?: t.class.simpleName)
            }
        } finally {
            if (pushed) ec.user.popUser()
            runs.remove(runId)
            ec.message.clearErrors()
            out.durationMs = System.currentTimeMillis() - start
        }
        return out
    }

    /** Moqui's binding returns null for any unknown name. Groovy's own names (the TimedInterrupt
     *  expire time read from a closure) must fall back to the script's fields instead. */
    static class ProgramBinding extends ContextBinding {
        private final ContextStack stack
        ProgramBinding(ContextStack stack) { super(stack); this.stack = stack }
        @Override Object getVariable(String name) {
            if (name.contains('$') && !stack.containsKey(name)) throw new MissingPropertyException(name, ProgramBinding)
            return super.getVariable(name)
        }
    }

    /** Bytes the current thread allocated so far, -1 when the JVM can not tell. */
    private static long allocatedBytes() {
        def mx = java.lang.management.ManagementFactory.getThreadMXBean()
        return mx instanceof com.sun.management.ThreadMXBean && ((com.sun.management.ThreadMXBean) mx).isThreadAllocatedMemorySupported() ?
                ((com.sun.management.ThreadMXBean) mx).getThreadAllocatedBytes(Thread.currentThread().getId()) : -1L
    }

    /** Run body; a watchdog interrupts this thread when it allocates more than MEMORY_LIMIT_BYTES. */
    private static void withMemoryWatchdog(Map out, java.util.concurrent.atomic.AtomicLong serviceBytes,
                                           java.util.concurrent.atomic.AtomicLong callStart, Closure body) {
        def mx = java.lang.management.ManagementFactory.getThreadMXBean()
        Thread worker = Thread.currentThread()
        boolean measured = mx instanceof com.sun.management.ThreadMXBean &&
                ((com.sun.management.ThreadMXBean) mx).isThreadAllocatedMemorySupported()
        if (!measured) { body.call(); return }
        com.sun.management.ThreadMXBean amx = (com.sun.management.ThreadMXBean) mx
        long start = amx.getThreadAllocatedBytes(worker.getId())
        boolean[] done = [false]
        Thread watchdog = Thread.startDaemon('adk-program-watchdog') {
            while (!done[0]) {
                // what the called services allocate (and their first-call compile) is not the program's
                long now = amx.getThreadAllocatedBytes(worker.getId())
                long inCall = callStart.get() >= 0 ? now - callStart.get() : 0L
                if (now - start - serviceBytes.get() - inCall > MEMORY_LIMIT_BYTES) {
                    out.overMemory = true
                    worker.interrupt()
                    return
                }
                try { Thread.sleep(10) } catch (InterruptedException ignore) { return }
            }
        }
        try { body.call() }
        finally {
            done[0] = true
            watchdog.interrupt()
            Thread.interrupted() // clear a late interrupt so it does not hit the caller
        }
    }

    /**
     * One service call of a running program: through the governance gate, then executed as the
     * agent user (already logged in by {@link #run}). Errors stop the program.
     * @return the service result; for a held write [approvalPending: true], for a simulated write
     *         [simulated: true]
     */
    static Map callGoverned(ExecutionContext ec, String runId, String serviceName, Map inMap) {
        Map run = runId ? runs[runId] : null
        if (run == null) { ec.message.addError('No agent program is running.'); return null }
        long before = allocatedBytes()
        (run.callStart as java.util.concurrent.atomic.AtomicLong).set(before)
        try { return callGovernedRun(ec, run, serviceName, inMap) }
        finally {
            if (before >= 0) (run.serviceBytes as java.util.concurrent.atomic.AtomicLong).addAndGet(allocatedBytes() - before)
            (run.callStart as java.util.concurrent.atomic.AtomicLong).set(-1L)
        }
    }

    private static Map callGovernedRun(ExecutionContext ec, Map run, String serviceName, Map inMap) {
        Map call = [tool: 'program', service: serviceName,
                    args: groovy.json.JsonOutput.toJson(inMap ?: [:]).take(600)]
        (run.toolCalls as List) << call
        Map gov = ec.service.sync().name('AdkGovernanceServices.govern#AgentAction')
                .parameters([configId: run.configId, toolName: 'program', serviceName: serviceName,
                             parameters: inMap ?: [:], dryRun: run.dryRun, program: true])
                .requireNewTransaction(true).disableAuthz().call()
        if (ec.message.hasError() || gov == null) { call.decision = 'blocked'; return null }
        if (gov.decision == 'blocked') {
            call.decision = 'blocked'
            call.result = gov.message
            ec.message.addError("${serviceName}: ${gov.message}")
            return null
        }
        if (gov.decision == 'pending') {
            call.decision = 'approval'
            call.result = gov.message
            return [approvalPending: true, message: gov.message]
        }
        if (run.dryRun && gov.verbClass == 'write') {
            call.decision = 'simulated'
            call.result = "DRY RUN (test): not executed."
            return [simulated: true]
        }
        Map result = ec.service.sync().name(serviceName).parameters(gov.parameters as Map)
                .requireNewTransaction(true).call()
        if (ec.message.hasError()) {
            call.decision = 'blocked'
            call.result = ec.message.getErrorsString().trim().take(800)
            return null
        }
        String json = groovy.json.JsonOutput.toJson(result ?: [:])
        call.decision = 'ok'
        call.result = json.take(800)
        if (gov.adkActionLogId)
            ec.service.sync().name('AdkGovernanceServices.record#AgentResult')
                    .parameters([adkActionLogId: gov.adkActionLogId, resultSummary: json]).disableAuthz().call()
        return result
    }
}
