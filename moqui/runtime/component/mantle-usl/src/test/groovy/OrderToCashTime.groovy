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
import org.moqui.entity.EntityValue
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import spock.lang.Shared
import spock.lang.Specification

/* To run these make sure moqui, and mantle are in place and run:
    "gradle cleanAll load runtime/mantle/mantle-usl:test"
   Or to quick run with saved DB copy use "gradle loadSave" once then each time "gradle reloadSave runtime/mantle/mantle-usl:test"
 */
class OrderToCashTime extends Specification {
    @Shared
    protected final static Logger logger = LoggerFactory.getLogger(OrderToCashTime.class)
    @Shared
    ExecutionContext ec

    def setupSpec() {
        // init the framework, get the ec
        ec = Moqui.getExecutionContext()
    }

    def cleanupSpec() {
        ec.destroy()
        ec.factory.waitWorkerPoolEmpty(50) // up to 5 seconds
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
    }

    def cleanup() {
        ec.artifactExecution.enableAuthz()
    }

    def "Sales Order Time Check"() {
        when:
        int numOrders = 5

        long startTime = System.currentTimeMillis()
        for (int i = 0; i < numOrders; i++) {
            ec.user.loginUser("joe@public.com", "moqui")

            String productStoreId = "POPC_DEFAULT"
            EntityValue productStore = ec.entity.find("mantle.product.store.ProductStore").condition("productStoreId", productStoreId).useCache(true).one()
            String currencyUomId = productStore.defaultCurrencyUomId
            // String priceUomId = productStore.defaultCurrencyUomId
            // String defaultLocale = productStore.defaultLocale
            // String organizationPartyId = productStore.organizationPartyId
            // String vendorPartyId = productStore.organizationPartyId
            String customerPartyId = ec.user.userAccount.partyId

            Map addOut1 = ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                    .parameters([productId:'DEMO_1_1', quantity:1, customerPartyId:customerPartyId,
                        currencyUomId:currencyUomId, productStoreId:productStoreId]).call()

            String cartOrderId = addOut1.orderId
            String orderPartSeqId = addOut1.orderPartSeqId

            ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                    .parameters([orderId:cartOrderId, productId:'DEMO_3_1', quantity:1, customerPartyId:customerPartyId,
                        currencyUomId:currencyUomId, productStoreId:productStoreId]).call()
            ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                    .parameters([orderId:cartOrderId, productId:'DEMO_2_1', quantity:1, customerPartyId:customerPartyId,
                        currencyUomId:currencyUomId, productStoreId:productStoreId, requireInventory:false]).call()

            ec.service.sync().name("mantle.order.OrderServices.set#OrderBillingShippingInfo")
                    .parameters([orderId:cartOrderId, paymentMethodId:'CustJqpCc', shippingPostalContactMechId:'CustJqpAddr',
                        shippingTelecomContactMechId:'CustJqpTeln', carrierPartyId:'_NA_', shipmentMethodEnumId:'ShMthGround']).call()
            ec.service.sync().name("mantle.order.OrderServices.place#Order")
                    .parameters([orderId:cartOrderId, requireInventory:false]).call()

            ec.user.logoutUser()

            ec.user.loginUser("john.doe", "moqui")
            // explicitly approve order as john.doe (has pre-approve warnings for unavailable inventory so must be done explicitly)
            ec.service.sync().name("mantle.order.OrderServices.approve#Order").parameters([orderId:cartOrderId]).call()
            ec.service.sync().name("mantle.shipment.ShipmentServices.ship#OrderPart")
                    .parameters([orderId:cartOrderId, orderPartSeqId:orderPartSeqId]).call()
            ec.user.logoutUser()

            logger.info("[${i+1}/${numOrders} - ${System.currentTimeMillis() - startTime}] Created and shipped order ${cartOrderId}")
        }
        long endTime = System.currentTimeMillis()
        double seconds = (endTime - startTime)/1000
        logger.info("Created and shipped ${numOrders} in ${seconds} seconds, ${numOrders/seconds} orders per second")

        then:
        true
    }
}
