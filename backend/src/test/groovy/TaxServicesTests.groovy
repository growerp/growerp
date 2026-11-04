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

/* Tests for sales tax (TaxServices100):
   - a tenant without tax rates sees no tax at all
   - a default rate, a category rate, a product that is not taxable, an exempt
     customer and a rate that has expired, on orders
   - saving an order or a stand-alone invoice again does not add the tax twice
   - the tax of an approved order reaches the invoice and the ledger
   - purchase documents are never taxed
   - tax included in the price: a POS sale totals the shelf price
   - rates of another tenant neither apply nor can be changed

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class TaxServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant, otherTenant, customer, supplier, product, untaxed, drink, category
    @Shared String service = 'growerp.100.TaxServices100'
    @Shared String finDocService = 'growerp.100.FinDocServices100'
    @Shared String run = Long.toString(System.currentTimeMillis(), 36)

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        otherTenant = GrowerpTestSupport.tenant(ec, 'TaxTestOther')
        tenant = GrowerpTestSupport.tenant(ec, 'TaxTest')
        // the test database predates the seed data: this is what an upgrade runs
        ec.service.sync().name("${service}.migrate#TaxGateway").call()
        customer = ec.service.sync().name('growerp.100.PartyServices100.create#User')
                .parameters([user: [firstName: 'Carl', lastName: "Customer${run}", role: 'Customer',
                        email: "carl-${run}@spock.example.com",
                        company: [name: "Buyer ${run}", role: 'Customer',
                                address: [address1: '1 Main Street', city: 'Springfield',
                                        postalCode: '12345', country: 'United States']]]]).call().user
        supplier = ec.service.sync().name('growerp.100.PartyServices100.create#User')
                .parameters([user: [firstName: 'Sue', lastName: "Supplier${run}", role: 'Supplier',
                        company: [name: "Seller ${run}", role: 'Supplier']]]).call().user
        category = ec.service.sync().name('growerp.100.CatalogServices100.create#ProductCategory')
                .parameters([category: [categoryName: "Drinks ${run}"]]).call().category
        product = createProduct("Gadget ${run}", [])
        drink = createProduct("Beer ${run}", [[categoryId: category.categoryId]])
        untaxed = createProduct("Stamp ${run}", [])
        ec.entity.find('mantle.product.Product').condition('productId', untaxed.productId).forUpdate(true).one()
                .set('taxable', 'N').update()
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def cleanup() {
        ec.message.clearErrors()
        ec.user.internalLoginUser(tenant.username)
        ec.service.sync().name("${service}.get#TaxRates").call().taxRates.each {
            ec.service.sync().name("${service}.delete#TaxRate").parameters([taxRateId: it.taxRateId]).call()
        }
        ec.service.sync().name("${service}.update#TaxSettings").parameters([pricesIncludeTax: false]).call()
    }

    Map createProduct(String name, List categories) {
        return ec.service.sync().name('growerp.100.CatalogServices100.create#Product')
                .parameters([product: [productName: name, productTypeId: 'Service', price: 10,
                        categories: categories]]).call().product
    }

    Map createRate(Map rate) {
        return ec.service.sync().name("${service}.create#TaxRate").parameters([taxRate: rate]).call()?.taxRate
    }

    Map item(Map product, BigDecimal quantity, BigDecimal price) {
        return [itemType: [itemTypeId: 'ItemProduct'], product: [productId: product.productId],
                description: product.productName, quantity: quantity, price: price]
    }

    Map createFinDoc(Map finDoc) {
        return ec.service.sync().name("${finDocService}.create#FinDoc").parameters([finDoc: finDoc]).call()?.finDoc
    }

    Map updateFinDoc(Map finDoc) {
        return ec.service.sync().name("${finDocService}.update#FinDoc").parameters([finDoc: finDoc]).call()?.finDoc
    }

    Map getFinDoc(Map parameters) {
        List finDocs = ec.service.sync().name("${finDocService}.get#FinDoc").parameters(parameters).call()?.finDocs
        return finDocs ? finDocs[0] : null
    }

    Map salesOrder(List items) {
        return createFinDoc([docType: 'order', sales: true, description: "Order ${run}",
                otherUser: [partyId: customer.partyId], otherCompany: [partyId: customer.company.partyId],
                items: items])
    }

    BigDecimal orderTax(String orderId) {
        return ec.entity.find('mantle.order.OrderItem').condition('orderId', orderId)
                .condition('itemTypeEnumId', 'ItemSalesTax').useCache(false).list()
                .sum { (it.unitAmount as BigDecimal) * (it.quantity as BigDecimal) } as BigDecimal ?: 0
    }

    def "a tenant without tax rates is not charged tax"() {
        when:
        Map order = salesOrder([item(product, 2, 10)])

        then:
        !ec.message.hasError()
        order.grandTotal as BigDecimal == 20
        orderTax(order.orderId) == 0
    }

    def "a tax line entered by hand stays when the tenant has no rates"() {
        when:
        Map order = salesOrder([item(product, 2, 10),
                [itemType: [itemTypeId: 'ItemSalesTax'], description: 'Tourist tax', quantity: 1, price: 3]])

        then:
        !ec.message.hasError()
        orderTax(order.orderId) == 3
        getFinDoc([docType: 'order', sales: true, finDocId: order.orderId]).grandTotal as BigDecimal == 23
    }

    def "a default rate taxes the order and the tax is not doubled when saved again"() {
        given:
        createRate([taxName: 'VAT', taxPercentage: 10])

        when:
        Map order = salesOrder([item(product, 2, 10)])

        then:
        !ec.message.hasError()
        getFinDoc([docType: 'order', sales: true, finDocId: order.orderId]).grandTotal as BigDecimal == 22
        orderTax(order.orderId) == 2

        when: 'the order comes back with its tax line, the way the frontend saves it'
        Map read = getFinDoc([docType: 'order', sales: true, finDocId: order.orderId])
        updateFinDoc([docType: 'order', sales: true, orderId: order.orderId,
                otherUser: [partyId: customer.partyId], otherCompany: [partyId: customer.company.partyId],
                items: read.items])

        then:
        !ec.message.hasError()
        orderTax(order.orderId) == 2
        getFinDoc([docType: 'order', sales: true, finDocId: order.orderId]).grandTotal as BigDecimal == 22
    }

    def "a category rate beats the default rate"() {
        given:
        createRate([taxName: 'VAT', taxPercentage: 10])
        createRate([taxName: 'Alcohol', taxPercentage: 25, productCategoryId: category.categoryId])

        when:
        Map order = salesOrder([item(product, 1, 10), item(drink, 1, 10)])

        then:
        !ec.message.hasError()
        orderTax(order.orderId) == 3.5
    }

    def "a product that is not taxable and an exempt customer pay no tax"() {
        given:
        Map rate = createRate([taxName: 'VAT', taxPercentage: 10])

        when:
        Map order = salesOrder([item(untaxed, 1, 10)])

        then:
        orderTax(order.orderId) == 0

        when:
        ec.service.sync().name('create#mantle.other.tax.TaxAuthorityParty')
                .parameters([partyId: customer.company.partyId, taxAuthorityId: rate.taxAuthorityId,
                        fromDate: ec.user.nowTimestamp, isExempt: 'Y']).call()
        Map exempt = salesOrder([item(product, 1, 10)])
        ec.entity.find('mantle.other.tax.TaxAuthorityParty').condition('partyId', customer.company.partyId)
                .deleteAll()

        then:
        !ec.message.hasError()
        orderTax(exempt.orderId) == 0
    }

    def "a rate that expired does not apply"() {
        given:
        createRate([taxName: 'Old', taxPercentage: 10, thruDate: new java.sql.Timestamp(1000)])

        when:
        Map order = salesOrder([item(product, 1, 10)])

        then:
        !ec.message.hasError()
        orderTax(order.orderId) == 0
    }

    def "the tax of an approved order reaches the invoice and the ledger"() {
        given:
        createRate([taxName: 'VAT', taxPercentage: 10])
        Map order = salesOrder([item(product, 2, 10)])

        when:
        ['FinDocCreated', 'FinDocApproved'].each {
            updateFinDoc([docType: 'order', sales: true, orderId: order.orderId, statusId: it])
        }
        String invoiceId = ec.entity.find('mantle.order.OrderItemBilling').condition('orderId', order.orderId)
                .useCache(false).list()[0]?.invoiceId
        Map invoice = getFinDoc([docType: 'invoice', sales: true, finDocId: invoiceId])

        then:
        !ec.message.hasError()
        invoice.grandTotal as BigDecimal == 22

        when:
        def entries = ec.entity.find('mantle.ledger.transaction.AcctgTransAndEntry')
                .condition('invoiceId', invoiceId).useCache(false).list()

        then:
        entries.find { it.debitCreditFlag == 'C' && it.amount as BigDecimal == 2 }
        entries.findAll { it.debitCreditFlag == 'C' }.sum { it.amount as BigDecimal } == 22
        entries.findAll { it.debitCreditFlag == 'D' }.sum { it.amount as BigDecimal } == 22
    }

    def "a stand-alone sales invoice is taxed once, also when saved again"() {
        given:
        createRate([taxName: 'VAT', taxPercentage: 10])

        when:
        Map invoice = createFinDoc([docType: 'invoice', sales: true, description: "Invoice ${run}",
                otherUser: [partyId: customer.partyId], otherCompany: [partyId: customer.company.partyId],
                items: [item(product, 2, 10)]])

        then:
        !ec.message.hasError()
        getFinDoc([docType: 'invoice', sales: true, finDocId: invoice.invoiceId]).grandTotal as BigDecimal == 22

        when:
        Map read = getFinDoc([docType: 'invoice', sales: true, finDocId: invoice.invoiceId])
        updateFinDoc([docType: 'invoice', sales: true, invoiceId: invoice.invoiceId,
                otherUser: [partyId: customer.partyId], otherCompany: [partyId: customer.company.partyId],
                items: read.items])

        then:
        !ec.message.hasError()
        getFinDoc([docType: 'invoice', sales: true, finDocId: invoice.invoiceId]).grandTotal as BigDecimal == 22
    }

    def "purchase documents are not taxed"() {
        given:
        createRate([taxName: 'VAT', taxPercentage: 10])

        when:
        Map order = createFinDoc([docType: 'order', sales: false, description: "Purchase ${run}",
                otherUser: [partyId: supplier.partyId], otherCompany: [partyId: supplier.company.partyId],
                items: [item(product, 2, 10)]])
        Map invoice = createFinDoc([docType: 'invoice', sales: false, description: "Bill ${run}",
                otherUser: [partyId: supplier.partyId], otherCompany: [partyId: supplier.company.partyId],
                items: [item(product, 2, 10)]])

        then:
        !ec.message.hasError()
        order.grandTotal as BigDecimal == 20
        getFinDoc([docType: 'invoice', sales: false, finDocId: invoice.invoiceId]).grandTotal as BigDecimal == 20
    }

    def "a POS sale in a store with tax in the price totals the shelf price"() {
        given:
        createRate([taxName: 'VAT', taxPercentage: 21])
        ec.service.sync().name("${service}.update#TaxSettings").parameters([pricesIncludeTax: true]).call()
        String storeId = ec.entity.find('mantle.product.store.ProductStore')
                .condition('organizationPartyId', tenant.companyPartyId).list()[0].productStoreId

        when: 'three at 10 including tax, net 24.79'
        Map net = ec.service.sync().name("${service}.calculate#NetUnitAmount")
                .parameters([ownerPartyId: tenant.ownerPartyId, productId: product.productId,
                        grossUnitAmount: 10, quantity: 3]).call()
        Map order = ec.service.sync().name('mantle.order.OrderServices.create#Order')
                .parameters([customerPartyId: customer.company.partyId, vendorPartyId: tenant.companyPartyId,
                        productStoreId: storeId, salesChannelEnumId: 'ScPos', currencyUomId: 'USD']).call()
        ec.service.sync().name('mantle.order.OrderServices.create#OrderItem')
                .parameters([orderId: order.orderId, orderPartSeqId: order.orderPartSeqId,
                        itemTypeEnumId: 'ItemProduct', productId: product.productId, quantity: 3,
                        unitAmount: net.unitAmount, unitListPrice: 10, requireInventory: false]).call()
        def part = ec.entity.find('mantle.order.OrderPart').condition('orderId', order.orderId)
                .useCache(false).one()

        then:
        !ec.message.hasError()
        orderTax(order.orderId) == 5.21
        (part.partTotal as BigDecimal).setScale(2, BigDecimal.ROUND_HALF_UP) == 30
    }

    def "an order outside the POS stays tax on top in a store with tax in the price"() {
        given:
        createRate([taxName: 'VAT', taxPercentage: 10])
        ec.service.sync().name("${service}.update#TaxSettings").parameters([pricesIncludeTax: true]).call()

        when:
        Map order = salesOrder([item(product, 2, 10)])

        then:
        !ec.message.hasError()
        orderTax(order.orderId) == 2
    }

    def "rates of another tenant do not apply and cannot be changed"() {
        given:
        ec.user.internalLoginUser(otherTenant.username)
        Map foreign = createRate([taxName: 'Foreign', taxPercentage: 50])
        ec.user.internalLoginUser(tenant.username)

        when:
        Map order = salesOrder([item(product, 1, 10)])

        then:
        orderTax(order.orderId) == 0
        ec.service.sync().name("${service}.get#TaxRates").call().taxRates.isEmpty()

        when:
        ec.service.sync().name("${service}.update#TaxRate")
                .parameters([taxRate: [taxRateId: foreign.taxRateId, taxPercentage: 1]]).call()

        then:
        ec.message.hasError()

        cleanup:
        ec.message.clearErrors()
        ec.user.internalLoginUser(otherTenant.username)
        ec.service.sync().name("${service}.delete#TaxRate").parameters([taxRateId: foreign.taxRateId]).call()
    }

    def "a rate can be changed and needs a percentage"() {
        given:
        Map rate = createRate([taxName: 'VAT', taxPercentage: 10])

        when:
        Map updated = ec.service.sync().name("${service}.update#TaxRate")
                .parameters([taxRate: [taxRateId: rate.taxRateId, taxName: 'VAT high', taxPercentage: 21]])
                .call().taxRate

        then:
        !ec.message.hasError()
        updated.taxName == 'VAT high'
        updated.taxPercentage as BigDecimal == 21

        when:
        createRate([taxName: 'Empty'])

        then:
        ec.message.hasError()
    }
}
