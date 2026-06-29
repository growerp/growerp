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
import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * ADK FunctionTools for sending and polling email.
 *
 * emailServerId == ownerPartyId (set via SystemSettings in the Flutter app).
 * Both methods return an error map when no EmailServer record exists for the
 * given ownerPartyId rather than attempting a connection.
 */
class EmailTool {

    protected static final Logger logger = LoggerFactory.getLogger(EmailTool.class)

    @Schema(description = 'Send an email on behalf of the current tenant')
    static Map<String, Object> sendEmail(
            @Schema(name = 'toAddresses',
                    description = 'Comma-separated list of recipient email addresses') String toAddresses,
            @Schema(name = 'subject',
                    description = 'Email subject line') String subject,
            @Schema(name = 'body',
                    description = 'Plain-text email body') String body,
            @Schema(name = 'fromAddress',
                    description = 'Sender address override (optional, uses server default if blank)') String fromAddress,
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID — equals the emailServerId; pass {tenantId} from your context') String ownerPartyId) {

        if (!ownerPartyId) return [success: false, error: 'ownerPartyId is required']

        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            def ecf = AdkManager.sharedSessionService?.ecf
            if (!ecf) { result[0] = [success: false, error: 'ADK session service not initialised']; return }
            def ec = ecf.getExecutionContext()
            try {
                ec.user.internalLoginUser('SystemSupport')

                // Guard: email not configured for this tenant
                def es = ec.entity.find('moqui.basic.email.EmailServer')
                        .condition('emailServerId', ownerPartyId).one()
                if (!es) {
                    result[0] = [success: false,
                                 error: "Email not configured for tenant '${ownerPartyId}'. Configure it in System Setup."]
                    return
                }

                List toList = toAddresses.split(',').collect { it.trim() }.findAll { it }
                Map fields = [toList: toList, subject: subject]
                if (fromAddress) fields.from = fromAddress

                ec.service.sync()
                        .name('org.moqui.impl.EmailServices.send#EmailMessage')
                        .parameters([
                            emailServerId: ownerPartyId,
                            fields       : fields,
                            bodyPartList : [[contentType: 'text/plain', contentText: body]],
                        ])
                        .call()

                result[0] = [success: true, message: "Email sent to ${toAddresses}"]
            } catch (Exception e) {
                err[0] = e
                logger.error("EmailTool.sendEmail failed: ${e.message}", e)
            } finally {
                ec.destroy()
            }
        }, 'adk-email-send')
        t.start()
        t.join(15000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }

    @Schema(description = 'Poll the incoming mailbox and return recent emails for the current tenant')
    static Map<String, Object> readEmails(
            @Schema(name = 'ownerPartyId',
                    description = 'Tenant owner party ID — equals the emailServerId; pass {tenantId} from your context') String ownerPartyId,
            @Schema(name = 'maxMessages',
                    description = 'Maximum number of messages to return (default 10)') int maxMessages) {

        if (!ownerPartyId) return [success: false, error: 'ownerPartyId is required']
        int limit = maxMessages > 0 ? maxMessages : 10

        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            def ecf = AdkManager.sharedSessionService?.ecf
            if (!ecf) { result[0] = [success: false, error: 'ADK session service not initialised']; return }
            def ec = ecf.getExecutionContext()
            try {
                ec.user.internalLoginUser('SystemSupport')

                // Guard: email not configured for this tenant
                def es = ec.entity.find('moqui.basic.email.EmailServer')
                        .condition('emailServerId', ownerPartyId).one()
                if (!es) {
                    result[0] = [success: false,
                                 error: "Email not configured for tenant '${ownerPartyId}'. Configure it in System Setup."]
                    return
                }

                // Poll for new messages (triggers Email-ECA rules, saves to EmailMessage)
                try {
                    ec.service.sync()
                            .name('org.moqui.impl.EmailServices.poll#EmailServer')
                            .parameters([emailServerId: ownerPartyId])
                            .call()
                } catch (Exception pe) {
                    logger.warn("EmailTool.readEmails poll failed (will still return stored messages): ${pe.message}")
                }

                // Return recently received messages
                def msgList = ec.entity.find('moqui.basic.email.EmailMessage')
                        .condition('emailServerId', ownerPartyId)
                        .orderBy('-receivedDate')
                        .limit(limit)
                        .list()

                List emails = msgList.collect { msg ->
                    [
                        subject     : msg.subject,
                        fromAddress : msg.fromAddress,
                        toAddresses : msg.toAddresses,
                        receivedDate: msg.receivedDate?.toString(),
                        body        : msg.body,
                    ]
                }

                result[0] = [success: true, emails: emails, count: emails.size()]
            } catch (Exception e) {
                err[0] = e
                logger.error("EmailTool.readEmails failed: ${e.message}", e)
            } finally {
                ec.destroy()
            }
        }, 'adk-email-read')
        t.start()
        t.join(30000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }
}
