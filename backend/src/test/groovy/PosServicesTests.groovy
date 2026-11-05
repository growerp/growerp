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
import spock.lang.Shared
import spock.lang.Specification

/* Tests for the point of sale (PosServices100):
   - a sale paid in cash, by card and mixed, change given back
   - a walk-in customer, not in the customer list
   - a retry of the same sale gives the same sale, a different one with the same id is refused
   - stock goes down, a sale above recorded stock still completes and logs the variance
   - a sale of services only completes without a shipment
   - the invoice is paid and the ledger balances, the receipt has the tax per rate
   - the client cannot set the price, products of another tenant cannot be sold

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class PosServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant, otherTenant, service1, gadget, foreign
    @Shared String service = 'growerp.100.PosServices100'
    @Shared String run = Long.toString(System.currentTimeMillis(), 36)
    @Shared int saleCount = 0

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        otherTenant = GrowerpTestSupport.tenant(ec, 'PosTestOther')
        foreign = createProduct("Foreign ${run}", 'Service', 10)
        tenant = GrowerpTestSupport.tenant(ec, 'PosTest')
        ec.service.sync().name('growerp.100.TaxServices100.migrate#TaxGateway').call()
        service1 = createProduct("Haircut ${run}", 'Service', 10)
        gadget = createProduct("Gadget ${run}", 'Physical Good', 10)
        Map location = ec.service.sync().name('growerp.100.InventoryServices100.create#Location')
                .parameters([location: [locationName: "Shelf ${run}"]]).call().location
        ec.service.sync().name('growerp.100.InventoryServices100.create#Asset')
                .parameters([asset: [assetName: "Gadget stock ${run}", statusId: 'Available',
                        quantityOnHand: 10, availableToPromise: 10, acquireCost: 2,
                        product: [productId: gadget.productId],
                        location: [locationId: location.locationId]]]).call()
        openShift("Till 1 ${run}".toString(), 100)
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def cleanup() {
        ec.message.clearErrors()
        ec.user.internalLoginUser(tenant.username)
        ec.service.sync().name('growerp.100.TaxServices100.get#TaxRates').call().taxRates.each {
            ec.service.sync().name('growerp.100.TaxServices100.delete#TaxRate')
                    .parameters([taxRateId: it.taxRateId]).call()
        }
        ec.service.sync().name('growerp.100.TaxServices100.update#TaxSettings')
                .parameters([pricesIncludeTax: false]).call()
    }

    Map createProduct(String name, String type, BigDecimal price) {
        return ec.service.sync().name('growerp.100.CatalogServices100.create#Product')
                .parameters([product: [productName: name, productTypeId: type, price: price,
                        useWarehouse: type != 'Service']]).call().product
    }

    Map sell(List lines, List tenders, String clientSaleId = null, String terminalName = "Till 1 ${run}".toString()) {
        return ec.service.sync().name("${service}.create#PosSale")
                .parameters([clientSaleId: clientSaleId ?: "${run}-${++saleCount}".toString(),
                        terminalName: terminalName, lines: lines, tenders: tenders]).call()?.sale
    }

    Map openShift(String terminalName, BigDecimal openingFloat) {
        return ec.service.sync().name("${service}.open#Shift")
                .parameters([terminalName: terminalName, openingFloat: openingFloat]).call()?.shift
    }

    Map closeShift(Map shift, BigDecimal countedCash) {
        return ec.service.sync().name("${service}.close#Shift")
                .parameters([shiftId: shift.shiftId, countedCash: countedCash]).call()?.report
    }

    List shiftEntries(Map shift) {
        def trans = ec.entity.find('mantle.ledger.transaction.AcctgTrans')
                .condition('description', "POS shift ${shift.shiftId}".toString()).useCache(false).list()
        return trans ? ec.entity.find('mantle.ledger.transaction.AcctgTransEntry')
                .condition('acctgTransId', trans[0].acctgTransId).useCache(false).list() : []
    }

    void cashMovement(Map shift, BigDecimal amount, String reason) {
        ec.service.sync().name("${service}.create#CashMovement")
                .parameters([shiftId: shift.shiftId, amount: amount, reason: reason]).call()
    }

    Map line(Map product, BigDecimal quantity) {
        return [productId: product.productId, quantity: quantity]
    }

    Map cash(BigDecimal amount) {
        return [method: 'PiCash', amount: amount]
    }

    Map invoiceOf(Map sale) {
        return ec.entity.find('mantle.account.invoice.Invoice').condition('invoiceId', sale.invoiceId)
                .useCache(false).one()
    }

    BigDecimal onHand(Map product) {
        return ec.entity.find('mantle.product.asset.Asset').condition('productId', product.productId)
                .useCache(false).list().sum { it.quantityOnHandTotal as BigDecimal } as BigDecimal
    }

    def "a cash sale of a service is paid and completed, with change"() {
        when:
        Map sale = sell([line(service1, 2)], [cash(50)])

        then:
        !ec.message.hasError()
        sale.grandTotal as BigDecimal == 20
        sale.changeAmount as BigDecimal == 30
        ec.entity.find('mantle.order.OrderHeader').condition('orderId', sale.orderId).useCache(false)
                .one().statusId == 'OrderCompleted'
        invoiceOf(sale).statusId == 'InvoicePmtRecvd'

        when:
        def payments = ec.entity.find('mantle.account.payment.Payment').condition('forInvoiceId', sale.invoiceId)
                .useCache(false).list()

        then: 'only what the sale cost is booked, in cash'
        payments.size() == 1
        payments[0].amount as BigDecimal == 20
        payments[0].paymentInstrumentEnumId == 'PiCash'
        payments[0].statusId == 'PmntDelivered'
    }

    def "a sale paid partly by card and partly in cash"() {
        when:
        Map sale = sell([line(service1, 3)], [cash(20), [method: 'PiCreditCard', amount: 15, reference: 'AUTH1']])

        then:
        !ec.message.hasError()
        sale.changeAmount as BigDecimal == 5
        invoiceOf(sale).statusId == 'InvoicePmtRecvd'

        when:
        def payments = ec.entity.find('mantle.account.payment.Payment').condition('forInvoiceId', sale.invoiceId)
                .useCache(false).list()

        then:
        payments.find { it.paymentInstrumentEnumId == 'PiCreditCard' }.amount as BigDecimal == 15
        payments.find { it.paymentInstrumentEnumId == 'PiCreditCard' }.paymentRefNum == 'AUTH1'
        payments.find { it.paymentInstrumentEnumId == 'PiCash' }.amount as BigDecimal == 15
    }

    def "a sale is refused when not enough is paid or a card pays too much"() {
        when:
        Map sale = sell([line(service1, 2)], [cash(5)])

        then:
        ec.message.hasError()
        sale == null

        when:
        ec.message.clearErrors()
        sell([line(service1, 1)], [[method: 'PiCreditCard', amount: 20]])

        then:
        ec.message.hasError()
    }

    def "the walk-in customer is shared by the sales and not in the customer list"() {
        when:
        Map first = sell([line(service1, 1)], [cash(10)])
        Map second = sell([line(service1, 1)], [cash(10)])
        def parts = ec.entity.find('mantle.order.OrderPart').condition('orderId', 'in', [first.orderId, second.orderId])
                .useCache(false).list()
        List customers = ec.service.sync().name('growerp.100.PartyServices100.get#User')
                .parameters([role: 'Customer', limit: 100]).call().users

        then:
        !ec.message.hasError()
        parts*.customerPartyId.unique().size() == 1
        !(parts[0].customerPartyId in (customers*.partyId + customers*.company*.partyId))
    }

    def "amounts leave as strings, the frontend parses them as Decimal"() {
        given:
        ec.service.sync().name('growerp.100.TaxServices100.create#TaxRate')
                .parameters([taxRate: [taxName: 'VAT', taxPercentage: 10]]).call()

        when:
        Map sale = sell([line(service1, 1)], [cash(20)])
        Map quote = ec.service.sync().name("${service}.quote#PosSale")
                .parameters([lines: [line(service1, 1)]]).call()
        String rate = ec.service.sync().name('growerp.100.TaxServices100.get#TaxRates').call()
                .taxRates[0].taxPercentage

        then:
        !ec.message.hasError()
        rate as BigDecimal == 10
        [sale.grandTotal, sale.taxTotal, sale.changeAmount, sale.lines[0].price, sale.lines[0].quantity,
         sale.lines[0].lineTotal, sale.taxes[0].taxAmount, sale.taxes[0].taxPercentage,
         sale.tenders[0].amount, sale.saleDate, quote.grandTotal, quote.taxTotal].every { it instanceof String }
    }

    def "a retry of a sale gives the same sale"() {
        given:
        String id = "${run}-retry".toString()
        long before = ec.entity.find('mantle.order.OrderHeader').count()

        when:
        Map first = sell([line(service1, 1)], [cash(10)], id)
        Map second = sell([line(service1, 1)], [cash(10)], id)

        then:
        !ec.message.hasError()
        second.orderId == first.orderId
        ec.entity.find('mantle.order.OrderHeader').count() == before + 1

        when: 'another sale with the same id'
        sell([line(service1, 2)], [cash(20)], id)

        then:
        ec.message.hasError()
    }

    def "stock goes down and the invoice is paid"() {
        given:
        BigDecimal before = onHand(gadget)

        when:
        Map sale = sell([line(gadget, 2)], [cash(20)])

        then:
        !ec.message.hasError()
        onHand(gadget) == before - 2
        ec.entity.find('mantle.order.OrderHeader').condition('orderId', sale.orderId).useCache(false)
                .one().statusId == 'OrderCompleted'
        invoiceOf(sale).statusId == 'InvoicePmtRecvd'
    }

    def "a sale above the recorded stock completes and logs the variance"() {
        given:
        Map rare = createProduct("Rare ${run}", 'Physical Good', 10)
        long before = ec.entity.find('mantle.product.asset.PhysicalInventory').count()

        when:
        Map sale = sell([line(rare, 2)], [cash(20)])

        then:
        !ec.message.hasError()
        ec.entity.find('mantle.order.OrderHeader').condition('orderId', sale.orderId).useCache(false)
                .one().statusId == 'OrderCompleted'
        ec.entity.find('mantle.product.asset.PhysicalInventory').count() > before
        onHand(rare) == 0
    }

    def "a sale above stock that is partly there corrects only the difference"() {
        given:
        Map scarce = createProduct("Scarce ${run}", 'Physical Good', 10)
        Map location = ec.service.sync().name('growerp.100.InventoryServices100.create#Location')
                .parameters([location: [locationName: "Back ${run}"]]).call().location
        ec.service.sync().name('growerp.100.InventoryServices100.create#Asset')
                .parameters([asset: [assetName: "Scarce stock ${run}", statusId: 'Available',
                        quantityOnHand: 1, availableToPromise: 1, acquireCost: 2,
                        product: [productId: scarce.productId],
                        location: [locationId: location.locationId]]]).call()

        when:
        sell([line(scarce, 3)], [cash(30)])

        then:
        !ec.message.hasError()
        onHand(scarce) == 0
    }

    def "the ledger balances and the receipt has the tax per rate"() {
        given:
        ec.service.sync().name('growerp.100.TaxServices100.create#TaxRate')
                .parameters([taxRate: [taxName: 'VAT', taxPercentage: 10]]).call()

        when:
        Map sale = sell([line(gadget, 1), line(service1, 1)], [cash(22)])
        def entries = ec.entity.find('mantle.ledger.transaction.AcctgTransAndEntry')
                .condition('invoiceId', sale.invoiceId).useCache(false).list()

        then:
        !ec.message.hasError()
        sale.grandTotal as BigDecimal == 22
        sale.taxTotal as BigDecimal == 2
        sale.taxes.size() == 1
        sale.taxes[0].taxPercentage as BigDecimal == 10
        sale.taxes[0].taxAmount as BigDecimal == 2
        sale.lines.size() == 2
        sale.tenders[0].method == 'PiCash'
        entries.findAll { it.debitCreditFlag == 'C' }.sum { it.amount as BigDecimal } ==
                entries.findAll { it.debitCreditFlag == 'D' }.sum { it.amount as BigDecimal }
    }

    def "with tax in the price the customer pays the shelf price and the invoice is fully paid"() {
        given:
        ec.service.sync().name('growerp.100.TaxServices100.create#TaxRate')
                .parameters([taxRate: [taxName: 'VAT', taxPercentage: 21]]).call()
        ec.service.sync().name('growerp.100.TaxServices100.update#TaxSettings')
                .parameters([pricesIncludeTax: true]).call()

        when:
        Map quote = ec.service.sync().name("${service}.quote#PosSale")
                .parameters([lines: [line(service1, 3)]]).call()
        Map sale = sell([line(service1, 3)], [cash(30)])

        then:
        !ec.message.hasError()
        quote.grandTotal as BigDecimal == 30
        quote.taxTotal as BigDecimal == 5.21
        sale.grandTotal as BigDecimal == 30
        sale.taxTotal as BigDecimal == 5.21
        sale.changeAmount as BigDecimal == 0
        sale.lines[0].lineTotal as BigDecimal == 30
        invoiceOf(sale).statusId == 'InvoicePmtRecvd'
    }

    def "a sale is refused when the booked total differs from the quote"() {
        given: 'the quote charges tax, the gateway leaves an exempt customer without'
        Map rate = ec.service.sync().name('growerp.100.TaxServices100.create#TaxRate')
                .parameters([taxRate: [taxName: 'VAT', taxPercentage: 10]]).call().taxRate
        String walkIn = ec.service.sync().name("${service}.ensure#WalkInCustomer")
                .parameters([ownerPartyId: tenant.ownerPartyId]).call().walkInPartyId
        ec.service.sync().name('create#mantle.other.tax.TaxAuthorityParty')
                .parameters([partyId: walkIn, taxAuthorityId: rate.taxAuthorityId,
                        fromDate: ec.user.nowTimestamp, isExempt: 'Y']).call()
        long before = ec.entity.find('growerp.pos.PosSale').count()

        when:
        Map sale = sell([line(service1, 1)], [cash(11)])

        then: 'nothing is sold'
        sale == null
        ec.message.errorsString.contains('differs')
        ec.entity.find('growerp.pos.PosSale').count() == before

        cleanup:
        ec.message.clearErrors()
        ec.entity.find('mantle.other.tax.TaxAuthorityParty').condition('partyId', walkIn).deleteAll()
    }

    def "quote and sale agree to the cent on awkward amounts"() {
        given:
        ec.service.sync().name('growerp.100.TaxServices100.create#TaxRate')
                .parameters([taxRate: [taxName: 'VAT', taxPercentage: percentage]]).call()
        ec.service.sync().name('growerp.100.TaxServices100.update#TaxSettings')
                .parameters([pricesIncludeTax: inclusive]).call()
        Map odd = createProduct("Odd ${run} ${price} ${inclusive}", 'Service', price)
        Map other = createProduct("Other ${run} ${price} ${inclusive}", 'Service', 0.07)
        List lines = [line(odd, quantity), line(other, 3)]

        when:
        Map quote = ec.service.sync().name("${service}.quote#PosSale").parameters([lines: lines]).call()
        Map sale = sell(lines, [cash(quote.grandTotal as BigDecimal)])

        then:
        !ec.message.hasError()
        sale.grandTotal as BigDecimal == quote.grandTotal as BigDecimal
        sale.taxTotal as BigDecimal == quote.taxTotal as BigDecimal
        sale.changeAmount as BigDecimal == 0
        invoiceOf(sale).statusId == 'InvoicePmtRecvd'

        where:
        price | quantity | percentage | inclusive
        3.33  | 7        | 21         | true
        3.33  | 7        | 21         | false
        9.99  | 3        | 7.5        | true
        9.99  | 3        | 7.5        | false
        0.01  | 1        | 19         | true
        19.95 | 13       | 8.25       | true
    }

    def "the price comes from the catalog and a product of another tenant is refused"() {
        when: 'a price sent along is ignored'
        Map sale = sell([[productId: service1.productId, quantity: 1, price: 1]], [cash(10)])

        then:
        !ec.message.hasError()
        sale.grandTotal as BigDecimal == 10

        when:
        sell([line(foreign, 1)], [cash(10)])

        then:
        ec.message.hasError()
    }

    def "a sale of 50 lines stays fast enough for a till"() {
        given:
        ec.service.sync().name('growerp.100.TaxServices100.create#TaxRate')
                .parameters([taxRate: [taxName: 'VAT', taxPercentage: 10]]).call()

        when:
        long start = System.currentTimeMillis()
        Map sale = sell((1..50).collect { line(service1, 1) }, [cash(550)])
        long took = System.currentTimeMillis() - start
        println "50-line POS sale took ${took} ms"

        then:
        !ec.message.hasError()
        sale.grandTotal as BigDecimal == 550
        took < 5000
    }

    def "a barcode finds the product of the own tenant only"() {
        given:
        String code = "87${run}".toString()
        ec.service.sync().name('create#mantle.product.ProductIdentification')
                .parameters([productId: gadget.productId, productIdTypeEnumId: 'PidtEan', idValue: code]).call()

        when:
        Map found = ec.service.sync().name("${service}.get#ProductByBarcode").parameters([barcode: code]).call()

        then:
        !ec.message.hasError()
        found.item.productId == gadget.productId
        found.item.price as BigDecimal == 10

        when:
        ec.user.internalLoginUser(otherTenant.username)
        ec.service.sync().name("${service}.get#ProductByBarcode").parameters([barcode: code]).call()

        then:
        ec.message.hasError()
    }

    def "the catalog lists the products with price and the tax setting"() {
        when:
        Map catalog = ec.service.sync().name("${service}.get#PosCatalog").call()

        then:
        !ec.message.hasError()
        catalog.items.find { it.productId == service1.productId }.price as BigDecimal == 10
        catalog.pricesIncludeTax == false
        catalog.currencyId == 'USD'
    }

    Map refund(Map sale, List lines, Map options = [:]) {
        return ec.service.sync().name("${service}.create#PosRefund")
                .parameters([clientRefundId: "${run}-r${++saleCount}".toString(), clientSaleId: sale.clientSaleId,
                        terminalName: "Till 1 ${run}".toString(), lines: lines] + options).call()?.refund
    }

    Map refundLine(Map sale, int index, BigDecimal quantity) {
        return [orderItemSeqId: sale.lines[index].orderItemSeqId, quantity: quantity]
    }

    def "a part of a sale is refunded in cash with its tax, stock back and the ledger balanced"() {
        given:
        ec.service.sync().name('growerp.100.TaxServices100.create#TaxRate')
                .parameters([taxRate: [taxName: 'VAT', taxPercentage: 10]]).call()
        Map sale = sell([line(gadget, 3)], [cash(33)])
        BigDecimal before = onHand(gadget)

        when:
        Map done = refund(sale, [refundLine(sale, 0, 1)], [restock: true])
        def payment = ec.entity.find('mantle.account.payment.Payment').condition('paymentId', done.paymentId)
                .useCache(false).one()
        def entries = ec.entity.find('mantle.ledger.transaction.AcctgTransAndEntry')
                .condition('paymentId', done.paymentId).useCache(false).list()

        then:
        !ec.message.hasError()
        done.amount as BigDecimal == 11
        payment.amount as BigDecimal == 11
        payment.statusId == 'PmntDelivered'
        payment.paymentInstrumentEnumId == 'PiCash'
        onHand(gadget) == before + 1
        entries
        entries.findAll { it.debitCreditFlag == 'C' }.sum { it.amount as BigDecimal } ==
                entries.findAll { it.debitCreditFlag == 'D' }.sum { it.amount as BigDecimal }

        when: 'the credit memo is settled by the refund'
        def memo = ec.entity.find('mantle.account.invoice.Invoice').condition('invoiceId', payment.forInvoiceId)
                .useCache(false).one()

        then:
        memo.invoiceTypeEnumId == 'InvoiceReturn'
        memo.invoiceTotal as BigDecimal == 11
        ec.entity.find('mantle.account.payment.PaymentApplication').condition('paymentId', done.paymentId)
                .useCache(false).list().sum { it.amountApplied as BigDecimal } == 11
    }

    def "without restock the stock stays, a card sale refunds to the card"() {
        given:
        Map sale = sell([line(gadget, 1)], [[method: 'PiCreditCard', amount: 10, reference: 'A1']])
        BigDecimal before = onHand(gadget)

        when:
        Map done = refund(sale, [refundLine(sale, 0, 1)], [restock: false])

        then:
        !ec.message.hasError()
        onHand(gadget) == before
        ec.entity.find('mantle.account.payment.Payment').condition('paymentId', done.paymentId).useCache(false)
                .one().paymentInstrumentEnumId == 'PiCreditCard'
    }

    def "with tax in the price a full refund gives the shelf price back"() {
        given:
        ec.service.sync().name('growerp.100.TaxServices100.create#TaxRate')
                .parameters([taxRate: [taxName: 'VAT', taxPercentage: 21]]).call()
        ec.service.sync().name('growerp.100.TaxServices100.update#TaxSettings')
                .parameters([pricesIncludeTax: true]).call()
        Map sale = sell([line(service1, 3)], [cash(30)])

        when:
        Map done = refund(sale, [refundLine(sale, 0, 3)])

        then:
        !ec.message.hasError()
        done.amount as BigDecimal == 30
    }

    def "no more can be refunded than was sold"() {
        given:
        Map sale = sell([line(service1, 2)], [cash(20)])

        when:
        refund(sale, [refundLine(sale, 0, 1)])
        Map found = ec.service.sync().name("${service}.get#PosSaleLookup")
                .parameters([search: sale.invoicePseudoId]).call().sale

        then:
        !ec.message.hasError()
        found.lines[0].returnableQuantity as BigDecimal == 1

        when:
        refund(sale, [refundLine(sale, 0, 2)])

        then:
        ec.message.hasError()
    }

    def "a retry of a refund gives the same refund"() {
        given:
        Map sale = sell([line(service1, 2)], [cash(20)])
        String id = "${run}-rr".toString()
        Map parameters = [clientRefundId: id, clientSaleId: sale.clientSaleId, terminalName: "Till 1 ${run}".toString(),
                lines: [refundLine(sale, 0, 1)]]

        when:
        Map first = ec.service.sync().name("${service}.create#PosRefund").parameters(parameters).call().refund
        Map second = ec.service.sync().name("${service}.create#PosRefund").parameters(parameters).call().refund

        then:
        !ec.message.hasError()
        second.paymentId == first.paymentId
        ec.entity.find('mantle.account.payment.Payment').condition('forInvoiceId', sale.invoiceId)
                .useCache(false).list().size() == 1

        when:
        ec.service.sync().name("${service}.create#PosRefund")
                .parameters(parameters + [lines: [refundLine(sale, 0, 2)]]).call()

        then:
        ec.message.hasError()
    }

    def "a cashier sells and closes the till, the list of shifts is for the admin"() {
        given:
        String email = "seller-${run}@spock.example.com".toString()
        ec.service.sync().name('growerp.100.PartyServices100.create#User')
                .parameters([user: [firstName: 'Sel', lastName: 'Ler', role: 'OrgInternal',
                        email: email, loginName: email, userGroupId: 'GROWERP_M_EMPLOYEE']]).call()

        when:
        ec.user.internalLoginUser(email)
        Map sale = sell([line(service1, 1)], [cash(10)])

        then:
        ec.user.isInGroup('GROWERP_M_EMPLOYEE')
        !ec.message.hasError()
        sale.invoiceId

        when:
        ec.service.sync().name("${service}.get#PosShifts").call()

        then:
        ec.message.errorsString.contains('admin')
    }

    def "only an admin refunds and a sale of another tenant cannot be found"() {
        given:
        Map sale = sell([line(service1, 1)], [cash(10)])
        String email = "cashier-${run}@spock.example.com".toString()
        ec.service.sync().name('growerp.100.PartyServices100.create#User')
                .parameters([user: [firstName: 'Cas', lastName: 'Hier', role: 'OrgInternal',
                        email: email, loginName: email, userGroupId: 'GROWERP_M_EMPLOYEE']]).call()

        when:
        ec.user.internalLoginUser(email)
        refund(sale, [refundLine(sale, 0, 1)])

        then:
        ec.message.hasError()
        ec.message.errorsString.contains('admin')

        when:
        ec.message.clearErrors()
        ec.user.internalLoginUser(otherTenant.username)
        ec.service.sync().name("${service}.get#PosSaleLookup").parameters([search: sale.invoicePseudoId]).call()

        then:
        ec.message.hasError()
    }

    def "a sale and a refund need an open shift on the till"() {
        when:
        Map sale = sell([line(service1, 1)], [cash(10)], null, 'Never opened')

        then:
        sale == null
        ec.message.hasError()
        ec.message.errorsString.contains('no open shift')

        when:
        ec.message.clearErrors()
        Map paid = sell([line(service1, 1)], [cash(10)])
        ec.service.sync().name("${service}.create#PosRefund")
                .parameters([clientRefundId: "${run}-noshift".toString(), clientSaleId: paid.clientSaleId,
                        terminalName: 'Never opened', lines: [refundLine(paid, 0, 1)]]).call()

        then:
        ec.message.hasError()
    }

    def "a till has one open shift and a closed shift cannot change"() {
        given:
        Map shift = openShift("Till 3 ${run}".toString(), 50)

        when: 'opened twice'
        Map second = openShift("Till 3 ${run}".toString(), 50)

        then:
        second == null
        ec.message.errorsString.contains('open')

        when:
        ec.message.clearErrors()
        Map report = closeShift(shift, 50)

        then:
        !ec.message.hasError()
        report.status == 'Closed'

        when: 'closed again'
        closeShift(shift, 1)

        then:
        ec.message.hasError()

        when:
        ec.message.clearErrors()
        cashMovement(shift, 5, 'late')

        then:
        ec.message.hasError()

        when: 'the till opens again with a new shift'
        ec.message.clearErrors()
        Map next = openShift("Till 3 ${run}".toString(), 10)

        then:
        !ec.message.hasError()
        next.shiftId != shift.shiftId
        closeShift(next, 10).status == 'Closed'
    }

    def "the z report adds up the shift and a shortage goes to the ledger"() {
        given:
        ec.service.sync().name('growerp.100.TaxServices100.create#TaxRate')
                .parameters([taxRate: [taxName: 'VAT', taxPercentage: 10]]).call()
        Map shift = openShift("Till 2 ${run}".toString(), 100)
        Map cashSale = sell([line(service1, 2)], [cash(50)], null, "Till 2 ${run}".toString())
        sell([line(service1, 1)], [[method: 'PiCreditCard', amount: 11]], null, "Till 2 ${run}".toString())
        ec.service.sync().name("${service}.create#PosRefund")
                .parameters([clientRefundId: "${run}-z".toString(), clientSaleId: cashSale.clientSaleId,
                        terminalName: "Till 2 ${run}".toString(), lines: [refundLine(cashSale, 0, 1)]]).call()
        cashMovement(shift, -15, 'To the safe')
        cashMovement(shift, 5, 'Change float')

        when:
        Map open = ec.service.sync().name("${service}.get#ZReport").parameters([shiftId: shift.shiftId]).call().report

        then: 'float 100 + cash 22 - refund 11 - 15 + 5'
        !ec.message.hasError()
        open.status == 'Open'
        open.expectedCash as BigDecimal == 101
        open.saleCount == 2
        open.salesTotal as BigDecimal == 33
        open.tenders.find { it.method == 'PiCash' }.amount as BigDecimal == 22
        open.tenders.find { it.method == 'PiCreditCard' }.amount as BigDecimal == 11
        open.refundTotal as BigDecimal == 11
        open.taxes[0].taxAmount as BigDecimal == 3
        open.refundTaxTotal as BigDecimal == 1
        open.movementTotal as BigDecimal == -10

        when: 'two short'
        Map report = closeShift(shift, 99)
        List entries = shiftEntries(shift)

        then:
        !ec.message.hasError()
        report.countedCash as BigDecimal == 99
        report.variance as BigDecimal == -2
        entries.size() == 2
        entries.find { it.debitCreditFlag == 'D' }.amount as BigDecimal == 2
    }

    def "cash over goes to income, an exact count posts nothing"() {
        given:
        Map over = openShift("Till 4 ${run}".toString(), 10)
        Map exact = openShift("Till 5 ${run}".toString(), 10)

        when:
        closeShift(over, 11)
        closeShift(exact, 10)
        List overEntries = shiftEntries(over)
        List exactEntries = shiftEntries(exact)

        then:
        !ec.message.hasError()
        overEntries.find { it.debitCreditFlag == 'C' }.amount as BigDecimal == 1
        exactEntries.isEmpty()
    }

    def "shifts are listed, another tenant sees none of them"() {
        when:
        List shifts = ec.service.sync().name("${service}.get#PosShifts").parameters([limit: 50]).call().shifts

        then:
        !ec.message.hasError()
        shifts.find { it.terminalName == "Till 1 ${run}".toString() }.status == 'Open'
        shifts.every { it.openingFloat instanceof String && it.openedDate instanceof String }

        when:
        String shiftId = shifts[0].shiftId
        ec.user.internalLoginUser(otherTenant.username)
        ec.service.sync().name("${service}.get#ZReport").parameters([shiftId: shiftId]).call()

        then:
        ec.message.hasError()

        when:
        ec.message.clearErrors()
        List foreign = ec.service.sync().name("${service}.get#PosShifts").parameters([limit: 50]).call().shifts

        then:
        foreign.isEmpty()
    }

    def "a receipt can be read again, by the own tenant only"() {
        given:
        String id = "${run}-receipt".toString()
        sell([line(service1, 1)], [cash(10)], id)

        when:
        Map receipt = ec.service.sync().name("${service}.get#PosReceipt").parameters([clientSaleId: id]).call().sale

        then:
        !ec.message.hasError()
        receipt.grandTotal as BigDecimal == 10
        receipt.terminalName == "Till 1 ${run}".toString()

        when:
        ec.user.internalLoginUser(otherTenant.username)
        ec.service.sync().name("${service}.get#PosReceipt").parameters([clientSaleId: id]).call()

        then:
        ec.message.hasError()
    }
}
