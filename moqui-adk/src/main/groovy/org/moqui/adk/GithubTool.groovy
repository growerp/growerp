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
package org.moqui.adk

import com.google.adk.tools.Annotations.Schema
import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import org.slf4j.Logger
import org.slf4j.LoggerFactory


/**
 * ADK FunctionTools for interacting with GitHub Actions CI results and the growerp/growerp repo.
 *
 * Token resolution: GITHUB_TOKEN env var, then growerp.github.token Java system property.
 * All methods are static, run in a background thread (same pattern as EmailTool), and return
 * a Map with success:true/false.
 */
class GithubTool {

    protected static final Logger logger = LoggerFactory.getLogger(GithubTool.class)

    private static final String API_BASE        = 'https://api.github.com'
    private static final String DEFAULT_REPO    = 'growerp/growerp'

    private static String resolveRepo() {
        return System.getenv('GITHUB_REPO') ?:
               System.getProperty('growerp.github.repo') ?:
               DEFAULT_REPO
    }

    private static String resolveGithubToken(String ownerPartyId = null) {
        // 1. Prefer env var or cached system property (fastest, no DB hit)
        String tok = System.getenv('GITHUB_TOKEN') ?: System.getProperty('growerp.github.token') ?: ''
        if (tok) return tok

        // 2. Fall back to DB lookup — scan SystemSettings for any tenant that has a token.
        //    ownerPartyId param is a hint; if not supplied we scan all rows.
        def ecf = AdkManager.sharedSessionService?.ecf
        if (!ecf) return ''
        def ec = ecf.getExecutionContext()
        boolean wasDisabled = false
        try {
            ec.user.internalLoginUser('SystemSupport')
            wasDisabled = ec.artifactExecution.disableAuthz()
            def find = ec.entity.find('growerp.general.SystemSettings')
            if (ownerPartyId) find = find.condition('ownerPartyId', ownerPartyId)
            def rows = find.list()
            for (def row in rows) {
                String t = row.getString('githubToken')
                if (t) {
                    System.setProperty('growerp.github.token', t)  // cache for next call
                    return t
                }
            }
        } catch (Exception e) {
            logger.error("Failed to retrieve githubToken from SystemSettings: ${e.message}", e)
        } finally {
            if (!wasDisabled) ec.artifactExecution.enableAuthz()
            ec.destroy()
        }
        return ''
    }

    private static Map<String, Object> githubGet(String url, String token) {
        try {
            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection()
            conn.setRequestMethod('GET')
            conn.setRequestProperty('Authorization', "Bearer ${token}")
            conn.setRequestProperty('Accept', 'application/vnd.github+json')
            conn.setRequestProperty('X-GitHub-Api-Version', '2022-11-28')
            conn.setConnectTimeout(15_000)
            conn.setReadTimeout(30_000)
            int code = conn.responseCode
            String body = (code < 400 ? conn.inputStream : conn.errorStream)?.text ?: ''
            conn.disconnect()
            return [code: code, body: body,
                    parsed: body ? new JsonSlurper().parseText(body) : null]
        } catch (Exception e) {
            logger.error("GithubTool.githubGet failed for ${url}: ${e.message}", e)
            return [code: -1, body: e.message, parsed: null]
        }
    }

    private static Map<String, Object> githubPost(String url, String token,
                                                    Map payload, String method = 'POST') {
        try {
            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection()
            conn.setRequestMethod(method)
            conn.setRequestProperty('Authorization', "Bearer ${token}")
            conn.setRequestProperty('Accept', 'application/vnd.github+json')
            conn.setRequestProperty('Content-Type', 'application/json')
            conn.setRequestProperty('X-GitHub-Api-Version', '2022-11-28')
            conn.setDoOutput(true)
            conn.setConnectTimeout(15_000)
            conn.setReadTimeout(30_000)
            conn.outputStream.withWriter('UTF-8') { it.write(JsonOutput.toJson(payload)) }
            int code = conn.responseCode
            String body = (code < 400 ? conn.inputStream : conn.errorStream)?.text ?: ''
            conn.disconnect()
            return [code: code, body: body,
                    parsed: body ? new JsonSlurper().parseText(body) : null]
        } catch (Exception e) {
            logger.error("GithubTool.githubPost failed for ${url}: ${e.message}", e)
            return [code: -1, body: e.message, parsed: null]
        }
    }

    @Schema(description = 'Get the latest failed GitHub Actions CI run for the growerp/growerp test workflow. Returns runId, status, conclusion, headCommitAuthor, headCommitEmail, headCommitMessage.')
    static Map<String, Object> getLatestTestRun(
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {
        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                String token = resolveGithubToken(ownerPartyId)
                if (!token) { result[0] = [success: false, error: 'GITHUB_TOKEN not set']; return }

                def resp = githubGet("${API_BASE}/repos/${resolveRepo()}/actions/workflows/test.yml/runs?per_page=5&status=failure", token)
                if (resp.code < 0 || resp.code >= 400) {
                    result[0] = [success: false, error: "GitHub API error ${resp.code}: ${resp.body}"]
                    return
                }

                def runs = resp.parsed?.workflow_runs
                if (!runs) {
                    resp = githubGet("${API_BASE}/repos/${resolveRepo()}/actions/workflows/test.yml/runs?per_page=1&status=completed", token)
                    runs = resp.parsed?.workflow_runs
                }

                if (!runs || runs.isEmpty()) {
                    result[0] = [success: true, runId: null, message: 'No CI runs found']
                    return
                }

                def run = runs[0]
                def commit = run.head_commit
                result[0] = [
                    success          : true,
                    runId            : run.id?.toString(),
                    status           : run.status,
                    conclusion       : run.conclusion,
                    headCommitAuthor : commit?.author?.name ?: '',
                    headCommitEmail  : commit?.author?.email ?: '',
                    headCommitMessage: commit?.message ?: '',
                    runUrl           : run.html_url ?: '',
                ]
            } catch (Exception e) {
                err[0] = e
                logger.error("GithubTool.getLatestTestRun failed: ${e.message}", e)
            }
        }, 'adk-github-latestrun')
        t.start()
        t.join(30_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }

    @Schema(description = 'Get Flutter exceptions from the summarize job log of a CI run. Returns a list of exceptions with exceptionType, message, stackTrace (app frames only), packageSlice.')
    static Map<String, Object> getTestExceptions(
            @Schema(name = 'runId',
                    description = 'GitHub Actions run ID from getLatestTestRun') String runId,
            @Schema(name = 'format',
                    description = 'Test format to filter: mobile or desktop (optional, returns all if blank)') String format,
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {

        if (!runId) return [success: false, error: 'runId is required']

        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                String token = resolveGithubToken(ownerPartyId)
                if (!token) { result[0] = [success: false, error: 'GITHUB_TOKEN not set']; return }

                // Find the summarize job for this run
                def resp = githubGet("${API_BASE}/repos/${resolveRepo()}/actions/runs/${runId}/jobs?per_page=50", token)
                if (resp.code < 0 || resp.code >= 400) {
                    result[0] = [success: false, error: "Jobs list error ${resp.code}: ${resp.body}"]
                    return
                }

                def jobs = resp.parsed?.jobs ?: []
                def summarizeJob = jobs.find { it.name == 'summarize' }
                if (!summarizeJob) {
                    result[0] = [success: false,
                                 error: "No 'summarize' job found in run ${runId}. Jobs: ${jobs.collect { it.name }.join(', ')}"]
                    return
                }

                long jobId = summarizeJob.id as long

                // Job log endpoint returns 302 redirect to plain-text log
                HttpURLConnection step1 = (HttpURLConnection) new URL("${API_BASE}/repos/${resolveRepo()}/actions/jobs/${jobId}/logs").openConnection()
                step1.setRequestMethod('GET')
                step1.setRequestProperty('Authorization', "Bearer ${token}")
                step1.setRequestProperty('Accept', 'application/vnd.github+json')
                step1.setRequestProperty('X-GitHub-Api-Version', '2022-11-28')
                step1.setInstanceFollowRedirects(false)
                step1.setConnectTimeout(15_000)
                step1.setReadTimeout(15_000)
                step1.connect()
                String redirectUrl = step1.getHeaderField('Location')
                step1.disconnect()

                if (!redirectUrl) {
                    result[0] = [success: false, error: "No redirect for job log ${jobId}. HTTP ${step1.responseCode}"]
                    return
                }

                // Fetch plain-text log — no auth header on the redirect target
                HttpURLConnection step2 = (HttpURLConnection) new URL(redirectUrl).openConnection()
                step2.setInstanceFollowRedirects(true)
                step2.setConnectTimeout(30_000)
                step2.setReadTimeout(60_000)
                String logContent = step2.inputStream.text
                step2.disconnect()

                // Parse exception blocks; track slice context for format filtering
                List<Map> exceptions = []
                List<String> currentBlock = []
                boolean inException = false
                String currentSlice = ''

                for (String rawLine : logContent.split('\n')) {
                    // Strip GitHub Actions timestamp prefix: "2024-01-01T12:00:00.0000000Z "
                    String line = rawLine
                            .replaceFirst('^\\d{4}-\\d{2}-\\d{2}T[\\d:.]+Z\\s*', '')
                            .replaceFirst('^##\\[\\w+\\]', '')

                    def sliceMatch = line =~ /### Exceptions in Slice: (.+)/
                    if (sliceMatch) currentSlice = (sliceMatch[0][1] as String).trim()

                    if (line.contains('══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞═════')) {
                        if (!format || currentSlice.contains(format)) {
                            inException = true
                            currentBlock = []
                        }
                        continue
                    }
                    if (inException) {
                        if (line =~ /═{40,}/) {
                            if (currentBlock) exceptions << parseExceptionBlock(currentBlock, currentSlice)
                            currentBlock = []
                            inException = false
                        } else {
                            currentBlock << line
                        }
                    }
                }
                if (inException && currentBlock) exceptions << parseExceptionBlock(currentBlock, currentSlice)

                result[0] = [success: true, exceptions: exceptions, count: exceptions.size()]
            } catch (Exception e) {
                err[0] = e
                logger.error("GithubTool.getTestExceptions failed: ${e.message}", e)
            }
        }, 'adk-github-exceptions')
        t.start()
        t.join(60_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }

    private static Map<String, Object> parseExceptionBlock(List<String> lines, String slice = '') {
        String exceptionType = 'UnknownException'
        String message = ''
        boolean typeFound = false
        List<String> appFrames = []

        for (String line : lines) {
            def m = line =~ /The following (\S+) was thrown/
            if (m) {
                exceptionType = m[0][1]
                typeFound = true
                continue
            }
            if (typeFound && !message && line.trim()) {
                message = line.trim()
            }
            if (isAppFrame(line)) appFrames << line.trim()
        }

        return [
            exceptionType: exceptionType,
            message      : message,
            stackTrace   : appFrames.join('\n'),
            rawBlock     : lines.take(30).join('\n'),
            packageSlice : slice,
        ]
    }

    private static boolean isAppFrame(String line) {
        if (!line.startsWith('#'))                  return false
        if (line.contains('package:flutter/'))      return false
        if (line.contains('package:flutter_test/')) return false
        if (line.contains('dart:'))                 return false
        if (line.contains('package:test/'))         return false
        return true
    }

    @Schema(description = 'Get the HEAD commit SHA of the main branch in growerp/growerp. Use this SHA as fromSha when calling createBranch.')
    static Map<String, Object> getMainSha(
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {
        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                String token = resolveGithubToken(ownerPartyId)
                if (!token) { result[0] = [success: false, error: 'GITHUB_TOKEN not set']; return }

                def resp = githubGet("${API_BASE}/repos/${resolveRepo()}/git/ref/heads/main", token)
                if (resp.code < 0 || resp.code >= 400) {
                    result[0] = [success: false, error: "GitHub API error ${resp.code}: ${resp.body}"]
                    return
                }
                result[0] = [success: true, sha: resp.parsed?.object?.sha]
            } catch (Exception e) {
                err[0] = e
                logger.error("GithubTool.getMainSha failed: ${e.message}", e)
            }
        }, 'adk-github-mainsha')
        t.start()
        t.join(20_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }

    @Schema(description = 'Get the content and SHA of a file from the growerp/growerp repository.')
    static Map<String, Object> getFileContent(
            @Schema(name = 'path',
                    description = 'File path in repo, e.g. flutter/packages/growerp_catalog/lib/src/catalog_router.dart') String path,
            @Schema(name = 'ref',
                    description = 'Branch name or commit SHA to read from') String ref,
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {

        if (!path) return [success: false, error: 'path is required']

        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                String token = resolveGithubToken(ownerPartyId)
                if (!token) { result[0] = [success: false, error: 'GITHUB_TOKEN not set']; return }

                String url = "${API_BASE}/repos/${resolveRepo()}/contents/${path}"
                if (ref) url += "?ref=${URLEncoder.encode(ref, 'UTF-8')}"
                def resp = githubGet(url, token)
                if (resp.code < 0 || resp.code >= 400) {
                    result[0] = [success: false, error: "GitHub API error ${resp.code}: ${resp.body}"]
                    return
                }

                String b64 = (resp.parsed?.content as String) ?: ''
                String content = new String(Base64.getMimeDecoder().decode(b64.replaceAll('\\s', '')), 'UTF-8')
                result[0] = [
                    success: true,
                    content: content,
                    sha    : resp.parsed?.sha,
                    size   : resp.parsed?.size,
                    path   : resp.parsed?.path,
                ]
            } catch (Exception e) {
                err[0] = e
                logger.error("GithubTool.getFileContent failed for ${path}: ${e.message}", e)
            }
        }, 'adk-github-getcontent')
        t.start()
        t.join(20_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }

    @Schema(description = 'Create a new branch in growerp/growerp from a given commit SHA. Get fromSha from getMainSha().')
    static Map<String, Object> createBranch(
            @Schema(name = 'branchName',
                    description = 'New branch name, e.g. fix/ci-flutter-NoSuchMethodError-1717200000') String branchName,
            @Schema(name = 'fromSha',
                    description = 'Commit SHA to branch from') String fromSha,
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {

        if (!branchName) return [success: false, error: 'branchName is required']
        if (!fromSha)    return [success: false, error: 'fromSha is required']

        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                String token = resolveGithubToken(ownerPartyId)
                if (!token) { result[0] = [success: false, error: 'GITHUB_TOKEN not set']; return }

                def resp = githubPost("${API_BASE}/repos/${resolveRepo()}/git/refs", token,
                        [ref: "refs/heads/${branchName}", sha: fromSha])
                if (resp.code < 0 || resp.code >= 400) {
                    result[0] = [success: false, error: "GitHub API error ${resp.code}: ${resp.body}"]
                    return
                }
                result[0] = [success: true, branchName: branchName, ref: resp.parsed?.ref]
            } catch (Exception e) {
                err[0] = e
                logger.error("GithubTool.createBranch failed: ${e.message}", e)
            }
        }, 'adk-github-createbranch')
        t.start()
        t.join(20_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }

    @Schema(description = 'Create or update a file in growerp/growerp on a specified branch. Pass plain text content — the tool handles base64 encoding.')
    static Map<String, Object> updateFileContent(
            @Schema(name = 'path',
                    description = 'File path in repository') String path,
            @Schema(name = 'commitMessage',
                    description = 'Git commit message') String commitMessage,
            @Schema(name = 'content',
                    description = 'New file content as plain text (not base64)') String content,
            @Schema(name = 'sha',
                    description = 'Current file SHA from getFileContent (required for updates, omit for new files)') String sha,
            @Schema(name = 'branch',
                    description = 'Branch name to commit to') String branch,
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {

        if (!path)    return [success: false, error: 'path is required']
        if (!content) return [success: false, error: 'content is required']
        if (!branch)  return [success: false, error: 'branch is required']

        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                String token = resolveGithubToken(ownerPartyId)
                if (!token) { result[0] = [success: false, error: 'GITHUB_TOKEN not set']; return }

                String b64 = content.bytes.encodeBase64().toString()
                Map payload = [
                    message: commitMessage ?: "Update ${path}",
                    content: b64,
                    branch : branch,
                ]
                if (sha) payload.sha = sha

                def resp = githubPost("${API_BASE}/repos/${resolveRepo()}/contents/${path}", token, payload, 'PUT')
                if (resp.code < 0 || resp.code >= 400) {
                    result[0] = [success: false, error: "GitHub API error ${resp.code}: ${resp.body}"]
                    return
                }
                result[0] = [
                    success  : true,
                    commitSha: resp.parsed?.commit?.sha,
                    path     : path,
                    branch   : branch,
                ]
            } catch (Exception e) {
                err[0] = e
                logger.error("GithubTool.updateFileContent failed for ${path}: ${e.message}", e)
            }
        }, 'adk-github-updatecontent')
        t.start()
        t.join(20_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }

    @Schema(description = 'Create a pull request in growerp/growerp. Returns prUrl and prNumber.')
    static Map<String, Object> createPullRequest(
            @Schema(name = 'title',
                    description = 'PR title') String title,
            @Schema(name = 'body',
                    description = 'PR description body (markdown)') String body,
            @Schema(name = 'head',
                    description = 'Source branch name') String head,
            @Schema(name = 'base',
                    description = 'Target branch name, typically main') String base,
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {

        if (!title) return [success: false, error: 'title is required']
        if (!head)  return [success: false, error: 'head is required']

        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                String token = resolveGithubToken(ownerPartyId)
                if (!token) { result[0] = [success: false, error: 'GITHUB_TOKEN not set']; return }

                def resp = githubPost("${API_BASE}/repos/${resolveRepo()}/pulls", token, [
                    title: title,
                    body : body ?: '',
                    head : head,
                    base : base ?: 'main',
                ])
                if (resp.code < 0 || resp.code >= 400) {
                    result[0] = [success: false, error: "GitHub API error ${resp.code}: ${resp.body}"]
                    return
                }
                result[0] = [
                    success : true,
                    prUrl   : resp.parsed?.html_url,
                    prNumber: resp.parsed?.number?.toString(),
                ]
            } catch (Exception e) {
                err[0] = e
                logger.error("GithubTool.createPullRequest failed: ${e.message}", e)
            }
        }, 'adk-github-createpr')
        t.start()
        t.join(20_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }

    @Schema(description = 'Add a comment to a pull request or issue in growerp/growerp.')
    static Map<String, Object> addComment(
            @Schema(name = 'prNumber',
                    description = 'Pull request or issue number as a string') String prNumber,
            @Schema(name = 'body',
                    description = 'Comment body (markdown)') String body,
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {

        if (!prNumber) return [success: false, error: 'prNumber is required']
        if (!body)     return [success: false, error: 'body is required']

        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                String token = resolveGithubToken(ownerPartyId)
                if (!token) { result[0] = [success: false, error: 'GITHUB_TOKEN not set']; return }

                def resp = githubPost("${API_BASE}/repos/${resolveRepo()}/issues/${prNumber}/comments", token, [body: body])
                if (resp.code < 0 || resp.code >= 400) {
                    result[0] = [success: false, error: "GitHub API error ${resp.code}: ${resp.body}"]
                    return
                }
                result[0] = [
                    success   : true,
                    commentId : resp.parsed?.id?.toString(),
                    commentUrl: resp.parsed?.html_url,
                ]
            } catch (Exception e) {
                err[0] = e
                logger.error("GithubTool.addComment failed: ${e.message}", e)
            }
        }, 'adk-github-addcomment')
        t.start()
        t.join(20_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }
}
