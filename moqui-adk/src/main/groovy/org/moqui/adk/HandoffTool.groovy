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
import com.google.adk.tools.ToolContext
import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * ADK FunctionTool that hands a website-chat conversation off to a human support agent.
 *
 * The active chat room and tenant are read from the ADK session state (seeded by
 * AdkChatServices.reply#WebsiteChatAgent as 'chatRoomId' / 'tenantId') via the injected
 * ToolContext — the model never has to pass ids, and the tool is a no-op outside a website chat.
 */
class HandoffTool {

    protected static final Logger logger = LoggerFactory.getLogger(HandoffTool.class)

    @Schema(description = 'Hand the current website-chat conversation off to a human support ' +
            'agent. Call this when the customer asks to speak to a person/human/representative, ' +
            'or when you cannot help. After calling it, tell the customer a human will follow up here.')
    static Map<String, Object> requestHumanHandoff(
            @Schema(name = 'reason',
                    description = 'Short reason for the handoff (e.g. "customer asked for a human")')
            String reason,
            @Schema(name = 'toolContext') ToolContext toolContext) {

        def state = toolContext?.state()
        String chatRoomId   = state?.get('chatRoomId') as String
        String ownerPartyId = state?.get('tenantId') as String
        if (!chatRoomId) {
            return [success: false, error: 'No active website chat room — handoff only works in website chat']
        }

        Map<String, Object>[] result = [null]
        Throwable[] err = [null]

        Thread t = new Thread({
            def ecf = AdkManager.sharedSessionService?.ecf
            if (!ecf) { result[0] = [success: false, error: 'ADK session service not initialised']; return }
            def ec = ecf.getExecutionContext()
            try {
                ec.user.internalLoginUser('SystemSupport')
                ec.service.sync()
                        .name('AdkChatServices.escalate#WebsiteChat')
                        .parameters([chatRoomId: chatRoomId, ownerPartyId: ownerPartyId, reason: reason])
                        .call()
                result[0] = [success: true, message: 'Connected to a human support agent.']
            } catch (Exception e) {
                err[0] = e
                logger.error("HandoffTool.requestHumanHandoff failed: ${e.message}", e)
            } finally {
                ec.destroy()
            }
        }, 'adk-handoff')
        t.start()
        t.join(15000L)

        if (err[0]) return [success: false, error: err[0].message]
        return result[0] ?: [success: false, error: 'Unknown error']
    }
}
