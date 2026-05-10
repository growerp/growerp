/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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

import org.moqui.context.ExecutionContext

ExecutionContext ec = context.ec ?: context

// The Flutter MenuConfigBloc handles the actual menu save (create#/update#MenuConfiguration).
// This script only persists the conversation as a private ChatRoom for support review.

// 1. Get owner party for the chat room
def ownerResult = ec.service.sync()
    .name("growerp.100.GeneralServices100.get#RelatedCompanyAndOwner")
    .call()

def ownerPartyId = ownerResult.ownerPartyId ?: ownerResult.companyPartyId
if (!ownerPartyId) {
    ec.message.addError("Cannot save onboarding: ownerPartyId not found")
    return
}

// 2. Get company name
def companyName = classificationId
def companyPartyId = ownerResult.companyPartyId
if (companyPartyId) {
    def companyDetail = ec.entity.find("mantle.party.PartyDetailAndRole")
        .condition("partyId", companyPartyId)
        .one()
    if (companyDetail?.organizationName) companyName = companyDetail.organizationName
}

def roomName = "Onboarding: ${companyName} [${classificationId}] ${new Date().format('yyyy-MM-dd')}"

// 3. Create ChatRoom using low-level Moqui CRUD service
def roomCreate = ec.service.sync()
    .name("create#growerp.general.ChatRoom")
    .parameters([
        chatRoomName: roomName,
        isPrivate   : 'Y',
        ownerPartyId: ownerPartyId,
    ])
    .call()

def chatRoomId = roomCreate.chatRoomId
if (!chatRoomId) {
    ec.message.addError("Onboarding save: could not create ChatRoom")
    return
}

// 4. Add initiating user as member
ec.service.sync()
    .name("create#growerp.general.ChatRoomMember")
    .parameters([
        chatRoomId: chatRoomId,
        userId    : ec.user.userAccount.userId,
        isActive  : 'Y',
        hasRead   : 'Y',
    ])
    .call()

// 5. Add SYSTEM_SUPPORT as member so the support app can list this room
ec.service.sync()
    .name("create#growerp.general.ChatRoomMember")
    .parameters([
        chatRoomId: chatRoomId,
        userId    : 'SYSTEM_SUPPORT',
        isActive  : 'Y',
        hasRead   : 'Y',
    ])
    .call()

// 6. Persist conversation messages
for (msg in conversation) {
    def role = msg.role == "model" ? "[Gemini]" : "[User]"
    def textPart = msg.parts?.find { it.text }
    def text = textPart?.text ?: ""
    if (text) {
        ec.service.sync()
            .name("create#growerp.general.ChatMessage")
            .parameters([
                chatRoomId: chatRoomId,
                fromUserId: ec.user.userAccount.userId,
                content   : "${role} ${text}",
            ])
            .call()
    }
}
