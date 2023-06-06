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
import org.moqui.entity.EntityList
import org.moqui.entity.EntityValue
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import spock.lang.Shared
import spock.lang.Specification

import java.sql.Timestamp

/* To run these make sure moqui, and mantle are in place and run:
    "gradle cleanAll load runtime/mantle/mantle-usl:test"
   Or to quick run with saved DB copy use "gradle loadSave" once then each time "gradle reloadSave runtime/mantle/mantle-usl:test"
 */
class OrderToCashBasicFlow extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(OrderToCashBasicFlow.class)
    @Shared ExecutionContext ec
    @Shared String cartOrderId = null, cartOrderPartSeqId
    @Shared String inventoryOrderId = null
    @Shared Map setInfoOut, shipResult
    @Shared String b2bPaymentId, b2bShipmentId, b2bCredMemoId
    @Shared long effectiveTime = System.currentTimeMillis()
    // no longer needed: @Shared boolean kieEnabled = false
    @Shared long totalFieldsChecked = 0

    def setupSpec() {
        // init the framework, get the ec
        ec = Moqui.getExecutionContext()
        // set an effective date so data check works, etc
        ec.user.setEffectiveTime(new Timestamp(effectiveTime))
        // no longer needed: kieEnabled = ec.factory.getToolFactory("KIE") != null

        ec.entity.tempSetSequencedIdPrimary("mantle.account.method.PaymentGatewayResponse", 55500, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.ledger.transaction.AcctgTrans", 55500, 50)
        ec.entity.tempSetSequencedIdPrimary("mantle.shipment.Shipment", 55500, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.shipment.ShipmentItemSource", 55500, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.asset.Asset", 55500, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.asset.AssetDetail", 55500, 50)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.asset.PhysicalInventory", 55500, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.issuance.AssetReservation", 55500, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.issuance.AssetIssuance", 55500, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.account.invoice.Invoice", 55500, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.account.payment.Payment", 55500, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.account.payment.PaymentApplication", 55500, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.order.OrderHeader", 55500, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.order.OrderItemBilling", 55500, 20)
    }

    def cleanupSpec() {
        ec.entity.tempResetSequencedIdPrimary("mantle.account.method.PaymentGatewayResponse")
        ec.entity.tempResetSequencedIdPrimary("mantle.ledger.transaction.AcctgTrans")
        ec.entity.tempResetSequencedIdPrimary("mantle.shipment.Shipment")
        ec.entity.tempResetSequencedIdPrimary("mantle.shipment.ShipmentItemSource")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.asset.Asset")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.asset.AssetDetail")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.asset.PhysicalInventory")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.issuance.AssetReservation")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.issuance.AssetIssuance")
        ec.entity.tempResetSequencedIdPrimary("mantle.account.invoice.Invoice")
        ec.entity.tempResetSequencedIdPrimary("mantle.account.payment.Payment")
        ec.entity.tempResetSequencedIdPrimary("mantle.account.payment.PaymentApplication")
        ec.entity.tempResetSequencedIdPrimary("mantle.order.OrderHeader")
        ec.entity.tempResetSequencedIdPrimary("mantle.order.OrderItemBilling")
        ec.destroy()

        ec.factory.waitWorkerPoolEmpty(50) // up to 5 seconds
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
    }

    def cleanup() {
        ec.artifactExecution.enableAuthz()
    }

    def "create Sales Order"() {
        when:
        ec.user.loginUser("joe@public.com", "moqui")

        String productStoreId = "POPC_DEFAULT"
        EntityValue productStore = ec.entity.find("mantle.product.store.ProductStore").condition("productStoreId", productStoreId).one()
        String currencyUomId = productStore.defaultCurrencyUomId
        String priceUomId = productStore.defaultCurrencyUomId
        // String defaultLocale = productStore.defaultLocale
        // String organizationPartyId = productStore.organizationPartyId
        String vendorPartyId = productStore.organizationPartyId
        String customerPartyId = ec.user.userAccount.partyId

        Map priceMap = ec.service.sync().name("mantle.product.PriceServices.get#ProductPrice")
                .parameters([productId:'DEMO_1_1', priceUomId:priceUomId, productStoreId:productStoreId,
                    vendorPartyId:vendorPartyId, customerPartyId:customerPartyId]).call()

        Map addOut1 = ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                .parameters([productId:'DEMO_1_1', quantity:1, customerPartyId:customerPartyId,
                    currencyUomId:currencyUomId, productStoreId:productStoreId]).call()

        cartOrderId = addOut1.orderId
        cartOrderPartSeqId = addOut1.orderPartSeqId

        // disable tax and shipping calc so existing items don't get removed on recalc for order change
        ec.service.sync().name("mantle.order.OrderServices.update#OrderPart")
                .parameters([orderId:cartOrderId, orderPartSeqId:cartOrderPartSeqId, disablePromotions:'Y', disableShippingCalc:'Y', disableTaxCalc:'Y']).call()

        // without orderPartSeqId
        Map addOut2 = ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                .parameters([orderId:cartOrderId, productId:'DEMO_3_1', quantity:5]).call()
        // with orderPartSeqId
        Map addOut3 = ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                .parameters([orderId:cartOrderId, orderPartSeqId:cartOrderPartSeqId, productId:'DEMO_2_1', quantity:7, requireInventory:false]).call()

        // add discount and tax child items
        // item 1 sales tax
        ec.service.sync().name("mantle.order.OrderServices.create#OrderItem")
                .parameters([orderId:cartOrderId, orderPartSeqId:cartOrderPartSeqId, parentItemSeqId:addOut1.orderItemSeqId,
                    itemTypeEnumId:'ItemSalesTax', itemDescription:'Test Tax 7%', quantity:1, unitAmount:1.189]).call() // 16.99 * 0.07 = 1.1893
        // item 2 discount and sales tax, child qty == parent qty
        ec.service.sync().name("mantle.order.OrderServices.create#OrderItem")
                .parameters([orderId:cartOrderId, orderPartSeqId:cartOrderPartSeqId, parentItemSeqId:addOut2.orderItemSeqId,
                    itemTypeEnumId:'ItemDiscount', itemDescription:'Discount why? Because we love you.', quantity:5, unitAmount:-1.23]).call()
        ec.service.sync().name("mantle.order.OrderServices.create#OrderItem")
                .parameters([orderId:cartOrderId, orderPartSeqId:cartOrderPartSeqId, parentItemSeqId:addOut2.orderItemSeqId,
                    itemTypeEnumId:'ItemSalesTax', itemDescription:'Test Tax 7%', quantity:5, unitAmount:0.458]).call() // (7.77 - 1.23) * 0.07 = 0.4578
        // item 3 discount and sales tax, child qty != parent qty; sales tax with qty = 1 to simulate partial data coming from external system
        ec.service.sync().name("mantle.order.OrderServices.create#OrderItem")
                .parameters([orderId:cartOrderId, orderPartSeqId:cartOrderPartSeqId, parentItemSeqId:addOut3.orderItemSeqId,
                    itemTypeEnumId:'ItemDiscount', itemDescription:'Discount why? Because we love you.', quantity:4, unitAmount:-2.345]).call()
        ec.service.sync().name("mantle.order.OrderServices.create#OrderItem")
                .parameters([orderId:cartOrderId, orderPartSeqId:cartOrderPartSeqId, parentItemSeqId:addOut3.orderItemSeqId,
                    itemTypeEnumId:'ItemSalesTax', itemDescription:'Test Tax 7%', quantity:1, unitAmount:5.28]).call() // ((12.12 * 7) - (2.345 * 4)) * 0.07 = 5.2822

        // a pick assembly product
        Map addOut4 = ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                .parameters([orderId:cartOrderId, orderPartSeqId:cartOrderPartSeqId, productId:'DEMO_PA', quantity:2, unitAmount:30.0, requireInventory:false]).call()

        // add shipping charges, order part level not per item
        ec.service.sync().name("mantle.order.OrderServices.create#OrderItem")
                .parameters([orderId:cartOrderId, orderPartSeqId:cartOrderPartSeqId,
                    itemTypeEnumId:'ItemShipping', itemDescription:'Standard Shipping', quantity:1, unitAmount:6.77]).call()

        setInfoOut = ec.service.sync().name("mantle.order.OrderServices.set#OrderBillingShippingInfo")
                .parameters([orderId:cartOrderId, paymentMethodId:'CustJqpCc', shippingPostalContactMechId:'CustJqpAddr',
                    shippingTelecomContactMechId:'CustJqpTeln', carrierPartyId:'_NA_', shipmentMethodEnumId:'ShMthGround']).call()
        // place order
        ec.service.sync().name("mantle.order.OrderServices.place#Order")
                .parameters([orderId:cartOrderId, requireInventory:false]).call()

        ec.user.logoutUser()

        // explicitly approve order as john.doe (has pre-approve warnings for unavailable inventory so must be done explicitly)
        ec.user.loginUser("john.doe", "moqui")
        ec.service.sync().name("mantle.order.OrderServices.approve#Order").parameters([orderId:cartOrderId]).call()
        ec.user.logoutUser()

        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.order.OrderHeader orderId="${cartOrderId}" entryDate="${effectiveTime}" placedDate="${effectiveTime}"
                statusId="OrderApproved" currencyUomId="USD" productStoreId="POPC_DEFAULT" grandTotal="200.68"/>

            <mantle.account.payment.Payment paymentId="${setInfoOut.paymentId}" paymentTypeEnumId="PtInvoicePayment"
                paymentMethodId="CustJqpCc" paymentInstrumentEnumId="PiCreditCard" orderId="${cartOrderId}"
                orderPartSeqId="01" statusId="PmntAuthorized" amount="200.68"
                amountUomId="USD" fromPartyId="CustJqp" toPartyId="ORG_ZIZI_RETAIL"/>
            <mantle.account.method.PaymentGatewayResponse paymentGatewayResponseId="55500"
                paymentOperationEnumId="PgoAuthorize"
                paymentId="${setInfoOut.paymentId}" paymentMethodId="CustJqpCc" amount="200.68"
                amountUomId="USD" transactionDate="${effectiveTime}" resultSuccess="Y" resultDeclined="N" resultNsf="N"
                resultBadExpire="N" resultBadCardNumber="N"/>
            <!-- don't validate these, allow any payment gateway: paymentGatewayConfigId="TEST_APPROVE" referenceNum="TEST" -->

            <mantle.order.OrderPart orderId="${cartOrderId}" orderPartSeqId="01" vendorPartyId="ORG_ZIZI_RETAIL"
                customerPartyId="CustJqp" shipmentMethodEnumId="ShMthGround" postalContactMechId="CustJqpAddr"
                telecomContactMechId="CustJqpTeln" partTotal="200.68"/>
            <mantle.order.OrderItem orderId="${cartOrderId}" orderItemSeqId="01" orderPartSeqId="01" itemTypeEnumId="ItemProduct"
                productId="DEMO_1_1" itemDescription="Demo Product One-One" quantity="1" unitAmount="16.99"
                unitListPrice="19.99" isModifiedPrice="N"/>
            <mantle.order.OrderItem orderId="${cartOrderId}" orderItemSeqId="02" orderPartSeqId="01" itemTypeEnumId="ItemProduct"
                productId="DEMO_3_1" itemDescription="Demo Product Three-One" quantity="5" unitAmount="7.77"
                unitListPrice="" isModifiedPrice="N"/>
            <mantle.order.OrderItem orderId="${cartOrderId}" orderItemSeqId="03" orderPartSeqId="01" itemTypeEnumId="ItemProduct"
                productId="DEMO_2_1" itemDescription="Demo Product Two-One" quantity="7" unitAmount="12.12"
                unitListPrice="" isModifiedPrice="N"/>

            <!-- TODO PtPickAssembly add OrderItem for DEMO_PA -->

        </entity-facade-xml>""").check()
        logger.info("create Sales Order data check results: " + dataCheckErrors)

        then:
        priceMap.price == 16.99
        priceMap.priceUomId == 'USD'
        vendorPartyId == 'ORG_ZIZI_RETAIL'
        customerPartyId == 'CustJqp'

        dataCheckErrors.size() == 0
    }

    def "validate Asset Reservation"() {
        when:
        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <!-- Asset created, issued, changed record in detail -->

            <mantle.product.asset.Asset assetId="55400" acquireCost="8" acquireCostUomId="USD" productId="DEMO_1_1"
                statusId="AstAvailable" assetTypeEnumId="AstTpInventory" originalQuantity="400" quantityOnHandTotal="400"
                availableToPromiseTotal="187" facilityId="ZIRET_WH" ownerPartyId="ORG_ZIZI_RETAIL"
                hasQuantity="Y" assetName="Demo Product One-One"/>
            <mantle.product.issuance.AssetReservation assetReservationId="55500" assetId="55400" orderId="${cartOrderId}"
                orderItemSeqId="01" reservedDate="${effectiveTime}" quantity="1" productId="DEMO_1_1" sequenceNum="0"
                quantityNotIssued="1" quantityNotAvailable="0" reservationOrderEnumId="AsResOrdFifoRec"/>
            <mantle.product.asset.AssetDetail assetDetailId="55500" assetId="55400" productId="DEMO_1_1"
                assetReservationId="55500" availableToPromiseDiff="-1" effectiveDate="${effectiveTime}"/>

            <!-- this is an auto-created Asset based on the inventory issuance -->
            <mantle.product.asset.Asset assetId="55500" assetTypeEnumId="AstTpInventory" statusId="AstAvailable"
                ownerPartyId="ORG_ZIZI_RETAIL" productId="DEMO_2_1" hasQuantity="Y" quantityOnHandTotal="0"
                availableToPromiseTotal="-11" receivedDate="${effectiveTime}" facilityId="ZIRET_WH"/>
            <mantle.product.issuance.AssetReservation assetReservationId="55501" assetId="55500" productId="DEMO_2_1"
                orderId="${cartOrderId}" orderItemSeqId="03" reservationOrderEnumId="AsResOrdFifoRec"
                quantity="7" quantityNotAvailable="7" reservedDate="${effectiveTime}"/>
            <mantle.product.asset.AssetDetail assetDetailId="55501" assetId="55500" effectiveDate="${effectiveTime}"
                availableToPromiseDiff="-7" assetReservationId="55501" productId="DEMO_2_1"/>

            <!-- NOTE: before reserve against pick locations first used assetId DEMO_3_1A instead of 55401 -->
            <mantle.product.asset.Asset assetId="DEMO_3_1A" assetTypeEnumId="AstTpInventory" statusId="AstAvailable"
                ownerPartyId="ORG_ZIZI_RETAIL" productId="DEMO_3_1" hasQuantity="Y" quantityOnHandTotal="5"
                availableToPromiseTotal="0" receivedDate="1265184000000" facilityId="ZIRET_WH"/>
            <mantle.product.asset.Asset assetId="55401" assetTypeEnumId="AstTpInventory" statusId="AstAvailable"
                ownerPartyId="ORG_ZIZI_RETAIL" productId="DEMO_3_1" hasQuantity="Y" quantityOnHandTotal="100"
                availableToPromiseTotal="100" facilityId="ZIRET_WH"/>
            <mantle.product.issuance.AssetReservation assetReservationId="55502" assetId="DEMO_3_1A" productId="DEMO_3_1"
                orderId="${cartOrderId}" orderItemSeqId="02" reservationOrderEnumId="AsResOrdFifoRec" quantity="5"
                reservedDate="${effectiveTime}" sequenceNum="0"/>
            <mantle.product.asset.AssetDetail assetDetailId="55502" assetId="DEMO_3_1A" effectiveDate="${effectiveTime}"
                availableToPromiseDiff="-5" assetReservationId="55502" productId="DEMO_3_1"/>

            <!-- TODO PtPickAssembly AssetReservation records for assembly component products -->

        </entity-facade-xml>""").check()
        logger.info("validate Asset Reservation data check results: ")
        for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)

        then:
        dataCheckErrors.size() == 0
    }

    def "ship Sales Order"() {
        when:
        ec.user.loginUser("john.doe", "moqui")

        /* old approach, simple ship entire OrderPart:
        shipResult = ec.service.sync().name("mantle.shipment.ShipmentServices.ship#OrderPart")
                .parameters([orderId:cartOrderId, orderPartSeqId:cartOrderPartSeqId, tryAutoPackage:false]).call()
        */

        shipResult = ec.service.sync().name("mantle.shipment.ShipmentServices.create#OrderPartShipment")
                .parameters([orderId:cartOrderId, orderPartSeqId:cartOrderPartSeqId, createPackage:true]).call()

        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#ShipmentProduct")
                .parameters([productId:'DEMO_1_1', quantity:1, shipmentId:shipResult.shipmentId, shipmentPackageSeqId:shipResult.shipmentPackageSeqId]).call()
        // partial fill, 4 of 5
        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#ShipmentProduct")
                .parameters([productId:'DEMO_3_1', quantity:4, shipmentId:shipResult.shipmentId, shipmentPackageSeqId:shipResult.shipmentPackageSeqId]).call()
        // partial fill, 5 of 7
        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#ShipmentProduct")
                .parameters([productId:'DEMO_2_1', quantity:5, shipmentId:shipResult.shipmentId, shipmentPackageSeqId:shipResult.shipmentPackageSeqId]).call()

        // pack DEMO_PA by component using pack#ShipmentAssemblyComponent
        // pack DEMO_1_1 twice with qty 1 to test AssetIssuance consolidation
        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#ShipmentAssemblyComponent")
                .parameters([productId:'DEMO_1_1', assemblyProductId:'DEMO_PA', quantity:1,
                        shipmentId:shipResult.shipmentId, shipmentPackageSeqId:shipResult.shipmentPackageSeqId]).call()
        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#ShipmentAssemblyComponent")
                .parameters([productId:'DEMO_1_1', assemblyProductId:'DEMO_PA', quantity:1,
                        shipmentId:shipResult.shipmentId, shipmentPackageSeqId:shipResult.shipmentPackageSeqId]).call()
        // pack DEMO_2_1 twice with qty 2 to test produce and issue to shipment one assembly qty at a time
        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#ShipmentAssemblyComponent")
                .parameters([productId:'DEMO_2_1', assemblyProductId:'DEMO_PA', quantity:2,
                        shipmentId:shipResult.shipmentId, shipmentPackageSeqId:shipResult.shipmentPackageSeqId]).call()
        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#ShipmentAssemblyComponent")
                .parameters([productId:'DEMO_2_1', assemblyProductId:'DEMO_PA', quantity:2,
                        shipmentId:shipResult.shipmentId, shipmentPackageSeqId:shipResult.shipmentPackageSeqId]).call()

        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#Shipment").parameters([shipmentId:shipResult.shipmentId]).call()
        ec.service.sync().name("mantle.shipment.ShipmentServices.ship#Shipment").parameters([shipmentId:shipResult.shipmentId]).call()

        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <!-- Shipment created -->
            <mantle.shipment.Shipment shipmentId="${shipResult.shipmentId}" shipmentTypeEnumId="ShpTpSales"
                statusId="ShipShipped" fromPartyId="ORG_ZIZI_RETAIL" toPartyId="CustJqp"/>
            <mantle.shipment.ShipmentPackage shipmentId="${shipResult.shipmentId}" shipmentPackageSeqId="01"/>

            <mantle.shipment.ShipmentItem shipmentId="${shipResult.shipmentId}" productId="DEMO_1_1" quantity="1"/>
            <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55500" shipmentId="${shipResult.shipmentId}"
                productId="DEMO_1_1" orderId="${cartOrderId}" orderItemSeqId="01" statusId="SisPacked" quantity="1" quantityNotHandled="0"
                invoiceId="55500" invoiceItemSeqId="01"/>
            <mantle.shipment.ShipmentPackageContent shipmentId="${shipResult.shipmentId}" shipmentPackageSeqId="01"
                productId="DEMO_1_1" quantity="1"/>

            <mantle.shipment.ShipmentItem shipmentId="${shipResult.shipmentId}" productId="DEMO_3_1" quantity="4"/>
            <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55501" shipmentId="${shipResult.shipmentId}"
                productId="DEMO_3_1" orderId="${cartOrderId}" orderItemSeqId="02" statusId="SisPacked" quantity="4" quantityNotHandled="0"
                invoiceId="55500" invoiceItemSeqId="03"/>
            <mantle.shipment.ShipmentPackageContent shipmentId="${shipResult.shipmentId}" shipmentPackageSeqId="01"
                productId="DEMO_3_1" quantity="4"/>

            <mantle.shipment.ShipmentItem shipmentId="${shipResult.shipmentId}" productId="DEMO_2_1" quantity="5"/>
            <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55502" shipmentId="${shipResult.shipmentId}"
                productId="DEMO_2_1" orderId="${cartOrderId}" orderItemSeqId="03" statusId="SisPacked" quantity="5" quantityNotHandled="0"
                invoiceId="55500" invoiceItemSeqId="06"/>
            <mantle.shipment.ShipmentPackageContent shipmentId="${shipResult.shipmentId}" shipmentPackageSeqId="01"
                productId="DEMO_2_1" quantity="5"/>

            <!-- TODO PtPickAssembly ShipmentItem and Source for DEMO_PA -->

            <mantle.shipment.ShipmentRouteSegment shipmentId="${shipResult.shipmentId}" shipmentRouteSegmentSeqId="01"
                destPostalContactMechId="CustJqpAddr" destTelecomContactMechId="CustJqpTeln"/>
            <mantle.shipment.ShipmentPackageRouteSeg shipmentId="${shipResult.shipmentId}" shipmentPackageSeqId="01"
                shipmentRouteSegmentSeqId="01"/>
        </entity-facade-xml>""").check()
        logger.info("ship Sales Order data check results: ")
        for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)

        then:
        dataCheckErrors.size() == 0
    }

    def "close Partial Filled Order"() {
        when:
        ec.service.sync().name("mantle.order.OrderServices.cancel#Order").parameters([orderId:cartOrderId]).call()

        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <!-- OrderHeader status to Completed -->
            <mantle.order.OrderHeader orderId="${cartOrderId}" entryDate="${effectiveTime}" placedDate="${effectiveTime}"
                statusId="OrderCompleted" currencyUomId="USD" productStoreId="POPC_DEFAULT" grandTotal="170.61"/>
        </entity-facade-xml>""").check()
        logger.info("validate Sales Order Complete data check results: " + dataCheckErrors)

        then:
        dataCheckErrors.size() == 0
    }

    def "validate Asset Issuance"() {
        when:
        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <!-- Asset created, issued, change recorded in detail -->

            <mantle.product.asset.Asset assetId="55400" quantityOnHandTotal="397" availableToPromiseTotal="187"/>
            <mantle.product.issuance.AssetIssuance assetIssuanceId="55500" assetId="55400" orderId="${cartOrderId}"
                orderItemSeqId="01" issuedDate="${effectiveTime}" quantity="1" productId="DEMO_1_1"
                assetReservationId="55500" shipmentId="${shipResult.shipmentId}"/>
            <mantle.product.asset.AssetDetail assetDetailId="55505" assetId="55400" effectiveDate="${effectiveTime}"
                quantityOnHandDiff="-1" assetReservationId="55500" shipmentId="${shipResult.shipmentId}"
                productId="DEMO_1_1" assetIssuanceId="55500"/>

            <mantle.product.asset.Asset assetId="DEMO_3_1A" quantityOnHandTotal="1" availableToPromiseTotal="1"/>
            <mantle.product.asset.Asset assetId="55401" quantityOnHandTotal="100" availableToPromiseTotal="100"/>
            <mantle.product.issuance.AssetIssuance assetIssuanceId="55501" assetId="DEMO_3_1A" assetReservationId="55502"
                orderId="${cartOrderId}" orderItemSeqId="02" shipmentId="${shipResult.shipmentId}" productId="DEMO_3_1"
                quantity="4"/>
            <mantle.product.asset.AssetDetail assetDetailId="55506" assetId="DEMO_3_1A" effectiveDate="${effectiveTime}"
                quantityOnHandDiff="-4" assetReservationId="55502" shipmentId="${shipResult.shipmentId}"
                productId="DEMO_3_1" assetIssuanceId="55501"/>

            <!-- this is an auto-created Asset based on the inventory issuance -->
            <mantle.product.asset.Asset assetId="55500" quantityOnHandTotal="0" availableToPromiseTotal="0"/>
            <mantle.product.issuance.AssetIssuance assetIssuanceId="55502" assetId="55500" assetReservationId="55501"
                orderId="${cartOrderId}" orderItemSeqId="03" shipmentId="${shipResult.shipmentId}" productId="DEMO_2_1"
                quantity="5"/>
            <mantle.product.asset.AssetDetail assetDetailId="55507" assetId="55500" effectiveDate="${effectiveTime}"
                quantityOnHandDiff="-5" assetReservationId="55501" shipmentId="${shipResult.shipmentId}"
                productId="DEMO_2_1" assetIssuanceId="55502"/>
            <!-- the automatic physical inventory found record because QOH went below zero -->
            <mantle.product.asset.AssetDetail assetDetailId="55508" assetId="55500" physicalInventoryId="55500"
                availableToPromiseDiff="5" quantityOnHandDiff="5" productId="DEMO_2_1" varianceReasonEnumId="InVrFound"
                acctgTransResultEnumId="AtrNoAcquireCost"/>
        </entity-facade-xml>""").check()
        logger.info("validate Asset Issuance data check results: ")
        for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)

        then:
        dataCheckErrors.size() == 0
    }

    def "validate Asset Issuance Accounting Transactions"() {
        when:
        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55500" acctgTransTypeEnumId="AttInventoryIssuance"
                organizationPartyId="ORG_ZIZI_RETAIL" transactionDate="${effectiveTime}" isPosted="Y"
                postedDate="${effectiveTime}" glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD" assetId="55400"
                assetIssuanceId="55500"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55500" acctgTransEntrySeqId="01" debitCreditFlag="C"
                amount="8" glAccountTypeEnumId="GatInventory" glAccountId="141300000"
                reconcileStatusId="AterNot" isSummary="N" productId="DEMO_1_1"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55500" acctgTransEntrySeqId="02" debitCreditFlag="D"
                amount="8" glAccountTypeEnumId="GatCogs" glAccountId="512000000"
                reconcileStatusId="AterNot" isSummary="N" productId="DEMO_1_1"/>

            <mantle.ledger.transaction.AcctgTrans acctgTransId="55501" acctgTransTypeEnumId="AttInventoryIssuance"
                organizationPartyId="ORG_ZIZI_RETAIL" transactionDate="${effectiveTime}" isPosted="Y"
                postedDate="${effectiveTime}" glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD" assetId="DEMO_3_1A"
                assetIssuanceId="55501"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55501" acctgTransEntrySeqId="01" debitCreditFlag="C"
                amount="16" glAccountTypeEnumId="GatInventory" glAccountId="141300000"
                reconcileStatusId="AterNot" isSummary="N" productId="DEMO_3_1"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55501" acctgTransEntrySeqId="02" debitCreditFlag="D"
                amount="16" glAccountTypeEnumId="GatCogs" glAccountId="512000000"
                reconcileStatusId="AterNot" isSummary="N" productId="DEMO_3_1"/>

            <!-- NOTE: there is no AcctgTrans for assetId 55500, productId DEMO_2_1 because it is auto-created and has
                no acquireCost. -->
        </entity-facade-xml>""").check()
        logger.info("validate Shipment Invoice Accounting Transaction data check results: ")
        for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)

        then:
        dataCheckErrors.size() == 0
    }

    def "validate Shipment Invoice"() {
        when:
        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <!-- Invoice created and Finalized (status set by action in SECA rule), then Payment Received (status set by Payment application) -->

            <invoices invoiceId="55500" invoiceTypeEnumId="InvoiceSales" statusId="InvoicePmtRecvd" toPartyId="CustJqp" fromPartyId="ORG_ZIZI_RETAIL" 
                    description="For Order ${cartOrderId} part 01 and Shipment ${shipResult.shipmentId}" productStoreId="POPC_DEFAULT" 
                    settlementTermId="NetLastNext" acctgTransResultEnumId="AtrSuccess" invoiceDate="${effectiveTime}" 
                    currencyUomId="USD" invoiceTotal="170.61" unpaidTotal="0" appliedPaymentsTotal="170.61">
                <paymentApplications amountApplied="170.61" appliedDate="${effectiveTime}" acctgTransResultEnumId="AtrSuccess" paymentApplicationId="55500" paymentId="55500"/>

                <items invoiceItemSeqId="01" amount="16.99" quantity="1" productId="DEMO_1_1" description="Demo Product One-One" itemTypeEnumId="ItemProduct" assetId="55400">
                    <orderItemBillings orderItemSeqId="01" amount="16.99" quantity="1" orderId="${cartOrderId}" shipmentId="${shipResult.shipmentId}" assetIssuanceId="55500" orderItemBillingId="55500"/>
                    <issuances assetIssuanceId="55500" orderItemSeqId="01" issuedDate="${effectiveTime}" shipmentItemSourceId="55500" 
                        issuedByUserId="EX_JOHN_DOE" quantity="1" productId="DEMO_1_1" orderId="${cartOrderId}" assetReservationId="55500" 
                        acctgTransResultEnumId="AtrSuccess" assetId="55400" shipmentId="${shipResult.shipmentId}"/>
                    <shipmentItemSources shipmentItemSourceId="55500" orderId="${cartOrderId}" orderItemSeqId="01" quantity="1" 
                        productId="DEMO_1_1" statusId="SisPacked" quantityNotHandled="0" shipmentId="${shipResult.shipmentId}"/>
                </items>
                <items invoiceItemSeqId="02" parentItemSeqId="01" amount="1.189" quantity="1" description="Test Tax 7%" itemTypeEnumId="ItemSalesTax">
                    <orderItemBillings orderItemSeqId="04" amount="1.189" quantity="1" orderId="${cartOrderId}" shipmentId="${shipResult.shipmentId}" orderItemBillingId="55501"/>
                </items>
                <items invoiceItemSeqId="03" amount="7.77" quantity="4" productId="DEMO_3_1" description="Demo Product Three-One" itemTypeEnumId="ItemProduct" assetId="DEMO_3_1A">
                    <orderItemBillings orderItemSeqId="02" amount="7.77" quantity="4" orderId="${cartOrderId}" shipmentId="${shipResult.shipmentId}" assetIssuanceId="55501" orderItemBillingId="55502"/>
                    <issuances assetIssuanceId="55501" issuedDate="${effectiveTime}" shipmentItemSourceId="55501" issuedByUserId="EX_JOHN_DOE" 
                        quantity="4" productId="DEMO_3_1" orderId="${cartOrderId}" orderItemSeqId="02" assetReservationId="55502" 
                        acctgTransResultEnumId="AtrSuccess" assetId="DEMO_3_1A" shipmentId="${shipResult.shipmentId}"/>
                    <shipmentItemSources shipmentItemSourceId="55501" orderId="${cartOrderId}" orderItemSeqId="02" quantity="4" 
                        productId="DEMO_3_1" statusId="SisPacked" quantityNotHandled="0" shipmentId="${shipResult.shipmentId}"/>
                </items>
                <items invoiceItemSeqId="04" parentItemSeqId="03" amount="-1.23" quantity="4" description="Discount why? Because we love you." itemTypeEnumId="ItemDiscount">
                    <orderItemBillings orderItemSeqId="05" amount="-1.23" quantity="4" orderId="${cartOrderId}" shipmentId="${shipResult.shipmentId}" orderItemBillingId="55503"/>
                </items>
                <items invoiceItemSeqId="05" parentItemSeqId="03" amount="0.458" quantity="4" description="Test Tax 7%" itemTypeEnumId="ItemSalesTax">
                    <orderItemBillings orderItemSeqId="06" amount="0.458" quantity="4" orderId="${cartOrderId}" shipmentId="${shipResult.shipmentId}" orderItemBillingId="55504"/>
                </items>
                <items invoiceItemSeqId="06" amount="12.12" quantity="5" productId="DEMO_2_1" description="Demo Product Two-One" itemTypeEnumId="ItemProduct" assetId="55500">
                    <orderItemBillings orderItemSeqId="03" amount="12.12" quantity="5" orderId="${cartOrderId}" shipmentId="${shipResult.shipmentId}" assetIssuanceId="55502" orderItemBillingId="55505"/>
                    <issuances assetIssuanceId="55502" assetId="55500" issuedDate="${effectiveTime}" shipmentItemSourceId="55502" issuedByUserId="EX_JOHN_DOE" 
                        quantity="5" productId="DEMO_2_1" orderId="${cartOrderId}" orderItemSeqId="03" assetReservationId="55501" 
                        acctgTransResultEnumId="AtrNoAcquireCost" shipmentId="${shipResult.shipmentId}"/>
                    <shipmentItemSources shipmentItemSourceId="55502" quantity="5" orderId="${cartOrderId}" orderItemSeqId="03" 
                        productId="DEMO_2_1" statusId="SisPacked" quantityNotHandled="0" shipmentId="${shipResult.shipmentId}"/>
                </items>
                <items amount="-6.7" quantity="1" description="Discount why? Because we love you." invoiceItemSeqId="07" itemTypeEnumId="ItemDiscount" parentItemSeqId="06">
                    <orderItemBillings orderItemSeqId="07" amount="-6.7" quantity="1" orderId="${cartOrderId}" shipmentId="${shipResult.shipmentId}" orderItemBillingId="55506"/>
                </items>
                <items amount="3.77" quantity="1" description="Test Tax 7%" invoiceItemSeqId="08" itemTypeEnumId="ItemSalesTax" parentItemSeqId="06">
                    <orderItemBillings orderItemSeqId="08" amount="3.77" quantity="1" orderId="${cartOrderId}" shipmentId="${shipResult.shipmentId}" orderItemBillingId="55507"/>
                </items>
                <!-- TODO PtPickAssembly invoiceItemSeqId="09" -->
                <items amount="6.77" quantity="1" description="Standard Shipping" invoiceItemSeqId="10" itemTypeEnumId="ItemShipping">
                    <orderItemBillings orderItemSeqId="10" amount="6.77" quantity="1" orderId="${cartOrderId}" shipmentId="${shipResult.shipmentId}" orderItemBillingId="55509"/>
                </items>
                <status lastUpdatedStamp="1547839589298" statusId="InvoicePmtRecvd" sequenceNum="5" statusTypeId="Invoice" description="Payment Received"/>
            </invoices>
        </entity-facade-xml>""").check()
        logger.info("validate Shipment Invoice data check results: ")
        for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)

        then:
        dataCheckErrors.size() == 0
    }

    def "validate Shipment Invoice Accounting Transaction"() {
        when:
        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <!-- AcctgTrans created for Finalized Invoice -->
            <acctgTrans acctgTransId="55504" invoiceId="55500" organizationPartyId="ORG_ZIZI_RETAIL" otherPartyId="CustJqp" 
                    postedDate="${effectiveTime}" amountUomId="USD" isPosted="Y" acctgTransTypeEnumId="AttSalesInvoice" 
                    glFiscalTypeEnumId="GLFT_ACTUAL" transactionDate="${effectiveTime}">
                <entries acctgTransEntrySeqId="01" amount="16.99" debitCreditFlag="C" glAccountId="411000000" productId="DEMO_1_1" 
                        description="Demo Product One-One" reconcileStatusId="AterNot" invoiceItemSeqId="01" isSummary="N" 
                        glAccountTypeEnumId="GatSales" assetId="55400"/>
                <entries acctgTransEntrySeqId="02" amount="1.19" debitCreditFlag="C" glAccountId="224000000" 
                        description="Test Tax 7%" reconcileStatusId="AterNot" invoiceItemSeqId="02" isSummary="N" 
                        glAccountTypeEnumId="GatAccruedExpenses"/>

                <entries acctgTransEntrySeqId="03" amount="31.08" debitCreditFlag="C" glAccountId="411000000" productId="DEMO_3_1" 
                        description="Demo Product Three-One" reconcileStatusId="AterNot" invoiceItemSeqId="03" isSummary="N" 
                        glAccountTypeEnumId="GatSales" assetId="DEMO_3_1A"/>
                <entries acctgTransEntrySeqId="04" amount="4.92" debitCreditFlag="D" glAccountId="522200000"
                        description="Discount why? Because we love you." reconcileStatusId="AterNot" invoiceItemSeqId="04" isSummary="N" 
                        glAccountTypeEnumId="GatDiscounts"/>
                <entries acctgTransEntrySeqId="05" amount="1.83" debitCreditFlag="C" glAccountId="224000000" 
                        description="Test Tax 7%" reconcileStatusId="AterNot" invoiceItemSeqId="05" isSummary="N" glAccountTypeEnumId="GatAccruedExpenses"/>

                <entries acctgTransEntrySeqId="06" amount="60.6" debitCreditFlag="C" glAccountId="411000000" productId="DEMO_2_1" 
                        description="Demo Product Two-One" reconcileStatusId="AterNot" invoiceItemSeqId="06" isSummary="N" 
                        glAccountTypeEnumId="GatSales" assetId="55500"/>
                <entries acctgTransEntrySeqId="07" amount="6.7" debitCreditFlag="D" glAccountId="522200000"
                        description="Discount why? Because we love you." reconcileStatusId="AterNot" invoiceItemSeqId="07" isSummary="N" 
                        glAccountTypeEnumId="GatDiscounts"/>
                <entries acctgTransEntrySeqId="08" amount="3.77" debitCreditFlag="C" glAccountId="224000000" 
                        description="Test Tax 7%" reconcileStatusId="AterNot" invoiceItemSeqId="08" isSummary="N" 
                        glAccountTypeEnumId="GatAccruedExpenses"/>
                <!-- TODO PtPickAssembly acctgTransEntrySeqId="09" -->
                <entries acctgTransEntrySeqId="10" amount="6.77" debitCreditFlag="C" glAccountId="441000000" 
                        description="Standard Shipping" reconcileStatusId="AterNot" invoiceItemSeqId="10" isSummary="N"/>
                <entries acctgTransEntrySeqId="11" amount="170.61" debitCreditFlag="D" glAccountId="121000000" 
                        reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatAccountsReceivable"/>
            </acctgTrans>
        </entity-facade-xml>""").check()
        logger.info("validate Shipment Invoice Accounting Transaction data check results: ")
        for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)

        then:
        dataCheckErrors.size() == 0
    }

    def "validate Payment Accounting Transaction"() {
        when:
        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.account.payment.Payment paymentId="${setInfoOut.paymentId}" statusId="PmntDelivered"/>
            <mantle.account.payment.PaymentApplication paymentApplicationId="55500" paymentId="${setInfoOut.paymentId}"
                invoiceId="55500" amountApplied="170.61" appliedDate="${effectiveTime}"/>
            <mantle.account.method.PaymentGatewayResponse paymentGatewayResponseId="55501"
                paymentOperationEnumId="PgoCapture"
                paymentId="${setInfoOut.paymentId}" paymentMethodId="CustJqpCc" amount="200.68" amountUomId="USD"
                transactionDate="${effectiveTime}" resultSuccess="Y" resultDeclined="N" resultNsf="N"
                resultBadExpire="N" resultBadCardNumber="N"/>
            <!-- don't validate these, allow any payment gateway: paymentGatewayConfigId="TEST_APPROVE" referenceNum="TEST" -->

            <mantle.ledger.transaction.AcctgTrans acctgTransId="55505" acctgTransTypeEnumId="AttIncomingPayment"
                organizationPartyId="ORG_ZIZI_RETAIL" transactionDate="${effectiveTime}" isPosted="Y"
                glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD" otherPartyId="CustJqp"
                paymentId="${setInfoOut.paymentId}"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55505" acctgTransEntrySeqId="01" debitCreditFlag="C"
                amount="200.68" glAccountId="126000000" reconcileStatusId="AterNot" isSummary="N"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55505" acctgTransEntrySeqId="02" debitCreditFlag="D"
                amount="200.68" glAccountId="111100000" reconcileStatusId="AterNot" isSummary="N"/>
        </entity-facade-xml>""").check()
        logger.info("validate Payment Accounting Transaction data check results: ")
        for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)

        then:
        dataCheckErrors.size() == 0
    }

    /* ========== Business Customer Order, Credit Memo, Overpay/Refund, etc ========== */

    def "create and Ship Business Customer Order"() {
        when:
        Map createOut = ec.service.sync().name("mantle.order.OrderServices.create#Order")
                .parameters([vendorPartyId:'ORG_ZIZI_RETAIL', customerPartyId:'JoeDist', facilityId:'ZIRET_WH']).call()

        String b2bOrderId = createOut.orderId
        String b2bOrderPartSeqId = createOut.orderPartSeqId

        ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                .parameters([orderId:b2bOrderId, orderPartSeqId:b2bOrderPartSeqId, productId:'DEMO_1_1', quantity:100.0, unitAmount:15.0]).call()
        ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                .parameters([orderId:b2bOrderId, orderPartSeqId:b2bOrderPartSeqId, productId:'DEMO_3_1', quantity:20.0, unitAmount:5.5]).call()

        ec.service.sync().name("mantle.order.OrderServices.set#OrderBillingShippingInfo")
                .parameters([orderId:b2bOrderId, orderPartSeqId:b2bOrderPartSeqId, shippingPostalContactMechId:'JoeDistAddr',
                             carrierPartyId:'_NA_', shipmentMethodEnumId:'ShMthGround']).call()
        Map b2bPaymentOut = ec.service.sync().name("mantle.order.OrderServices.add#OrderPartPayment")
                .parameters([orderId:b2bOrderId, orderPartSeqId:b2bOrderPartSeqId, paymentInstrumentEnumId:'PiCompanyCheck']).call()
        b2bPaymentId = b2bPaymentOut.paymentId

        ec.service.sync().name("mantle.order.OrderServices.place#Order").parameters([orderId:b2bOrderId]).call()
        ec.service.sync().name("mantle.order.OrderServices.approve#Order").parameters([orderId:b2bOrderId]).call()

        Map b2bShipmentOut = ec.service.sync().name("mantle.shipment.ShipmentServices.create#OrderPartShipment")
                .parameters([orderId:b2bOrderId, orderPartSeqId:b2bOrderPartSeqId, createPackage:true]).call()
        b2bShipmentId = b2bShipmentOut.shipmentId
        String b2bShipmentPackageSeqId = b2bShipmentOut.shipmentPackageSeqId

        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#ShipmentProduct")
                .parameters([productId:'DEMO_1_1', quantity:100, shipmentId:b2bShipmentId, shipmentPackageSeqId:b2bShipmentPackageSeqId]).call()
        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#ShipmentProduct")
                .parameters([productId:'DEMO_3_1', quantity:20, shipmentId:b2bShipmentId, shipmentPackageSeqId:b2bShipmentPackageSeqId]).call()

        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#Shipment").parameters([shipmentId:b2bShipmentId]).call()
        ec.service.sync().name("mantle.shipment.ShipmentServices.ship#Shipment").parameters([shipmentId:b2bShipmentId]).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.account.invoice.Invoice invoiceId="55501" invoiceTypeEnumId="InvoiceSales"
                fromPartyId="ORG_ZIZI_RETAIL" toPartyId="JoeDist" statusId="InvoiceFinalized" invoiceDate="${effectiveTime}"
                currencyUomId="USD" invoiceTotal="1610.0" appliedPaymentsTotal="0" unpaidTotal="1610.0"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "create Customer Credit Memo Invoice"() {
        when:
        Map b2bCredMemoOut = ec.service.sync().name("mantle.account.InvoiceServices.create#Invoice")
                .parameters([fromPartyId:'JoeDist', toPartyId:'ORG_ZIZI_RETAIL', invoiceTypeEnumId:'InvoiceCreditMemo', invoiceDate:new Timestamp(effectiveTime)]).call()
        b2bCredMemoId = b2bCredMemoOut.invoiceId
        // add single item for ItemChargebackAdjust
        ec.service.sync().name("mantle.account.InvoiceServices.create#InvoiceItem").parameters([invoiceId:b2bCredMemoId,
                itemTypeEnumId:'ItemChargebackAdjust', description:'Test Chargeback', quantity:1.0, amount:250.0]).call()
        // approve invoice (posts to GL)
        ec.service.sync().name("update#mantle.account.invoice.Invoice").parameters([invoiceId:b2bCredMemoId, statusId:'InvoiceApproved']).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.account.invoice.Invoice invoiceId="${b2bCredMemoId}" invoiceTypeEnumId="InvoiceCreditMemo"
                fromPartyId="JoeDist" toPartyId="ORG_ZIZI_RETAIL" statusId="InvoiceApproved" invoiceDate="${effectiveTime}"
                currencyUomId="USD" invoiceTotal="250" appliedPaymentsTotal="0" unpaidTotal="250"/>

            <mantle.ledger.transaction.AcctgTrans acctgTransId="55510" acctgTransTypeEnumId="AttCreditMemo"
                    organizationPartyId="ORG_ZIZI_RETAIL" transactionDate="${effectiveTime}" isPosted="Y"
                    postedDate="${effectiveTime}" glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD"
                    otherPartyId="JoeDist" invoiceId="${b2bCredMemoId}">
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="01" debitCreditFlag="D"
                        amount="250" glAccountId="522100000" reconcileStatusId="AterNot" isSummary="N"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="02" debitCreditFlag="C"
                        amount="250" glAccountId="212000000" reconcileStatusId="AterNot" isSummary="N"/>
            </mantle.ledger.transaction.AcctgTrans>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "apply Customer Credit Memo Invoice"() {
        when:
        String b2bInvoiceId = '55501'
        Map credMemoApplResult = ec.service.sync().name("mantle.account.PaymentServices.apply#InvoiceToInvoice")
                .parameters([invoiceId:b2bCredMemoId, toInvoiceId:b2bInvoiceId]).call()
        String paymentApplicationId = credMemoApplResult.paymentApplicationId

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.account.payment.PaymentApplication paymentApplicationId="${paymentApplicationId}"
                invoiceId="${b2bCredMemoId}" toInvoiceId="${b2bInvoiceId}" amountApplied="250" appliedDate="${effectiveTime}"/>
            <mantle.account.invoice.Invoice invoiceId="${b2bCredMemoId}" invoiceTypeEnumId="InvoiceCreditMemo"
                fromPartyId="JoeDist" toPartyId="ORG_ZIZI_RETAIL" statusId="InvoicePmtSent" invoiceDate="${effectiveTime}"
                currencyUomId="USD" invoiceTotal="250" appliedPaymentsTotal="250" unpaidTotal="0"/>
            <mantle.account.invoice.Invoice invoiceId="${b2bInvoiceId}" invoiceTypeEnumId="InvoiceSales"
                fromPartyId="ORG_ZIZI_RETAIL" toPartyId="JoeDist" statusId="InvoiceFinalized" invoiceDate="${effectiveTime}"
                currencyUomId="USD" invoiceTotal="1610.0" appliedPaymentsTotal="250" unpaidTotal="1360.0"/>

            <mantle.ledger.transaction.AcctgTrans acctgTransId="55511" acctgTransTypeEnumId="AttInvoiceInOutAppl"
                    organizationPartyId="ORG_ZIZI_RETAIL" transactionDate="${effectiveTime}" isPosted="Y"
                    postedDate="${effectiveTime}" glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD"
                    otherPartyId="JoeDist" invoiceId="${b2bCredMemoId}" toInvoiceId="${b2bInvoiceId}"
                    paymentApplicationId="${paymentApplicationId}">
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="01" debitCreditFlag="D"
                        amount="250" glAccountId="212000000" reconcileStatusId="AterNot" isSummary="N"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="02" debitCreditFlag="C"
                        amount="250" glAccountId="121000000" reconcileStatusId="AterNot" isSummary="N"/>
            </mantle.ledger.transaction.AcctgTrans>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "receive and Apply Customer Overpayment"() {
        when:
        BigDecimal overpayAmount = 1500.0 - 1360.0
        ec.service.sync().name("mantle.account.PaymentServices.update#Payment")
                .parameters([paymentId:b2bPaymentId, amount:1500.0, effectiveDate:new Timestamp(effectiveTime)]).call()
        ec.service.sync().name("mantle.account.PaymentServices.update#Payment")
                .parameters([paymentId:b2bPaymentId, statusId:'PmntDelivered']).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.account.payment.Payment paymentId="${b2bPaymentId}" statusId="PmntDelivered"
                effectiveDate="${effectiveTime}" amount="1500" appliedTotal="1360.0" unappliedTotal="${overpayAmount}"/>

            <!-- TODO: AcctgTrans 55509 for incoming payment, 55510 for incoming payment appl -->
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "refund Customer Overpayment"() {
        when:
        BigDecimal overpayAmount = 1500.0 - 1360.0
        // record sent refund Payment
        Map refundPmtResult = ec.service.sync().name("mantle.account.PaymentServices.create#Payment")
                .parameters([paymentTypeEnumId:'PtRefund', statusId:'PmntDelivered', fromPartyId:'ORG_ZIZI_RETAIL',
                             toPartyId:'JoeDist', effectiveDate:new Timestamp(effectiveTime), paymentRefNum:"1000",
                             paymentInstrumentEnumId:'PiCompanyCheck', paymentMethodId:"ZIRET_BA", amount:overpayAmount]).call()
        // apply refund Payment to overpay Payment
        Map refundApplResult = ec.service.sync().name("mantle.account.PaymentServices.apply#PaymentToPayment")
                .parameters([paymentId:refundPmtResult.paymentId, toPaymentId:b2bPaymentId]).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.account.payment.PaymentApplication paymentApplicationId="${refundApplResult.paymentApplicationId}"
                paymentId="${refundPmtResult.paymentId}" toPaymentId="${b2bPaymentId}" amountApplied="${overpayAmount}"
                appliedDate="${effectiveTime}"/>
            <mantle.account.payment.Payment paymentId="${refundPmtResult.paymentId}" statusId="PmntDelivered"
                effectiveDate="${effectiveTime}" amount="${overpayAmount}" appliedTotal="${overpayAmount}" unappliedTotal="0"/>
            <mantle.account.payment.Payment paymentId="${b2bPaymentId}" statusId="PmntDelivered"
                effectiveDate="${effectiveTime}" amount="1500" appliedTotal="1500" unappliedTotal="0"/>

            <!-- AcctgTrans created for Delivered refund Payment -->
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55514" acctgTransTypeEnumId="AttOutgoingPayment"
                    organizationPartyId="ORG_ZIZI_RETAIL" transactionDate="${effectiveTime}" isPosted="Y"
                    postedDate="${effectiveTime}" glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD"
                    otherPartyId="JoeDist" paymentId="${refundPmtResult.paymentId}">
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="01" debitCreditFlag="D"
                        amount="${overpayAmount}" glAccountId="216000000" reconcileStatusId="AterNot" isSummary="N"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="02" debitCreditFlag="C"
                        amount="${overpayAmount}" glAccountId="111100000" reconcileStatusId="AterNot" isSummary="N"/>
            </mantle.ledger.transaction.AcctgTrans>

            <!-- AcctgTrans for payment to payment application -->
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55515" acctgTransTypeEnumId="AttPaymentInOutAppl"
                    organizationPartyId="ORG_ZIZI_RETAIL" transactionDate="${effectiveTime}" isPosted="Y"
                    postedDate="${effectiveTime}" glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD"
                    otherPartyId="JoeDist" paymentId="${refundPmtResult.paymentId}" toPaymentId="${b2bPaymentId}"
                    paymentApplicationId="${refundApplResult.paymentApplicationId}">
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="01" debitCreditFlag="C"
                        amount="${overpayAmount}" glAccountId="216000000" reconcileStatusId="AterNot" isSummary="N"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="02" debitCreditFlag="D"
                        amount="${overpayAmount}" glAccountId="126000000" reconcileStatusId="AterNot" isSummary="N"/>
            </mantle.ledger.transaction.AcctgTrans>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        refundApplResult.amountApplied == overpayAmount
        dataCheckErrors.size() == 0
    }

    /* ========== Inventory Reservation and Issuance Tests: pack/issue and unpack, cancel Shipment in late status ========== */

    def "create Inventory Tests Sales Order"() {
        when:
        ec.user.loginUser("john.doe", "moqui")

        Map addOut1 = ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                .parameters([productId:"DEMO_UNIT", quantity:10, customerPartyId:"CustJqp",
                        currencyUomId:"USD", productStoreId:"POPC_DEFAULT"]).call()

        inventoryOrderId = addOut1.orderId

        ec.service.sync().name("mantle.order.OrderServices.set#OrderBillingShippingInfo")
                .parameters([orderId:inventoryOrderId, paymentMethodId:'CustJqpCc', shippingPostalContactMechId:'CustJqpAddr',
                        shippingTelecomContactMechId:'CustJqpTeln', carrierPartyId:'_NA_', shipmentMethodEnumId:'ShMthGround']).call()

        ec.service.sync().name("mantle.order.OrderServices.place#Order").parameters([orderId:inventoryOrderId, requireInventory:false]).call()
        ec.service.sync().name("mantle.order.OrderServices.approve#Order").parameters([orderId:inventoryOrderId]).call()

        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.order.OrderHeader orderId="${inventoryOrderId}" entryDate="${effectiveTime}" placedDate="${effectiveTime}"
                statusId="OrderApproved" currencyUomId="USD" productStoreId="POPC_DEFAULT" grandTotal="10.00"/>
            <mantle.order.OrderPart orderId="${inventoryOrderId}" orderPartSeqId="01" vendorPartyId="ORG_ZIZI_RETAIL"
                customerPartyId="CustJqp" shipmentMethodEnumId="ShMthGround" postalContactMechId="CustJqpAddr"
                telecomContactMechId="CustJqpTeln" partTotal="10.00"/>
            <mantle.order.OrderItem orderId="${inventoryOrderId}" orderItemSeqId="01" orderPartSeqId="01" itemTypeEnumId="ItemProduct"
                productId="DEMO_UNIT" itemDescription="Demo Product One Unit" quantity="10" unitAmount="1.00"
                isModifiedPrice="N"/>

            <mantle.product.issuance.AssetReservation assetReservationId="55507" orderId="55502" orderItemSeqId="01"
                reservedDate="${effectiveTime}" quantity="10" quantityNotAvailable="0" quantityNotIssued="10" assetId="DEMO_UNITA"
                productId="DEMO_UNIT" sequenceNum="0" reservationOrderEnumId="AsResOrdFifoRec"/>
            <mantle.product.asset.AssetDetail assetDetailId="55525" assetId="DEMO_UNITA" orderId="55502" orderItemSeqId="01" 
                productId="DEMO_UNIT" assetReservationId="55507" availableToPromiseDiff="-10" effectiveDate="${effectiveTime}"/>
        </entity-facade-xml>""").check()
        logger.info("create Inventory Tests Sales Order data check results: ")
        for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)

        // check QOH - ATP = Reservations
        def assetDetailSummaryList = ec.entity.find("mantle.product.asset.AssetDetailSummary")
                .condition("assetId", "DEMO_UNITA").selectField("availableToPromiseTotal,quantityOnHandTotal").list()
        BigDecimal availableToPromiseTotal = (BigDecimal) assetDetailSummaryList.get(0).availableToPromiseTotal
        BigDecimal quantityOnHandTotal = (BigDecimal) assetDetailSummaryList.get(0).quantityOnHandTotal
        BigDecimal reservationTotal = (BigDecimal) ec.entity.find("mantle.product.issuance.AssetReservation")
                .condition("assetId", "DEMO_UNITA").list().sum({ it.quantity })
        logger.info("availableToPromiseTotal ${availableToPromiseTotal} quantityOnHandTotal ${quantityOnHandTotal} reservationTotal ${reservationTotal}")

        then:
        dataCheckErrors.size() == 0
        quantityOnHandTotal - availableToPromiseTotal == reservationTotal
    }

    def "ship Inventory Sales Order and Cancel Shipment"() {
        when:
        ec.user.loginUser("john.doe", "moqui")

        Map shipResult = ec.service.sync().name("mantle.shipment.ShipmentServices.create#OrderPartShipment")
                .parameters([orderId:inventoryOrderId, orderPartSeqId:"01", createPackage:true]).call()

        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#ShipmentProduct")
                .parameters([productId:'DEMO_UNIT', quantity:10, shipmentId:shipResult.shipmentId, shipmentPackageSeqId:shipResult.shipmentPackageSeqId]).call()

        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#Shipment").parameters([shipmentId:shipResult.shipmentId]).call()
        ec.service.sync().name("mantle.shipment.ShipmentServices.ship#Shipment").parameters([shipmentId:shipResult.shipmentId]).call()
        ec.service.sync().name("mantle.shipment.ShipmentServices.cancel#Shipment").parameters([shipmentId:shipResult.shipmentId]).call()

        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.product.issuance.AssetIssuance assetIssuanceId="55508" assetId="DEMO_UNITA" orderId="55502" orderItemSeqId="01" 
                    issuedDate="${effectiveTime}" shipmentId="55502" shipmentItemSourceId="55506" 
                    productId="DEMO_UNIT" quantity="0" quantityCancelled="10" assetReservationId="55507"
                    acctgTransResultEnumId="AtrSuccess" issuedByUserId="EX_JOHN_DOE">
                <mantle.product.asset.AssetDetail assetDetailId="55526" assetId="DEMO_UNITA" quantityOnHandDiff="-10" 
                        productId="DEMO_UNIT" shipmentId="55502" assetReservationId="55507" effectiveDate="${effectiveTime}"/>
                <mantle.product.asset.AssetDetail assetDetailId="55527" assetId="DEMO_UNITA" quantityOnHandDiff="10" availableToPromiseDiff="10"  
                        productId="DEMO_UNIT" shipmentId="55502" effectiveDate="${effectiveTime}"/>
                <mantle.order.OrderItemBilling orderItemBillingId="55512" orderId="55502" orderItemSeqId="01" amount="1" 
                        quantity="0" shipmentId="55502" invoiceId="55503" invoiceItemSeqId="01"/>
            </mantle.product.issuance.AssetIssuance>

            <mantle.product.issuance.AssetReservation assetReservationId="55508" orderId="55502" orderItemSeqId="01" 
                    reservedDate="${effectiveTime}" quantity="10" quantityNotAvailable="0" quantityNotIssued="10" assetId="DEMO_UNITA" 
                    productId="DEMO_UNIT" sequenceNum="0" reservationOrderEnumId="AsResOrdFifoRec"/>
            <mantle.product.asset.AssetDetail assetDetailId="55528" assetId="DEMO_UNITA" orderId="55502" orderItemSeqId="01"
                    productId="DEMO_UNIT" assetReservationId="55508" availableToPromiseDiff="-10" effectiveDate="${effectiveTime}"/>
        </entity-facade-xml>""").check()
        logger.info("ship Inventory Sales Order and Cancel Shipment data check results: ")
        for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)

        // check QOH - ATP = Reservations
        def assetDetailSummaryList = ec.entity.find("mantle.product.asset.AssetDetailSummary")
                .condition("assetId", "DEMO_UNITA").selectField("availableToPromiseTotal,quantityOnHandTotal").list()
        BigDecimal availableToPromiseTotal = (BigDecimal) assetDetailSummaryList.get(0).availableToPromiseTotal
        BigDecimal quantityOnHandTotal = (BigDecimal) assetDetailSummaryList.get(0).quantityOnHandTotal
        BigDecimal reservationTotal = (BigDecimal) ec.entity.find("mantle.product.issuance.AssetReservation")
                .condition("assetId", "DEMO_UNITA").list().sum({ it.quantity })
        logger.info("availableToPromiseTotal ${availableToPromiseTotal} quantityOnHandTotal ${quantityOnHandTotal} reservationTotal ${reservationTotal}")

        then:
        dataCheckErrors.size() == 0
        quantityOnHandTotal - availableToPromiseTotal == reservationTotal
    }

    def "ship Partial Inventory Sales Order and Cancel Shipment"() {
        when:
        ec.user.loginUser("john.doe", "moqui")

        Map shipResult = ec.service.sync().name("mantle.shipment.ShipmentServices.create#OrderPartShipment")
                .parameters([orderId:inventoryOrderId, orderPartSeqId:"01", createPackage:true]).call()
        String shipmentId = shipResult.shipmentId

        // pack partial
        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#ShipmentProduct")
                .parameters([productId:'DEMO_UNIT', quantity:5, shipmentId:shipResult.shipmentId, shipmentPackageSeqId:shipResult.shipmentPackageSeqId]).call()
        // unpack
        EntityList issuanceList = ec.entity.find("mantle.product.issuance.AssetIssuance").condition("shipmentId", shipmentId).list()
        for (EntityValue issuance in issuanceList) {
            ec.service.sync().name("mantle.shipment.ShipmentServices.unpack#ShipmentItemIssuance")
                    .parameters([assetIssuanceId:issuance.assetIssuanceId]).call()
        }

        // pack partial again
        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#ShipmentProduct")
                .parameters([productId:'DEMO_UNIT', quantity:5, shipmentId:shipResult.shipmentId, shipmentPackageSeqId:shipResult.shipmentPackageSeqId]).call()

        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#Shipment").parameters([shipmentId:shipResult.shipmentId]).call()
        ec.service.sync().name("mantle.shipment.ShipmentServices.ship#Shipment").parameters([shipmentId:shipResult.shipmentId]).call()
        ec.service.sync().name("mantle.shipment.ShipmentServices.cancel#Shipment").parameters([shipmentId:shipResult.shipmentId]).call()

        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
        </entity-facade-xml>""").check()
        logger.info("ship Partial Inventory Sales Order and Cancel Shipment data check results: ")
        for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)

        // check QOH - ATP = Reservations
        def assetDetailSummaryList = ec.entity.find("mantle.product.asset.AssetDetailSummary")
                .condition("assetId", "DEMO_UNITA").selectField("availableToPromiseTotal,quantityOnHandTotal").list()
        BigDecimal availableToPromiseTotal = (BigDecimal) assetDetailSummaryList.get(0).availableToPromiseTotal
        BigDecimal quantityOnHandTotal = (BigDecimal) assetDetailSummaryList.get(0).quantityOnHandTotal
        BigDecimal reservationTotal = (BigDecimal) ec.entity.find("mantle.product.issuance.AssetReservation")
                .condition("assetId", "DEMO_UNITA").list().sum({ it.quantity })
        logger.info("availableToPromiseTotal ${availableToPromiseTotal} quantityOnHandTotal ${quantityOnHandTotal} reservationTotal ${reservationTotal}")

        then:
        dataCheckErrors.size() == 0
        quantityOnHandTotal - availableToPromiseTotal == reservationTotal
    }

    // NOTE: do this last because deals with unpredictable data (number of AssetDetail, etc records) from the thread race in asset reservations
    def "reserve Asset With Displace Reservation"() {
        when:
        // NOTE: orders used here are from AssetReservationMultipleThreads (base id 53000)
        // use asset DEMO_1_1A with 0 ATP at this point (90 QOH, 2 reservations for orders)
        // use order with 60 currently reserved against asset 55400

        EntityList beforeResList = ec.entity.find("mantle.product.issuance.AssetReservation")
                .condition("assetId", "DEMO_1_1A").orderBy("assetId").list()
        for (EntityValue res in beforeResList) logger.warn("Res before: R:${res.assetReservationId} - O:${res.orderId} - A:${res.assetId} - ${res.quantity} - QOH:${res.asset.quantityOnHandTotal}")

        beforeResList = ec.entity.find("mantle.product.issuance.AssetReservation")
                .condition("assetId", "55400").orderBy("assetId").list()
        for (EntityValue res in beforeResList) logger.warn("Res before: R:${res.assetReservationId} - O:${res.orderId} - A:${res.assetId} - ${res.quantity}")

        EntityValue beforeRes = beforeResList.find({it.quantity == 60})
        String orderId = beforeRes.orderId
        String orderItemSeqId = beforeRes.orderItemSeqId

        ec.service.sync().name("mantle.product.AssetServices.reserve#AssetForOrderItem")
                .parameters([orderId:orderId, orderItemSeqId:orderItemSeqId, assetId:"DEMO_1_1A", resetReservations:true]).call()

        EntityList afterResList = ec.entity.find("mantle.product.issuance.AssetReservation")
                .condition("orderId", orderId).condition("orderItemSeqId", orderItemSeqId).orderBy("assetId").list()
        for (EntityValue res in afterResList) logger.info("Res after: R:${res.assetReservationId} - O:${res.orderId} - A:${res.assetId} - ${res.quantity}")
        EntityValue afterRes = afterResList.find({it.assetId == "DEMO_1_1A"})

        then:
        afterRes != null
        afterRes?.assetId == "DEMO_1_1A"
        afterRes?.quantity == 60.0
    }
}
