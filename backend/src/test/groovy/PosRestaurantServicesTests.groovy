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

import org.moqui.Moqui
import org.moqui.context.ExecutionContext
import org.moqui.context.ExecutionContextFactory
import org.moqui.context.NotificationMessage
import org.moqui.context.NotificationMessageListener
import spock.lang.Shared
import spock.lang.Specification

import java.util.concurrent.CopyOnWriteArrayList

/* Tests for the restaurant (PosRestaurantServices100):
   - tables on a floor plan, a table has one open tab
   - lines with modifiers, price and note, editable until sent
   - sending to the kitchen, a resend sends nothing twice
   - the kitchen works a ticket, line state survives other lines changing
   - a line sent is voided, not removed
   - a back office save cannot touch the lines of a tab
   - a bill split equally and by item, settled at once
   - the kitchen hears about it after the commit, the own tenant only

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class PosRestaurantServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant, otherTenant, burger, beer, sauce
    @Shared String service = 'growerp.100.PosRestaurantServices100'
    @Shared String run = Long.toString(System.currentTimeMillis(), 36)
    @Shared String till
    @Shared List<NotificationMessage> heard = new CopyOnWriteArrayList<>()
    @Shared int count = 0

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        ec.factory.registerNotificationMessageListener(new NotificationMessageListener() {
            void init(ExecutionContextFactory ecf) { }
            void destroy() { }
            void onMessage(NotificationMessage nm) { if (nm.topic == 'posKitchen') heard.add(nm) }
        })
        otherTenant = GrowerpTestSupport.tenant(ec, 'PosRestaurantOther')
        tenant = GrowerpTestSupport.tenant(ec, 'PosRestaurant')
        ec.service.sync().name('growerp.100.TaxServices100.migrate#TaxGateway').call()
        burger = product("Burger ${run}", 10)
        beer = product("Beer ${run}", 5)
        sauce = ec.service.sync().name("${service}.store#ModifierGroup")
                .parameters([group: [groupName: "Sauce ${run}", minSelect: 1, maxSelect: 2,
                        modifiers: [[modifierName: 'Mayo', priceDelta: 0], [modifierName: 'Truffle', priceDelta: 2]],
                        productIds: [burger.productId]]]).call().group
        till = "Bar ${run}".toString()
        ec.service.sync().name('growerp.100.PosServices100.open#Shift')
                .parameters([terminalName: till, openingFloat: 100]).call()
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def cleanup() {
        ec.message.clearErrors()
        ec.user.internalLoginUser(tenant.username)
    }

    Map product(String name, BigDecimal price) {
        return ec.service.sync().name('growerp.100.CatalogServices100.create#Product')
                .parameters([product: [productName: name, productTypeId: 'Service', price: price]]).call().product
    }

    Map table(String name = null) {
        return ec.service.sync().name("${service}.create#Table")
                .parameters([table: [tableName: name ?: "T${run}-${++count}".toString(), seats: 4, x: 1, y: 2]])
                .call()?.table
    }

    Map openTab(Map table) {
        return ec.service.sync().name("${service}.open#Tab")
                .parameters([tableAssetId: table.assetId, guestCount: 2]).call()?.tab
    }

    Map addLine(Map tab, Map product, BigDecimal quantity = 1, Map more = [:]) {
        return ec.service.sync().name("${service}.add#TabLine")
                .parameters([tabId: tab.tabId, productId: product.productId, quantity: quantity] + more).call()?.tab
    }

    Map mayo() { sauce.modifiers.find { it.modifierName == 'Mayo' } }

    Map truffle() { sauce.modifiers.find { it.modifierName == 'Truffle' } }

    Map readTab(Map tab) {
        return ec.service.sync().name("${service}.get#Tab").parameters([tabId: tab.tabId]).call()?.tab
    }

    Map send(Map tab) {
        return ec.service.sync().name("${service}.send#TabToKitchen").parameters([tabId: tab.tabId]).call()?.tab
    }

    List tickets() {
        return ec.service.sync().name("${service}.get#KitchenTickets").call()?.tickets
    }

    Map settle(Map tab, List tenders) {
        return ec.service.sync().name("${service}.settle#Tab")
                .parameters([clientSaleId: "${run}-${++count}".toString(), tabId: tab.tabId,
                        terminalName: till, tenders: tenders]).call()?.sale
    }

    Map cash(BigDecimal amount) { [method: 'PiCash', amount: amount] }

    def "tables are on the floor plan, free until a tab opens, with their place"() {
        given:
        Map one = table()

        when:
        ec.service.sync().name("${service}.update#Table")
                .parameters([table: [assetId: one.assetId, x: 7, y: 8, shape: 'round']]).call()
        def found = { ec.service.sync().name("${service}.get#FloorPlan").call().tables.find { it.assetId == one.assetId } }

        then:
        !ec.message.hasError()
        found().x == 7
        found().shape == 'round'
        found().status == 'free'

        when:
        Map tab = openTab(one)

        then:
        !ec.message.hasError()
        found().status == 'occupied'
        found().tabId == tab.tabId

        when: 'a second tab on the table'
        Map second = openTab(one)

        then:
        second == null
        ec.message.errorsString.contains('open tab')
    }

    def "modifiers change price and description and follow the group limits"() {
        given:
        Map tab = openTab(table())

        when: 'the group needs a choice'
        addLine(tab, burger)

        then:
        ec.message.hasError()

        when: 'too many'
        ec.message.clearErrors()
        Map thirdGroup = ec.service.sync().name("${service}.store#ModifierGroup")
                .parameters([group: [groupId: sauce.groupId, groupName: sauce.groupName, minSelect: 1, maxSelect: 1,
                        modifiers: sauce.modifiers, productIds: [burger.productId]]]).call().group
        addLine(tab, burger, 1, [modifierIds: [mayo().modifierId, truffle().modifierId]])

        then:
        thirdGroup.maxSelect == 1
        ec.message.hasError()

        when:
        ec.message.clearErrors()
        Map read = addLine(tab, burger, 2, [modifierIds: [truffle().modifierId], note: 'well done', seatNo: 2])

        then:
        !ec.message.hasError()
        read.lines.size() == 1
        read.lines[0].price as BigDecimal == 12
        read.lines[0].description.contains('Truffle')
        read.lines[0].note == 'well done'
        read.lines[0].seatNo == 2
        read.lines[0].kitchenStatus == 'New'
        read.grandTotal as BigDecimal == 24
    }

    def "a line is changed until it is sent, a resend sends nothing twice"() {
        given:
        Map tab = openTab(table())
        Map read = addLine(tab, beer, 1)
        String seq = read.lines[0].orderItemSeqId

        when:
        read = ec.service.sync().name("${service}.update#TabLine")
                .parameters([tabId: tab.tabId, orderItemSeqId: seq, quantity: 3, note: 'cold']).call().tab

        then:
        !ec.message.hasError()
        read.lines[0].quantity as BigDecimal == 3
        read.lines[0].note == 'cold'

        when:
        send(tab)
        int ticketsBefore = tickets().size()
        Map again = send(tab)

        then:
        !ec.message.hasError()
        again.lines[0].kitchenStatus == 'Sent'
        tickets().size() == ticketsBefore

        when: 'sent lines stay as they are'
        ec.service.sync().name("${service}.update#TabLine")
                .parameters([tabId: tab.tabId, orderItemSeqId: seq, quantity: 1]).call()

        then:
        ec.message.hasError()
    }

    def "the kitchen state of a line survives a new line, the table turns ready"() {
        given:
        Map one = table()
        Map tab = openTab(one)
        Map read = addLine(tab, beer)
        String seq = read.lines[0].orderItemSeqId
        send(tab)
        Map ticket = tickets().find { it.tabId == tab.tabId }

        expect:
        ticket.tableName == one.tableName
        ticket.lines[0].orderItemSeqId == seq

        when:
        ec.service.sync().name("${service}.update#KitchenLine")
                .parameters([orderId: ticket.lines[0].orderId, orderItemSeqId: seq, kitchenStatus: 'Ready']).call()
        addLine(tab, beer, 2)
        Map after = readTab(tab)

        then:
        !ec.message.hasError()
        after.lines.find { it.orderItemSeqId == seq }.kitchenStatus == 'Ready'
        after.lines.find { it.orderItemSeqId != seq }.kitchenStatus == 'New'
        ec.service.sync().name("${service}.get#FloorPlan").call().tables
                .find { it.assetId == one.assetId }.status == 'ready'

        when: 'all served, the ticket leaves the kitchen'
        ec.service.sync().name("${service}.update#KitchenLine")
                .parameters([orderId: ticket.lines[0].orderId, orderItemSeqId: seq, kitchenStatus: 'Served']).call()

        then:
        !ec.message.hasError()
        !tickets().find { it.tabId == tab.tabId }
    }

    def "a line not sent is removed, a line sent is voided and not charged"() {
        given:
        Map tab = openTab(table())
        Map read = addLine(tab, beer)
        send(tab)
        read = addLine(tab, beer, 2)
        String sent = read.lines.find { it.kitchenStatus == 'Sent' }.orderItemSeqId
        String fresh = read.lines.find { it.kitchenStatus == 'New' }.orderItemSeqId

        when:
        ec.service.sync().name("${service}.void#TabLine")
                .parameters([tabId: tab.tabId, orderItemSeqId: fresh]).call()
        ec.service.sync().name("${service}.void#TabLine")
                .parameters([tabId: tab.tabId, orderItemSeqId: sent, reason: 'spilled']).call()
        Map after = readTab(tab)

        then:
        !ec.message.hasError()
        after.lines.size() == 1
        after.lines[0].kitchenStatus == 'Voided'
        after.lines[0].voidReason == 'spilled'
        after.grandTotal as BigDecimal == 0
        !tickets().find { it.tabId == tab.tabId }

        when: 'nothing left to pay, the table is freed'
        ec.service.sync().name("${service}.cancel#Tab").parameters([tabId: tab.tabId]).call()

        then:
        !ec.message.hasError()
        readTab(tab).status == 'Cancelled'
    }

    def "a back office save cannot touch the lines of a tab"() {
        given:
        Map tab = openTab(table())
        Map read = addLine(tab, beer)

        when:
        ec.service.sync().name('growerp.100.FinDocServices100.update#FinDoc')
                .parameters([finDoc: [docType: 'order', sales: true, orderId: read.orderId,
                        items: [[itemType: [itemTypeId: 'ItemProduct'], product: [productId: beer.productId],
                                 quantity: 9, price: 1]]]]).call()

        then:
        ec.message.hasError()

        when:
        ec.message.clearErrors()
        Map after = readTab(tab)

        then:
        after.lines.size() == 1
        after.lines[0].quantity as BigDecimal == 1
    }

    def "a tab with tax is settled, a voided line is left out and the shift has it"() {
        given:
        Map rate = ec.service.sync().name('growerp.100.TaxServices100.create#TaxRate')
                .parameters([taxRate: [taxName: 'VAT', taxPercentage: 10]]).call().taxRate
        Map one = table()
        Map tab = openTab(one)
        addLine(tab, beer, 2)
        Map read = addLine(tab, beer, 1)
        send(tab)
        ec.service.sync().name("${service}.void#TabLine")
                .parameters([tabId: tab.tabId, orderItemSeqId: read.lines[1].orderItemSeqId, reason: 'wrong']).call()

        when:
        Map sale = settle(tab, [cash(20)])

        then:
        !ec.message.hasError()
        sale.grandTotal as BigDecimal == 11
        sale.changeAmount as BigDecimal == 9
        sale.lines.size() == 1
        ec.entity.find('mantle.order.OrderHeader').condition('orderId', sale.orderId).useCache(false)
                .one().statusId == 'OrderCompleted'
        ec.entity.find('mantle.account.invoice.Invoice').condition('invoiceId', sale.invoiceId).useCache(false)
                .one().statusId == 'InvoicePmtRecvd'
        readTab(tab).status == 'Settled'
        ec.service.sync().name("${service}.get#FloorPlan").call().tables
                .find { it.assetId == one.assetId }.status == 'free'

        when:
        String shiftId = ec.service.sync().name('growerp.100.PosServices100.get#CurrentShift')
                .parameters([terminalName: till]).call().shift.shiftId
        Map report = ec.service.sync().name('growerp.100.PosServices100.get#ZReport')
                .parameters([shiftId: shiftId]).call().report

        then:
        report.saleCount >= 1
        report.voidCount >= 1

        cleanup:
        ec.message.clearErrors()
        ec.service.sync().name('growerp.100.TaxServices100.delete#TaxRate').parameters([taxRateId: rate.taxRateId]).call()
    }

    def "with tax in the price a tab totals the menu price, modifier included"() {
        given:
        Map rate = ec.service.sync().name('growerp.100.TaxServices100.create#TaxRate')
                .parameters([taxRate: [taxName: 'VAT', taxPercentage: 21]]).call().taxRate
        ec.service.sync().name('growerp.100.TaxServices100.update#TaxSettings')
                .parameters([pricesIncludeTax: true]).call()
        Map tab = openTab(table())

        when: 'three burgers at 10 with a truffle sauce at 2, then one more'
        Map read = addLine(tab, burger, 3, [modifierIds: [truffle().modifierId]])
        read = ec.service.sync().name("${service}.update#TabLine")
                .parameters([tabId: tab.tabId, orderItemSeqId: read.lines[0].orderItemSeqId, quantity: 4]).call().tab

        then:
        !ec.message.hasError()
        read.grandTotal as BigDecimal == 48
        read.lines[0].price as BigDecimal == 12

        when:
        Map sale = settle(tab, [cash(48)])

        then:
        !ec.message.hasError()
        sale.grandTotal as BigDecimal == 48
        sale.taxTotal as BigDecimal == 8.33
        sale.changeAmount as BigDecimal == 0
        ec.entity.find('mantle.account.invoice.Invoice').condition('invoiceId', sale.invoiceId).useCache(false)
                .one().statusId == 'InvoicePmtRecvd'

        cleanup:
        ec.message.clearErrors()
        ec.service.sync().name('growerp.100.TaxServices100.update#TaxSettings')
                .parameters([pricesIncludeTax: false]).call()
        ec.service.sync().name('growerp.100.TaxServices100.delete#TaxRate').parameters([taxRateId: rate.taxRateId]).call()
    }

    def "a bill is split equally, the last share takes what is left"() {
        given:
        Map tab = openTab(table())
        addLine(tab, beer, 2)

        when:
        Map split = ec.service.sync().name("${service}.calculate#TabSplit")
                .parameters([tabId: tab.tabId, ways: 3]).call()

        then:
        !ec.message.hasError()
        split.shares*.amount.collect { it as BigDecimal } == [3.33, 3.33, 3.34]

        when: 'one card each, settled at once'
        Map sale = settle(tab, split.shares.collect { [method: 'PiCreditCard', amount: it.amount] })

        then:
        !ec.message.hasError()
        sale.tenders.size() == 3
        ec.entity.find('mantle.account.invoice.Invoice').condition('invoiceId', sale.invoiceId).useCache(false)
                .one().statusId == 'InvoicePmtRecvd'
    }

    def "a bill is split by item, with its tax"() {
        given:
        Map rate = ec.service.sync().name('growerp.100.TaxServices100.create#TaxRate')
                .parameters([taxRate: [taxName: 'VAT', taxPercentage: 10]]).call().taxRate
        Map tab = openTab(table())
        addLine(tab, beer, 1)
        Map read = addLine(tab, burger, 1, [modifierIds: [mayo().modifierId]])

        when:
        Map split = ec.service.sync().name("${service}.calculate#TabSplit")
                .parameters([tabId: tab.tabId, assignments: [
                        [orderItemSeqId: read.lines[0].orderItemSeqId, splitNo: 1],
                        [orderItemSeqId: read.lines[1].orderItemSeqId, splitNo: 2]]]).call()

        then:
        !ec.message.hasError()
        split.shares.find { it.splitNo == 1 }.amount as BigDecimal == 5.5
        split.shares.find { it.splitNo == 2 }.amount as BigDecimal == 11
        readTab(tab).lines.find { it.orderItemSeqId == read.lines[1].orderItemSeqId }.splitNo == 2

        cleanup:
        ec.message.clearErrors()
        ec.service.sync().name('growerp.100.TaxServices100.delete#TaxRate').parameters([taxRateId: rate.taxRateId]).call()
    }

    def "a retry of settling gives the same sale, a tab needs a shift and enough money"() {
        given:
        Map tab = openTab(table())
        addLine(tab, beer, 1)
        String id = "${run}-settle".toString()
        Map parameters = [clientSaleId: id, tabId: tab.tabId, terminalName: till, tenders: [cash(5)]]

        when: 'not enough'
        ec.service.sync().name("${service}.settle#Tab").parameters(parameters + [tenders: [cash(1)]]).call()

        then:
        ec.message.hasError()

        when: 'no shift'
        ec.message.clearErrors()
        ec.service.sync().name("${service}.settle#Tab").parameters(parameters + [terminalName: 'Nowhere']).call()

        then:
        ec.message.errorsString.contains('no open shift')

        when:
        ec.message.clearErrors()
        Map first = ec.service.sync().name("${service}.settle#Tab").parameters(parameters).call().sale
        Map second = ec.service.sync().name("${service}.settle#Tab").parameters(parameters).call().sale

        then:
        !ec.message.hasError()
        second.orderId == first.orderId
    }

    def "the kitchen hears about a ticket after the commit, the own tenant only"() {
        given:
        Map tab = openTab(table())
        addLine(tab, beer)
        heard.clear()

        when:
        send(tab)
        for (int i = 0; i < 40 && heard.isEmpty(); i++) sleep(100)
        String ownUserId = ec.user.userId
        String otherUserId = ec.entity.find('moqui.security.UserAccount')
                .condition('username', otherTenant.username).useCache(false).one().userId

        then:
        !heard.isEmpty()
        heard[0].notifyUserIds.contains(ownUserId)
        !heard[0].notifyUserIds.contains(otherUserId)
    }

    def "another tenant sees no tables, tickets or tabs and cannot use them"() {
        given:
        Map one = table()
        Map tab = openTab(one)
        addLine(tab, beer)
        send(tab)
        ec.user.internalLoginUser(otherTenant.username)

        when:
        List tables = ec.service.sync().name("${service}.get#FloorPlan").call().tables
        List own = tickets()

        then:
        tables.isEmpty()
        own.isEmpty()

        when:
        readTab(tab)

        then:
        ec.message.hasError()

        when:
        ec.message.clearErrors()
        addLine(tab, beer)

        then:
        ec.message.hasError()
    }

    def "a table with an open tab stays, a free one can go"() {
        given:
        Map busy = table()
        Map free = table()
        openTab(busy)

        when:
        ec.service.sync().name("${service}.delete#Table").parameters([assetId: busy.assetId]).call()

        then:
        ec.message.hasError()

        when:
        ec.message.clearErrors()
        ec.service.sync().name("${service}.delete#Table").parameters([assetId: free.assetId]).call()
        List tables = ec.service.sync().name("${service}.get#FloorPlan").call().tables

        then:
        !ec.message.hasError()
        !tables.find { it.assetId == free.assetId }
    }

    def "a tab moves to a free table"() {
        given:
        Map from = table()
        Map to = table()
        Map tab = openTab(from)

        when:
        ec.service.sync().name("${service}.move#Tab").parameters([tabId: tab.tabId, tableAssetId: to.assetId]).call()
        List tables = ec.service.sync().name("${service}.get#FloorPlan").call().tables

        then:
        !ec.message.hasError()
        tables.find { it.assetId == from.assetId }.status == 'free'
        tables.find { it.assetId == to.assetId }.tabId == tab.tabId
    }
}
