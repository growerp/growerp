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

/* Tests for orders, invoices, payments and shipments (FinDocServices100):
   - a sales order: create, update, approve (creates invoice, payment and
     shipment), the invoice total
   - a purchase order: approve and receive the incoming shipment into a location
   - a stand-alone invoice and payment
   - another tenant does not see the documents

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class FinDocServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant, otherTenant, customer, supplier, product, location
    @Shared String service = 'growerp.100.FinDocServices100'
    @Shared String run = Long.toString(System.currentTimeMillis(), 36)

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        otherTenant = GrowerpTestSupport.tenant(ec, 'FinDocTestOther')
        tenant = GrowerpTestSupport.tenant(ec, 'FinDocTest')
        customer = ec.service.sync().name('growerp.100.PartyServices100.create#User')
                .parameters([user: [firstName: 'Carl', lastName: "Customer${run}", role: 'Customer',
                        email: "carl-${run}@spock.example.com",
                        // a sales order is only approved with a shipping address
                        company: [name: "Buyer ${run}", role: 'Customer',
                                address: [address1: '1 Main Street', city: 'Springfield',
                                        postalCode: '12345', country: 'United States']]]]).call().user
        supplier = ec.service.sync().name('growerp.100.PartyServices100.create#User')
                .parameters([user: [firstName: 'Sue', lastName: "Supplier${run}", role: 'Supplier',
                        company: [name: "Seller ${run}", role: 'Supplier']]]).call().user
        product = ec.service.sync().name('growerp.100.CatalogServices100.create#Product')
                .parameters([product: [productName: "Gadget ${run}", productTypeId: 'Physical Good',
                        price: 10, useWarehouse: true]]).call().product
        location = ec.service.sync().name('growerp.100.InventoryServices100.create#Location')
                .parameters([location: [locationName: "Dock ${run}"]]).call().location
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def cleanup() {
        ec.message.clearErrors()
        if (ec.user.username != tenant.username) ec.user.internalLoginUser(tenant.username)
    }

    /** an item the way the frontend sends it */
    Map productItem(String description, BigDecimal quantity, BigDecimal price) {
        return [itemType: [itemTypeId: 'ItemProduct'], product: [productId: product.productId],
                description: description, quantity: quantity, price: price]
    }

    /** status sequence of an order: FinDocPrep -> FinDocCreated -> FinDocApproved */
    void approveOrder(String orderId, boolean sales) {
        ['FinDocCreated', 'FinDocApproved'].each {
            updateFinDoc([docType: 'order', sales: sales, orderId: orderId, statusId: it])
        }
    }

    Map createFinDoc(Map finDoc) {
        return ec.service.sync().name("${service}.create#FinDoc").parameters([finDoc: finDoc]).call()?.finDoc
    }

    Map getFinDoc(Map parameters) {
        // an unknown single document is an error, not an empty list
        List finDocs = ec.service.sync().name("${service}.get#FinDoc").parameters(parameters).call()?.finDocs
        return finDocs ? finDocs[0] : null
    }

    Map updateFinDoc(Map finDoc) {
        return ec.service.sync().name("${service}.update#FinDoc").parameters([finDoc: finDoc]).call()?.finDoc
    }

    def "a sales order is created, changed and approved into an invoice and a payment"() {
        when:
        Map order = createFinDoc([docType: 'order', sales: true, description: "Order ${run}",
                otherUser: [partyId: customer.partyId], otherCompany: [partyId: customer.company.partyId],
                items: [productItem('Gadget', 2, 10)]])

        then:
        !ec.message.hasError()
        order.orderId
        order.pseudoId
        order.statusId == 'FinDocPrep'
        order.grandTotal as BigDecimal == 20

        when: 'the quantity changes'
        Map updated = updateFinDoc([docType: 'order', sales: true, orderId: order.orderId,
                otherUser: [partyId: customer.partyId], otherCompany: [partyId: customer.company.partyId],
                items: [productItem('Gadget', 3, 10)]])

        then:
        !ec.message.hasError()
        updated.grandTotal as BigDecimal == 30

        when: 'it is approved'
        approveOrder(order.orderId, true)
        Map approved = getFinDoc([docType: 'order', sales: true, finDocId: order.orderId])

        then:
        !ec.message.hasError()
        approved.statusId == 'FinDocApproved'

        when: 'the invoice of the order is read'
        Map invoice = getFinDoc([docType: 'invoice', sales: true, search: order.pseudoId])

        then:
        invoice
        invoice.orderId == order.orderId
        invoice.grandTotal as BigDecimal == 30

        when: 'the payment of the order is read'
        Map payment = getFinDoc([docType: 'payment', sales: true, search: order.pseudoId])

        then:
        payment
        payment.grandTotal as BigDecimal == 30
    }

    def "a purchase order is approved and its shipment received into a location"() {
        given:
        Map order = createFinDoc([docType: 'order', sales: false, description: "Purchase ${run}",
                otherUser: [partyId: supplier.partyId], otherCompany: [partyId: supplier.company.partyId],
                items: [productItem('Gadget', 5, 4)]])

        when:
        approveOrder(order.orderId, false)
        Map shipment = getFinDoc([docType: 'shipment', sales: false, search: order.pseudoId])

        then:
        !ec.message.hasError()
        shipment
        shipment.shipmentId
        shipment.items*.product*.productId.contains(product.productId)

        when: 'the shipment is received'
        ec.service.sync().name("${service}.receive#Shipment")
                .parameters([finDoc: [docType: 'shipment', sales: false, shipmentId: shipment.shipmentId,
                        items: [[product: [productId: product.productId], quantity: 5,
                                asset: [location: [locationId: location.locationId]]]]]]).call()
        List assets = ec.service.sync().name('growerp.100.InventoryServices100.get#Assets')
                .parameters([productId: product.productId]).call().assets

        then:
        !ec.message.hasError()
        assets.find { it.location?.locationId == location.locationId }?.quantityOnHand as BigDecimal == 5
    }

    def "a stand-alone sales invoice and payment"() {
        when:
        Map invoice = createFinDoc([docType: 'invoice', sales: true, description: "Invoice ${run}",
                otherUser: [partyId: customer.partyId], otherCompany: [partyId: customer.company.partyId],
                items: [productItem('Service fee', 1, 99)]])

        then:
        !ec.message.hasError()
        invoice.invoiceId
        invoice.grandTotal as BigDecimal == 99

        when:
        Map payment = createFinDoc([docType: 'payment', sales: true, description: "Payment ${run}",
                paymentInstrument: 'Cash', grandTotal: 99,
                otherUser: [partyId: customer.partyId], otherCompany: [partyId: customer.company.partyId],
                items: [[paymentType: [paymentTypeId: 'PtInvoicePayment']]]])

        then:
        !ec.message.hasError()
        payment.paymentId
        payment.grandTotal as BigDecimal == 99
    }

    def "the order dashboard counts the sales orders"() {
        when:
        Map out = ec.service.sync().name("${service}.get#OrderDashboard").call()

        then:
        !ec.message.hasError()
        out.salesOrders as Integer >= 1
    }

    def "another tenant does not see the orders"() {
        given:
        Map order = createFinDoc([docType: 'order', sales: true, description: "Hidden ${run}",
                otherUser: [partyId: customer.partyId], otherCompany: [partyId: customer.company.partyId],
                items: [productItem('Gadget', 1, 10)]])

        when:
        ec.user.internalLoginUser(otherTenant.username)
        Map found = getFinDoc([docType: 'order', sales: true, finDocId: order.orderId])

        then:
        found == null
        ec.message.errorsString.contains('not found')
    }
}
