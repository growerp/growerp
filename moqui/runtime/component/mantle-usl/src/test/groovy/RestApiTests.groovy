/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

import org.moqui.Moqui
import org.moqui.context.ExecutionContext
import org.moqui.screen.ScreenTest
import org.moqui.screen.ScreenTest.ScreenTestRender
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import spock.lang.Shared
import spock.lang.Specification
import spock.lang.Unroll

class RestApiTests extends Specification {
    protected final static Logger logger = LoggerFactory.getLogger(RestApiTests.class)

    static final String token = 'TestSessionToken'

    @Shared
    ExecutionContext ec
    @Shared
    ScreenTest screenTest

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        ec.user.loginUser("john.doe", "moqui")
        screenTest = ec.screen.makeTest().baseScreenPath("rest")

        ec.entity.tempSetSequencedIdPrimary("mantle.account.method.PaymentGatewayResponse", 55800, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.ledger.transaction.AcctgTrans", 55800, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.shipment.Shipment", 55800, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.shipment.ShipmentItemSource", 55800, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.asset.Asset", 55800, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.asset.AssetDetail", 55800, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.issuance.AssetReservation", 55800, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.issuance.AssetIssuance", 55800, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.account.invoice.Invoice", 55800, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.account.payment.Payment", 55800, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.account.payment.PaymentApplication", 55800, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.order.OrderHeader", 55800, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.order.OrderItemBilling", 55800, 10)
    }

    def cleanupSpec() {
        long totalTime = System.currentTimeMillis() - screenTest.startTime
        logger.info("Rendered ${screenTest.renderCount} screens (${screenTest.errorCount} errors) in ${ec.l10n.format(totalTime/1000, "0.000")}s, output ${ec.l10n.format(screenTest.renderTotalChars/1000, "#,##0")}k chars")

        ec.entity.tempResetSequencedIdPrimary("mantle.account.method.PaymentGatewayResponse")
        ec.entity.tempResetSequencedIdPrimary("mantle.ledger.transaction.AcctgTrans")
        ec.entity.tempResetSequencedIdPrimary("mantle.shipment.Shipment")
        ec.entity.tempResetSequencedIdPrimary("mantle.shipment.ShipmentItemSource")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.asset.Asset")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.asset.AssetDetail")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.issuance.AssetReservation")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.issuance.AssetIssuance")
        ec.entity.tempResetSequencedIdPrimary("mantle.account.invoice.Invoice")
        ec.entity.tempResetSequencedIdPrimary("mantle.account.payment.Payment")
        ec.entity.tempResetSequencedIdPrimary("mantle.account.payment.PaymentApplication")
        ec.entity.tempResetSequencedIdPrimary("mantle.order.OrderHeader")
        ec.entity.tempResetSequencedIdPrimary("mantle.order.OrderItemBilling")
        ec.destroy()
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
    }

    def cleanup() {
        ec.artifactExecution.enableAuthz()
    }

    def "calculate GL Account Org Summaries for Accounting Tests"() {
        when:
        // this is very late in the mantle tests, do this here to get all data
        // recalculate summaries, create GlAccountOrgTimePeriod records
        ec.service.sync().name("mantle.ledger.LedgerServices.recalculate#GlAccountOrgSummaries").call()

        then:
        true
    }

    @Unroll
    def "call Moqui Tools REST API (#requestMethod, #screenPath, #containsTextList)"() {
        expect:
        ScreenTestRender str = screenTest.render(screenPath, parameters, requestMethod)
        // logger.info("Rendered ${screenPath} in ${str.getRenderTime()}ms, output:\n${str.output}")
        boolean containsAll = true
        for (String containsText in containsTextList) {
            boolean contains = containsText ? str.assertContains(containsText) : true
            if (!contains) {
                logger.info("In ${screenPath} text [${containsText}] not found:\n${str.output}")
                containsAll = false
            }

        }

        // assertions
        !str.errorMessages
        containsAll

        where:
        requestMethod | screenPath | parameters | containsTextList

        // Order to Cash
        // TODO: better to not require session token in Service REST API calls?
        "put" | "s1/mantle/orders/productQuantity" | [productId:'DEMO_1_1', quantity:1, customerPartyId:'CustJqp',
                productStoreId:'POPC_DEFAULT', moquiSessionToken:token] | ['55800']
        "put" | "s1/mantle/orders/productQuantity" | [productId:'DEMO_1_1', quantity:1, orderId:'55800',
                                                      moquiSessionToken:token] | ['55800', '01']
        "put" | "s1/mantle/orders/55800/shippingBilling" | [paymentMethodId:'CustJqpCc',
                shippingPostalContactMechId:'CustJqpAddr', shippingTelecomContactMechId:'CustJqpTeln',
                carrierPartyId:'_NA_', shipmentMethodEnumId:'ShMthGround', moquiSessionToken:token] | ['paymentId', '55800']
        "post" | "s1/mantle/orders/55800/place" | [moquiSessionToken:token] | ['"statusChanged" : true']
        "post" | "s1/mantle/orders/55800/approve" | [moquiSessionToken:token] | ['"statusChanged" : true']
        "get" | "s1/mantle/payments/55800" | null | ['CustJqpCc', 'PiCreditCard', 'PmntAuthorized', 'ORG_ZIZI_RETAIL']
        "get" | "s1/mantle/orders/55800/items/01/reservations" | null |
                ['"assetReservationId" : "55800"', '"orderId" : "55800"', '"productId" : "DEMO_1_1"']

        "post" | "s1/mantle/orders/55800/parts/01/shipments" | [moquiSessionToken:token] | ['"shipmentId" : "55800"']
        "get" | "s1/mantle/orders/55800/items/01/billings" | null | ['"orderItemBillingId" : "55800"', '"orderId" : "55800"',
                '"orderItemSeqId" : "01"', '"invoiceId" : "55800"', '"assetIssuanceId" : "55800"', '"shipmentId" : "55800"']
        "get" | "s1/mantle/orders/55800/items/01/shipments" | null | ['"shipmentItemSourceId" : "55800"',
                '"shipmentId" : "55800"', '"productId" : "DEMO_1_1"', '"orderId" : "55800"', '"orderItemSeqId" : "01"',
                '"invoiceId" : "55800"']
        "get" | "s1/mantle/orders/55800/items/01/issuances" | null | ['"assetIssuanceId" : "55800"', '"orderId" : "55800"',
                '"orderItemSeqId" : "01"', '"shipmentId" : "55800"']
    }
}
