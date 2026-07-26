/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
