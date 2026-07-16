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
import groovy.json.JsonSlurper
import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * ADK FunctionTools for the Substack integration: list posts, read comments/engagements,
 * post notes, publish articles and add subscribers.
 *
 * Credentials: SUBSTACK_SID / SUBSTACK_PUBLICATION_URL env vars, then
 * growerp.substack.sid / growerp.substack.pubUrl system properties, then the
 * PlatformConfiguration entity (platform SUBSTACK; apiKey = substack.sid cookie,
 * username = publication URL). All methods are static, run in a background thread
 * (same pattern as GithubTool), and return a Map with success:true/false.
 */
class SubstackTool {

    protected static final Logger logger = LoggerFactory.getLogger(SubstackTool.class)

    /** Resolve [sid, pubUrl, ownerPartyId]: env var -> system property -> PlatformConfiguration. */
    private static Map<String, String> resolveSubstackConfig(String ownerPartyId = null) {
        String sid = System.getenv('SUBSTACK_SID') ?: System.getProperty('growerp.substack.sid') ?: ''
        String pubUrl = System.getenv('SUBSTACK_PUBLICATION_URL') ?:
                System.getProperty('growerp.substack.pubUrl') ?: ''
        if (sid && pubUrl) return [sid: sid, pubUrl: pubUrl.replaceAll('/+$', ''), ownerPartyId: ownerPartyId]

        def ecf = AdkManager.sharedSessionService?.ecf
        if (!ecf) return [sid: '', pubUrl: '', ownerPartyId: null]
        def ec = ecf.getExecutionContext()
        boolean wasDisabled = false
        try {
            ec.user.internalLoginUser('SystemSupport')
            wasDisabled = ec.artifactExecution.disableAuthz()
            def find = ec.entity.find('growerp.marketing.PlatformConfiguration')
                    .condition('platform', 'SUBSTACK').condition('isEnabled', 'Y')
            if (ownerPartyId) find = find.condition('ownerPartyId', ownerPartyId)
            for (def row in find.list()) {
                String rowSid = row.getString('apiKey')
                String rowUrl = row.getString('username')
                if (rowUrl) {
                    return [sid: rowSid ?: '', pubUrl: rowUrl.replaceAll('/+$', ''),
                            ownerPartyId: row.getString('ownerPartyId')]
                }
            }
        } catch (Exception e) {
            logger.error("Failed to retrieve Substack config from PlatformConfiguration: ${e.message}", e)
        } finally {
            if (!wasDisabled) ec.artifactExecution.enableAuthz()
            ec.destroy()
        }
        return [sid: '', pubUrl: '', ownerPartyId: null]
    }

    private static Map<String, Object> substackGet(String url, String sid) {
        try {
            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection()
            conn.setRequestMethod('GET')
            if (sid) conn.setRequestProperty('Cookie', "substack.sid=${sid}; connect.sid=${sid}")
            conn.setConnectTimeout(15_000)
            conn.setReadTimeout(30_000)
            int code = conn.responseCode
            String body = (code < 400 ? conn.inputStream : conn.errorStream)?.text ?: ''
            conn.disconnect()
            return [code: code, body: body,
                    parsed: body ? new JsonSlurper().parseText(body) : null]
        } catch (Exception e) {
            logger.error("SubstackTool.substackGet failed for ${url}: ${e.message}", e)
            return [code: -1, body: e.message, parsed: null]
        }
    }

    /** Run a closure with a SystemSupport ec (authz disabled); always cleans up. */
    private static Object withEc(Closure work) {
        def ecf = AdkManager.sharedSessionService?.ecf
        if (!ecf) throw new IllegalStateException('Moqui not available')
        def ec = ecf.getExecutionContext()
        boolean wasDisabled = false
        try {
            ec.user.internalLoginUser('SystemSupport')
            wasDisabled = ec.artifactExecution.disableAuthz()
            return work(ec)
        } finally {
            if (!wasDisabled) ec.artifactExecution.enableAuthz()
            ec.destroy()
        }
    }

    /** Publish one Substack SocialPost (SUBSTACK article or SUBSTACK_NOTE) and update its row. */
    private static Map<String, Object> publishOnePost(def ec, String postId) {
        def post = ec.entity.find('growerp.marketing.SocialPost').condition('postId', postId).one()
        if (!post) return [success: false, error: "Social post not found: ${postId}".toString()]
        if (!(post.platform in ['SUBSTACK', 'SUBSTACK_NOTE'])) {
            return [success: false, error: "Post ${postId} platform is ${post.platform}, not a Substack post".toString()]
        }
        if (post.status == 'PUBLISHED') {
            return [success: false, error: "Post ${postId} is already published: ${post.publishedUrl}".toString()]
        }
        if (!post.finalContent) return [success: false, error: 'finalContent is required before publishing']

        def config = ec.entity.find('growerp.marketing.PlatformConfiguration')
                .condition('ownerPartyId', post.ownerPartyId)
                .condition('platform', 'SUBSTACK').one()
        if (!config || config.isEnabled != 'Y') {
            return [success: false, error: "No enabled SUBSTACK PlatformConfiguration for owner ${post.ownerPartyId}".toString()]
        }

        String serviceName = post.platform == 'SUBSTACK_NOTE' ?
                'growerp.100.SubstackServices100.publish#SubstackNote' :
                'growerp.100.SocialPostPublishingServices100.publish#SocialPostToSubstack'
        def res = ec.service.sync().name(serviceName)
                .parameters([post: post, platformConfig: config]).call()

        if (res.success) {
            ec.service.sync().name('update#growerp.marketing.SocialPost')
                    .parameters([postId: postId, status: 'PUBLISHED',
                                 publishedDate: ec.user.nowTimestamp,
                                 publishedUrl: res.publishedUrl,
                                 externalPostId: res.externalPostId,
                                 publishError: null,
                                 lastModifiedDate: ec.user.nowTimestamp]).call()
            return [success: true, postId: postId, publishedUrl: res.publishedUrl,
                    externalPostId: res.externalPostId]
        }
        ec.service.sync().name('update#growerp.marketing.SocialPost')
                .parameters([postId: postId, publishError: res.errorMessage,
                             lastModifiedDate: ec.user.nowTimestamp]).call()
        return [success: false, error: (res.errorMessage ?: 'Unknown publish error') as String]
    }

    // ==================== read tools ====================

    @Schema(description = 'List recent posts of the configured Substack publication with id, title, url, post date and reaction/comment counts.')
    static Map<String, Object> listSubstackPosts(
            @Schema(name = 'limit',
                    description = 'Maximum number of posts to return (default 10, max 50)') String limit,
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {
        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                def cfg = resolveSubstackConfig(ownerPartyId)
                if (!cfg.pubUrl) { result[0] = [success: false, error: 'Substack publication URL not configured']; return }
                int lim = Math.min((limit ?: '10').isInteger() ? (limit as int) : 10, 50)

                def resp = substackGet("${cfg.pubUrl}/api/v1/posts?limit=${lim}&offset=0", cfg.sid)
                if (resp.code < 0 || resp.code >= 400) {
                    result[0] = [success: false, error: "Substack API error ${resp.code}: ${resp.body?.take(300)}"]
                    return
                }
                def posts = (resp.parsed instanceof List ? resp.parsed : resp.parsed?.posts ?: []).collect { p ->
                    [externalPostId: p.id?.toString(), title: p.title, subtitle: p.subtitle,
                     url: p.canonical_url, postDate: p.post_date,
                     reactionCount: p.reaction_count ?: p.reactions?.values()?.sum() ?: 0,
                     commentCount: p.comment_count ?: 0]
                }
                result[0] = [success: true, posts: posts, count: posts.size()]
            } catch (Exception e) {
                err[0] = e
                logger.error("SubstackTool.listSubstackPosts failed: ${e.message}", e)
            }
        }, 'adk-substack-listposts')
        t.start()
        t.join(30_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }

    @Schema(description = 'Get the comments (including restacks) on a Substack post. Use externalPostId from listSubstackPosts or from a published SocialPost.')
    static Map<String, Object> getSubstackPostComments(
            @Schema(name = 'externalPostId',
                    description = 'Substack numeric post id') String externalPostId,
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {

        if (!externalPostId) return [success: false, error: 'externalPostId is required']

        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                def cfg = resolveSubstackConfig(ownerPartyId)
                if (!cfg.pubUrl) { result[0] = [success: false, error: 'Substack publication URL not configured']; return }

                def resp = substackGet("${cfg.pubUrl}/api/v1/post/${externalPostId}/comments?all_comments=true", cfg.sid)
                if (resp.code < 0 || resp.code >= 400) {
                    result[0] = [success: false, error: "Substack API error ${resp.code}: ${resp.body?.take(300)}"]
                    return
                }
                List comments = []
                def flatten
                flatten = { List nodes ->
                    for (node in nodes) {
                        if (node == null) continue
                        comments.add([externalId: node.id?.toString(),
                                      userName: node.name ?: 'Anonymous',
                                      handle: node.handle,
                                      body: node.body, date: node.date,
                                      type: node.type ?: 'comment'])
                        if (node.children) flatten(node.children as List)
                    }
                }
                flatten((resp.parsed?.comments ?: []) as List)
                result[0] = [success: true, comments: comments, count: comments.size()]
            } catch (Exception e) {
                err[0] = e
                logger.error("SubstackTool.getSubstackPostComments failed: ${e.message}", e)
            }
        }, 'adk-substack-comments')
        t.start()
        t.join(30_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }

    @Schema(description = 'Get collected Substack engagements (comments/restacks stored as SocialEngagement) from the last N days, with status NEW/CONTACTED/CONVERTED.')
    static Map<String, Object> getSubstackEngagements(
            @Schema(name = 'days',
                    description = 'How many days back to look (default 30)') String days,
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {
        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                result[0] = (Map) withEc { ec ->
                    int d = (days ?: '30').isInteger() ? (days as int) : 30
                    def cutoff = new java.sql.Timestamp(ec.user.nowTimestamp.time - d * 24L * 60 * 60 * 1000)
                    def find = ec.entity.find('growerp.marketing.SocialEngagement')
                            .condition('platform', org.moqui.entity.EntityCondition.ComparisonOperator.IN,
                                    ['SUBSTACK', 'SUBSTACK_NOTE'])
                            .condition('createdDate', org.moqui.entity.EntityCondition.ComparisonOperator.GREATER_THAN_EQUAL_TO, cutoff)
                            .orderBy('-createdDate')
                    if (ownerPartyId) find = find.condition('ownerPartyId', ownerPartyId)
                    def rows = find.list().collect { r ->
                        [engagementId: r.engagementId, postId: r.postId,
                         engagementType: r.engagementType, userName: r.userName,
                         userProfileUrl: r.userProfileUrl, note: r.note,
                         status: r.status, createdDate: r.createdDate?.toString()]
                    }
                    return [success: true, engagements: rows, count: rows.size()]
                }
            } catch (Exception e) {
                err[0] = e
                logger.error("SubstackTool.getSubstackEngagements failed: ${e.message}", e)
            }
        }, 'adk-substack-engagements')
        t.start()
        t.join(30_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }

    @Schema(description = 'Get Substack subscriber sync statistics: how many GrowERP signup emails were synced to Substack, failed, and the most recent failures.')
    static Map<String, Object> getSubscriberSyncStats(
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {
        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                result[0] = (Map) withEc { ec ->
                    def find = ec.entity.find('growerp.marketing.SubstackSubscriberSync')
                    if (ownerPartyId) find = find.condition('ownerPartyId', ownerPartyId)
                    def rows = find.list()
                    def failed = rows.findAll { it.status == 'FAILED' }
                    return [success: true,
                            syncedCount: rows.count { it.status == 'SYNCED' },
                            failedCount: failed.size(),
                            recentFailures: failed.sort { -(it.syncedDate?.time ?: 0L) }.take(5).collect {
                                [emailAddress: it.emailAddress, errorMessage: it.errorMessage,
                                 syncedDate: it.syncedDate?.toString()]
                            }]
                }
            } catch (Exception e) {
                err[0] = e
                logger.error("SubstackTool.getSubscriberSyncStats failed: ${e.message}", e)
            }
        }, 'adk-substack-syncstats')
        t.start()
        t.join(30_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }

    // ==================== write tools ====================

    @Schema(description = 'Post a Substack Note (short-form post) immediately. Creates a SocialPost record (platform SUBSTACK_NOTE) and publishes it. Returns publishedUrl.')
    static Map<String, Object> postSubstackNote(
            @Schema(name = 'text',
                    description = 'The note text; blank lines separate paragraphs') String text,
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {

        if (!text) return [success: false, error: 'text is required']

        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                String owner = ownerPartyId ?: resolveSubstackConfig(null).ownerPartyId
                if (!owner) { result[0] = [success: false, error: 'No enabled SUBSTACK PlatformConfiguration found']; return }
                result[0] = (Map) withEc { ec ->
                    def created = ec.service.sync().name('create#growerp.marketing.SocialPost')
                            .parameters([ownerPartyId: owner, platform: 'SUBSTACK_NOTE',
                                         type: 'OTHER', finalContent: text, status: 'READY',
                                         createdDate: ec.user.nowTimestamp,
                                         lastModifiedDate: ec.user.nowTimestamp]).call()
                    return publishOnePost(ec, created.postId as String)
                }
            } catch (Exception e) {
                err[0] = e
                logger.error("SubstackTool.postSubstackNote failed: ${e.message}", e)
            }
        }, 'adk-substack-postnote')
        t.start()
        t.join(60_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }

    @Schema(description = 'Publish an existing Substack SocialPost (article or note) by postId: article flow is draft -> publish -> email to all subscribers. Irreversible for articles.')
    static Map<String, Object> publishSubstackArticle(
            @Schema(name = 'postId',
                    description = 'SocialPost postId with platform SUBSTACK or SUBSTACK_NOTE') String postId,
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {

        if (!postId) return [success: false, error: 'postId is required']

        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                result[0] = (Map) withEc { ec -> publishOnePost(ec, postId) }
            } catch (Exception e) {
                err[0] = e
                logger.error("SubstackTool.publishSubstackArticle failed: ${e.message}", e)
            }
        }, 'adk-substack-publish')
        t.start()
        t.join(90_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }

    @Schema(description = 'Add one email address as a free subscriber to the Substack publication. Idempotent: already-synced and test (example.com) emails are skipped.')
    static Map<String, Object> addSubstackSubscriber(
            @Schema(name = 'email',
                    description = 'Email address to subscribe') String email,
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID; pass {tenantId} from your context') String ownerPartyId = null) {

        if (!email) return [success: false, error: 'email is required']

        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            try {
                result[0] = (Map) withEc { ec ->
                    def res = ec.service.sync()
                            .name('growerp.100.SubstackServices100.add#SubstackSubscriber')
                            .parameters([emailAddress: email] +
                                    (ownerPartyId ? [ownerPartyId: ownerPartyId] : [:])).call()
                    return [success: res.resultStatus != 'FAILED',
                            resultStatus: res.resultStatus, errorMessage: res.errorMessage]
                }
            } catch (Exception e) {
                err[0] = e
                logger.error("SubstackTool.addSubstackSubscriber failed: ${e.message}", e)
            }
        }, 'adk-substack-addsub')
        t.start()
        t.join(60_000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }
}
