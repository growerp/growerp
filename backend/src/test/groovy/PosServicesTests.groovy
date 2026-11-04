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

    Map sell(List lines, List tenders, String clientSaleId = null) {
        return ec.service.sync().name("${service}.create#PosSale")
                .parameters([clientSaleId: clientSaleId ?: "${run}-${++saleCount}".toString(),
                        terminalName: 'Till 1', lines: lines, tenders: tenders]).call()?.sale
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

    def "a receipt can be read again, by the own tenant only"() {
        given:
        String id = "${run}-receipt".toString()
        sell([line(service1, 1)], [cash(10)], id)

        when:
        Map receipt = ec.service.sync().name("${service}.get#PosReceipt").parameters([clientSaleId: id]).call().sale

        then:
        !ec.message.hasError()
        receipt.grandTotal as BigDecimal == 10
        receipt.terminalName == 'Till 1'

        when:
        ec.user.internalLoginUser(otherTenant.username)
        ec.service.sync().name("${service}.get#PosReceipt").parameters([clientSaleId: id]).call()

        then:
        ec.message.hasError()
    }
}
