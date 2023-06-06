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
import org.moqui.util.ObjectUtilities
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import spock.lang.Shared
import spock.lang.Specification

import java.sql.Date
import java.sql.Timestamp

/* To run these make sure moqui, and mantle are in place and run:
    "gradle cleanAll load runtime/mantle/mantle-usl:test"
   Or to quick run with saved DB copy use "gradle loadSave" once then each time "gradle reloadSave runtime/mantle/mantle-usl:test"
 */
class OrderProcureToPayBasicFlow extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(OrderProcureToPayBasicFlow.class)
    @Shared ExecutionContext ec
    @Shared String purchaseOrderId = null, orderPartSeqId
    @Shared Map setInfoOut, shipResult, sendPmtResult, refundPmtResult, refundApplResult
    @Shared String vendorPartyId = 'ZiddlemanInc', customerPartyId = 'ORG_ZIZI_RETAIL'
    @Shared String priceUomId = 'USD', currencyUomId = 'USD'
    @Shared String facilityId = 'ZIRET_WH'
    @Shared long effectiveTime = System.currentTimeMillis()
    @Shared java.sql.Date eolDate
    @Shared String equip1AssetId, equip2AssetId, currentFiscalMonthId
    @Shared long totalFieldsChecked = 0

    def setupSpec() {
        // init the framework, get the ec
        ec = Moqui.getExecutionContext()
        ec.user.loginUser("john.doe", "moqui")
        // set an effective date so data check works, etc
        ec.user.setEffectiveTime(new Timestamp(effectiveTime))

        ec.entity.tempSetSequencedIdPrimary("mantle.ledger.transaction.AcctgTrans", 55400, 40)
        ec.entity.tempSetSequencedIdPrimary("mantle.shipment.Shipment", 55400, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.shipment.ShipmentItemSource", 55400, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.asset.Asset", 55400, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.asset.AssetDetail", 55400, 90)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.asset.PhysicalInventory", 55400, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.asset.Lot", 55400, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.receipt.AssetReceipt", 55400, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.product.issuance.AssetIssuance", 55400, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.account.invoice.Invoice", 55400, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.account.payment.Payment", 55400, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.account.payment.PaymentApplication", 55400, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.order.OrderHeader", 55400, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.order.OrderItemBilling", 55400, 10)
        ec.entity.tempSetSequencedIdPrimary("moqui.entity.EntityAuditLog", 55400, 90)
        // TODO: add EntityAuditLog validation (especially status changes, etc)
    }

    def cleanupSpec() {
        ec.entity.tempResetSequencedIdPrimary("mantle.ledger.transaction.AcctgTrans")
        ec.entity.tempResetSequencedIdPrimary("mantle.shipment.Shipment")
        ec.entity.tempResetSequencedIdPrimary("mantle.shipment.ShipmentItemSource")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.asset.Asset")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.asset.AssetDetail")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.asset.PhysicalInventory")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.asset.Lot")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.receipt.AssetReceipt")
        ec.entity.tempResetSequencedIdPrimary("mantle.product.issuance.AssetIssuance")
        ec.entity.tempResetSequencedIdPrimary("mantle.account.invoice.Invoice")
        ec.entity.tempResetSequencedIdPrimary("mantle.account.payment.Payment")
        ec.entity.tempResetSequencedIdPrimary("mantle.account.payment.PaymentApplication")
        ec.entity.tempResetSequencedIdPrimary("mantle.order.OrderHeader")
        ec.entity.tempResetSequencedIdPrimary("mantle.order.OrderItemBilling")
        ec.entity.tempResetSequencedIdPrimary("moqui.entity.EntityAuditLog")
        ec.destroy()

        logger.info("Order Procure to Pay Basic Flow complete, ${totalFieldsChecked} record fields checked")
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
    }

    def cleanup() {
        ec.artifactExecution.enableAuthz()
    }

    // TODO: def "create Supplier Credit Memo Invoice"() { }

    def "create Purchase Order"() {
        when:
        Map priceMap = ec.service.sync().name("mantle.product.PriceServices.get#ProductPrice")
                .parameters([productId:'DEMO_1_1', priceUomId:priceUomId, quantity:1,
                    vendorPartyId:vendorPartyId, customerPartyId:customerPartyId]).call()
        Map priceMap2 = ec.service.sync().name("mantle.product.PriceServices.get#ProductPrice")
                .parameters([productId:'DEMO_1_1', priceUomId:priceUomId, quantity:100,
                    vendorPartyId:vendorPartyId, customerPartyId:customerPartyId]).call()

        // no store, etc for purchase orders so explicitly create order and set parties
        Map orderOut = ec.service.sync().name("mantle.order.OrderServices.create#Order")
                .parameters([customerPartyId:customerPartyId, vendorPartyId:vendorPartyId,
                             currencyUomId:currencyUomId, facilityId:facilityId])
                .call()

        purchaseOrderId = orderOut.orderId
        orderPartSeqId = orderOut.orderPartSeqId

        ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                .parameters([orderId:purchaseOrderId, orderPartSeqId:orderPartSeqId, productId:'DEMO_1_1', quantity:400,
                    itemTypeEnumId:'ItemInventory']).call()
        ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                .parameters([orderId:purchaseOrderId, orderPartSeqId:orderPartSeqId, productId:'DEMO_3_1', quantity:100,
                    itemTypeEnumId:'ItemInventory']).call()
        ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                .parameters([orderId:purchaseOrderId, orderPartSeqId:orderPartSeqId, productId:'EQUIP_1', quantity:2,
                    itemTypeEnumId:'ItemAsset', unitAmount:10000]).call()

        // add shipping charge
        ec.service.sync().name("mantle.order.OrderServices.create#OrderItem")
                .parameters([orderId:purchaseOrderId, orderPartSeqId:orderPartSeqId, unitAmount:145.00,
                    itemTypeEnumId:'ItemShipping', itemDescription:'Incoming Freight']).call()

        setInfoOut = ec.service.sync().name("mantle.order.OrderServices.set#OrderBillingShippingInfo")
                .parameters([orderId:purchaseOrderId, orderPartSeqId:orderPartSeqId,
                    paymentMethodId:"ZIRET_BA", toPaymentMethodId:"ZiddlemanInc_BA",
                    paymentInstrumentEnumId:'PiAch', shippingPostalContactMechId:'ORG_ZIZI_RTL_SA',
                    shippingTelecomContactMechId:'ORG_ZIZI_RTL_PT', shipmentMethodEnumId:'ShMthPickUp']).call()

        // one person will place the PO
        ec.service.sync().name("mantle.order.OrderServices.place#Order").parameters([orderId:purchaseOrderId]).call()
        // typically another person will approve the PO
        ec.service.sync().name("mantle.order.OrderServices.approve#Order").parameters([orderId:purchaseOrderId]).call()
        // then the PO is sent to the vendor/supplier

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.order.OrderHeader orderId="${purchaseOrderId}" entryDate="${effectiveTime}" placedDate="${effectiveTime}"
                statusId="OrderApproved" currencyUomId="USD" grandTotal="23795.00"/>

            <mantle.account.payment.Payment paymentId="${setInfoOut.paymentId}" fromPartyId="${customerPartyId}" toPartyId="${vendorPartyId}"
                paymentInstrumentEnumId="PiAch" orderId="${purchaseOrderId}" orderPartSeqId="01"
                statusId="PmntPromised" amount="23795.00" amountUomId="USD"/>

            <mantle.order.OrderPart orderId="${purchaseOrderId}" orderPartSeqId="01" vendorPartyId="${vendorPartyId}"
                customerPartyId="${customerPartyId}" shipmentMethodEnumId="ShMthPickUp" postalContactMechId="ORG_ZIZI_RTL_SA"
                telecomContactMechId="ORG_ZIZI_RTL_PT" partTotal="" facilityId="${facilityId}"/>
            <mantle.order.OrderItem orderId="${purchaseOrderId}" orderItemSeqId="01" orderPartSeqId="01" itemTypeEnumId="ItemInventory"
                productId="DEMO_1_1" itemDescription="Demo Product One-One" quantity="400" unitAmount="8.00" isModifiedPrice="N"/>
            <mantle.order.OrderItem orderId="${purchaseOrderId}" orderItemSeqId="02" orderPartSeqId="01" itemTypeEnumId="ItemInventory"
                productId="DEMO_3_1" itemDescription="Demo Product Three-One" quantity="100" unitAmount="4.50" isModifiedPrice="N"/>
            <mantle.order.OrderItem orderId="${purchaseOrderId}" orderItemSeqId="03" orderPartSeqId="01" itemTypeEnumId="ItemAsset"
                productId="EQUIP_1" itemDescription="Picker Bot 2000" quantity="2" unitAmount="10000" isModifiedPrice="Y"/>
            <mantle.order.OrderItem orderId="${purchaseOrderId}" orderItemSeqId="04" orderPartSeqId="01" itemTypeEnumId="ItemShipping"
                itemDescription="Incoming Freight" quantity="1" unitAmount="145.00"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        priceMap.price == 9.00
        priceMap2.price == 8.00
        priceMap.priceUomId == 'USD'
        vendorPartyId == 'ZiddlemanInc'
        customerPartyId == 'ORG_ZIZI_RETAIL'

        dataCheckErrors.size() == 0
    }

    def "create Purchase Order Shipment and Schedule"() {
        when:
        shipResult = ec.service.sync().name("mantle.shipment.ShipmentServices.create#OrderPartShipment")
                .parameters([orderId:purchaseOrderId, orderPartSeqId:orderPartSeqId, destinationFacilityId:facilityId]).call()

        // TODO: add PO Shipment Schedule, update status to ShipScheduled

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <!-- Shipment created -->
            <mantle.shipment.Shipment shipmentId="${shipResult.shipmentId}" shipmentTypeEnumId="ShpTpPurchase"
                statusId="ShipInput" fromPartyId="ZiddlemanInc" toPartyId="ORG_ZIZI_RETAIL"/>

            <mantle.shipment.ShipmentItem shipmentId="${shipResult.shipmentId}" productId="DEMO_1_1" quantity="400"/>
            <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55400" shipmentId="${shipResult.shipmentId}"
                productId="DEMO_1_1" orderId="${purchaseOrderId}" orderItemSeqId="01" statusId="SisPending"
                quantity="400" quantityNotHandled="400" invoiceId="" invoiceItemSeqId=""/>

            <mantle.shipment.ShipmentItem shipmentId="${shipResult.shipmentId}" productId="DEMO_3_1" quantity="100"/>
            <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55401" shipmentId="${shipResult.shipmentId}"
                productId="DEMO_3_1" orderId="${purchaseOrderId}" orderItemSeqId="02" statusId="SisPending"
                quantity="100" quantityNotHandled="100" invoiceId="" invoiceItemSeqId=""/>

            <mantle.shipment.ShipmentItem shipmentId="${shipResult.shipmentId}" productId="EQUIP_1" quantity="2"/>
            <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55402" shipmentId="${shipResult.shipmentId}"
                productId="EQUIP_1" orderId="${purchaseOrderId}" orderItemSeqId="03" statusId="SisPending" quantity="2"
                quantityNotHandled="2" invoiceId="" invoiceItemSeqId=""/>

            <mantle.shipment.ShipmentRouteSegment shipmentId="${shipResult.shipmentId}" shipmentRouteSegmentSeqId="01"
                destPostalContactMechId="ORG_ZIZI_RTL_SA" destTelecomContactMechId="ORG_ZIZI_RTL_PT"/>

            <!-- no package when not outgoing packed, can be added by something else though:
            <mantle.shipment.ShipmentPackage shipmentId="${shipResult.shipmentId}" shipmentPackageSeqId="01"/>
            <mantle.shipment.ShipmentPackageContent shipmentId="${shipResult.shipmentId}" shipmentPackageSeqId="01"
                productId="DEMO_1_1" quantity="400"/>
            <mantle.shipment.ShipmentPackageContent shipmentId="${shipResult.shipmentId}" shipmentPackageSeqId="01"
                productId="DEMO_3_1" quantity="100"/>
            <mantle.shipment.ShipmentPackageRouteSeg shipmentId="${shipResult.shipmentId}" shipmentPackageSeqId="01"
                shipmentRouteSegmentSeqId="01"/>
            -->
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "set Shipment Shipped"() {
        when:
        // set Shipment Shipped
        ec.service.sync().name("mantle.shipment.ShipmentServices.ship#Shipment")
                .parameters([shipmentId:shipResult.shipmentId]).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <!-- Shipment to Shipped status -->
            <mantle.shipment.Shipment shipmentId="${shipResult.shipmentId}" shipmentTypeEnumId="ShpTpPurchase"
                statusId="ShipShipped" fromPartyId="ZiddlemanInc" toPartyId="ORG_ZIZI_RETAIL"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "receive Purchase Order Shipment"() {
        when:
        // receive the Shipment, create AssetReceipt records, status to ShipDelivered

        // don't want to receive entire order because need to set parameters for equipment product:
        // ec.service.sync().name("mantle.shipment.ShipmentServices.receive#EntireShipment")
        //         .parameters([shipmentId:shipResult.shipmentId]).call()

        ec.service.sync().name("mantle.shipment.ShipmentServices.receive#ShipmentProduct")
                .parameters([shipmentId:shipResult.shipmentId, productId:'DEMO_1_1',
                    quantityAccepted:400, facilityId:facilityId, locationSeqId:"01010101", lotNumber:'A1111',
                    manufacturedDate:new Timestamp(effectiveTime - (3600000L*24*14)),
                    expectedEndOfLife:new Date(effectiveTime + (3600000L*24*180))]).call()
        // receive to Receiving type location, with demo data settings will get On Hold
        ec.service.sync().name("mantle.shipment.ShipmentServices.receive#ShipmentProduct")
                .parameters([shipmentId:shipResult.shipmentId, productId:'DEMO_3_1',
                    quantityAccepted:100, facilityId:facilityId, locationSeqId:"0801", lotNumber:'A2222',
                    manufacturedDate:new Timestamp(effectiveTime - (3600000L*24*14)),
                    expectedEndOfLife:new Date(effectiveTime + (3600000L*24*240))]).call()

        // receive equipment with depreciation settings, in real use more likely set after receive with an update of the Asset record
        Calendar eolCal = ec.user.nowCalendar // will be set to effectiveTime, which will be the acquiredDate
        eolCal.add(Calendar.YEAR, 5) // depreciate over 5 years
        eolDate = new java.sql.Date(eolCal.timeInMillis)
        Map receiveEquip1Out = ec.service.sync().name("mantle.shipment.ShipmentServices.receive#ShipmentProduct")
                .parameters([shipmentId:shipResult.shipmentId, productId:'EQUIP_1',
                    quantityAccepted:1, facilityId:facilityId, serialNumber:'PB2000AZQRTFP',
                    expectedEndOfLife:(eolDate), salvageValue:1500, depreciationTypeEnumId:'DtpDoubleDeclining']).call()
        equip1AssetId = receiveEquip1Out.assetIdList[0]
        Map receiveEquip2Out = ec.service.sync().name("mantle.shipment.ShipmentServices.receive#ShipmentProduct")
                .parameters([shipmentId:shipResult.shipmentId, productId:'EQUIP_1',
                    quantityAccepted:1, facilityId:facilityId, serialNumber:'PB2000GRWADRE',
                    expectedEndOfLife:(eolDate), salvageValue:1500, depreciationTypeEnumId:'DtpStraightLine']).call()
        equip2AssetId = receiveEquip2Out.assetIdList[0]

        ec.service.sync().name("mantle.shipment.ShipmentServices.deliver#Shipment")
                .parameters([shipmentId:shipResult.shipmentId]).call()


        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.shipment.Shipment shipmentId="${shipResult.shipmentId}" shipmentTypeEnumId="ShpTpPurchase"
                statusId="ShipDelivered" fromPartyId="ZiddlemanInc" toPartyId="ORG_ZIZI_RETAIL"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "complete Purchase Order"() {
        when:
        // NOTE: this is no longer necessary, done through checkComplete#OrderPart called by receive#ShipmentProduct
        // after Shipment Delivered mark Order as Completed
        // ec.service.sync().name("mantle.order.OrderServices.complete#OrderPart")
        //        .parameters([orderId:purchaseOrderId, orderPartSeqId:orderPartSeqId]).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <!-- OrderHeader status to Completed -->
            <mantle.order.OrderHeader orderId="${purchaseOrderId}" statusId="OrderCompleted"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "validate Assets Received"() {
        when:
        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.product.asset.Asset assetId="55400" assetTypeEnumId="AstTpInventory" statusId="AstAvailable"
                ownerPartyId="ORG_ZIZI_RETAIL" productId="DEMO_1_1" hasQuantity="Y" quantityOnHandTotal="400"
                availableToPromiseTotal="200" assetName="Demo Product One-One" receivedDate="${effectiveTime}"
                acquiredDate="${effectiveTime}" facilityId="${facilityId}" acquireOrderId="${purchaseOrderId}"
                acquireOrderItemSeqId="01" acquireCost="8" acquireCostUomId="USD"/>
            <mantle.product.receipt.AssetReceipt assetReceiptId="55400" assetId="55400" productId="DEMO_1_1"
                orderId="${purchaseOrderId}" orderItemSeqId="01" shipmentId="${shipResult.shipmentId}"
                receivedByUserId="EX_JOHN_DOE" receivedDate="${effectiveTime}" quantityAccepted="400"/>
            <mantle.product.asset.AssetDetail assetDetailId="55400" assetId="55400" effectiveDate="${effectiveTime}"
                quantityOnHandDiff="400" availableToPromiseDiff="400" unitCost="8" shipmentId="${shipResult.shipmentId}"
                productId="DEMO_1_1" assetReceiptId="55400"/>

            <mantle.product.asset.Asset assetId="55401" assetTypeEnumId="AstTpInventory" statusId="AstOnHold"
                ownerPartyId="ORG_ZIZI_RETAIL" productId="DEMO_3_1" hasQuantity="Y" quantityOnHandTotal="100"
                availableToPromiseTotal="100" assetName="Demo Product Three-One" receivedDate="${effectiveTime}"
                acquiredDate="${effectiveTime}" facilityId="${facilityId}" locationSeqId="0801" 
                acquireOrderId="${purchaseOrderId}" acquireOrderItemSeqId="02" acquireCost="4.5" acquireCostUomId="USD"/>
            <mantle.product.receipt.AssetReceipt assetReceiptId="55401" assetId="55401" productId="DEMO_3_1"
                orderId="${purchaseOrderId}" orderItemSeqId="02" shipmentId="${shipResult.shipmentId}"
                receivedByUserId="EX_JOHN_DOE" receivedDate="${effectiveTime}" quantityAccepted="100"/>
            <mantle.product.asset.AssetDetail assetDetailId="55409" assetId="55401" productId="DEMO_3_1"
                availableToPromiseDiff="100" shipmentId="${shipResult.shipmentId}" assetReceiptId="55401" unitCost="4.5"
                effectiveDate="${effectiveTime}" quantityOnHandDiff="100"/>

            <mantle.product.asset.Asset assetId="${equip1AssetId}" assetTypeEnumId="AstTpEquipment" statusId="AstInStorage"
                ownerPartyId="ORG_ZIZI_RETAIL" productId="EQUIP_1" hasQuantity="N" quantityOnHandTotal="1"
                availableToPromiseTotal="1" assetName="Picker Bot 2000" serialNumber="PB2000AZQRTFP"
                receivedDate="${effectiveTime}" acquiredDate="${effectiveTime}" facilityId="${facilityId}"
                acquireOrderId="${purchaseOrderId}" acquireOrderItemSeqId="03" acquireCost="10,000" acquireCostUomId="USD"
                expectedEndOfLife="${eolDate}" salvageValue="1500" depreciationTypeEnumId="DtpDoubleDeclining"/>
            <mantle.product.receipt.AssetReceipt assetReceiptId="55402" assetId="${equip1AssetId}" productId="EQUIP_1"
                orderId="${purchaseOrderId}" orderItemSeqId="03" shipmentId="${shipResult.shipmentId}"
                receivedByUserId="EX_JOHN_DOE" receivedDate="${effectiveTime}" quantityAccepted="1"/>
            <mantle.product.asset.AssetDetail assetDetailId="55410" assetId="${equip1AssetId}" productId="EQUIP_1"
                availableToPromiseDiff="1" shipmentId="${shipResult.shipmentId}" assetReceiptId="55402" unitCost="10000"
                effectiveDate="${effectiveTime}" quantityOnHandDiff="1"/>

            <mantle.product.asset.Asset assetId="${equip2AssetId}" assetTypeEnumId="AstTpEquipment" statusId="AstInStorage"
                ownerPartyId="ORG_ZIZI_RETAIL" productId="EQUIP_1" hasQuantity="N" quantityOnHandTotal="1"
                availableToPromiseTotal="1" assetName="Picker Bot 2000" serialNumber="PB2000GRWADRE"
                receivedDate="${effectiveTime}" acquiredDate="${effectiveTime}" facilityId="${facilityId}"
                acquireOrderId="${purchaseOrderId}" acquireOrderItemSeqId="03" acquireCost="10,000" acquireCostUomId="USD"
                expectedEndOfLife="${eolDate}" salvageValue="1500" depreciationTypeEnumId="DtpStraightLine"/>
            <mantle.product.receipt.AssetReceipt assetReceiptId="55403" assetId="${equip2AssetId}" productId="EQUIP_1"
                orderId="${purchaseOrderId}" orderItemSeqId="03" shipmentId="${shipResult.shipmentId}"
                receivedByUserId="EX_JOHN_DOE" receivedDate="${effectiveTime}" quantityAccepted="1"/>
            <mantle.product.asset.AssetDetail assetDetailId="55411" assetId="${equip2AssetId}" productId="EQUIP_1"
                availableToPromiseDiff="1" shipmentId="${shipResult.shipmentId}" assetReceiptId="55403" unitCost="10000"
                effectiveDate="${effectiveTime}" quantityOnHandDiff="1"/>


            <!-- verify assetReceiptId set on OrderItemBilling, and that all else is the same -->
            <mantle.order.OrderItemBilling orderItemBillingId="55400" orderId="${purchaseOrderId}" orderItemSeqId="01"
                invoiceId="55400" invoiceItemSeqId="01" quantity="400" amount="8.00"
                shipmentId="${shipResult.shipmentId}" assetReceiptId="55400"/>
            <mantle.order.OrderItemBilling orderItemBillingId="55401" orderId="${purchaseOrderId}" orderItemSeqId="02"
                invoiceId="55400" invoiceItemSeqId="02" quantity="100" amount="4.50"
                shipmentId="${shipResult.shipmentId}" assetReceiptId="55401"/>
            <mantle.order.OrderItemBilling orderItemBillingId="55402" orderId="${purchaseOrderId}" orderItemSeqId="03"
                invoiceId="55400" invoiceItemSeqId="03" quantity="1" amount="10,000"
                shipmentId="${shipResult.shipmentId}" assetReceiptId="55402"/>

            <!-- ShipmentItemSource now has quantityNotHandled="0" and statusId to SisReceived -->
            <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55400" shipmentId="${shipResult.shipmentId}"
                productId="DEMO_1_1" orderId="${purchaseOrderId}" orderItemSeqId="01" statusId="SisReceived" quantity="400"
                quantityNotHandled="0" invoiceId="55400" invoiceItemSeqId="01"/>
            <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55401" shipmentId="${shipResult.shipmentId}"
                productId="DEMO_3_1" orderId="${purchaseOrderId}" orderItemSeqId="02" statusId="SisReceived" quantity="100"
                quantityNotHandled="0" invoiceId="55400" invoiceItemSeqId="02"/>
            <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55402" shipmentId="${shipResult.shipmentId}"
                productId="EQUIP_1" orderId="${purchaseOrderId}" orderItemSeqId="03" statusId="SisReceived" quantity="1"
                quantityNotHandled="0" invoiceId="55400" invoiceItemSeqId="03"/>
            <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55403" shipmentId="${shipResult.shipmentId}"
                productId="EQUIP_1" orderId="${purchaseOrderId}" orderItemSeqId="03" statusId="SisReceived" quantity="1"
                quantityNotHandled="0" invoiceId="55400" invoiceItemSeqId="04"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "move Received Inventory"() {
        when:
        // move to pick location to make Available with demo settings for autoStatusId
        ec.service.sync().name("mantle.product.AssetServices.move#Product")
                .parameters([productId:'DEMO_3_1', quantity:100, quantityAccepted:100,
                             facilityId:facilityId, locationSeqId:"0801", toLocationSeqId:"01020101"]).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.product.asset.Asset assetId="55401" assetTypeEnumId="AstTpInventory" statusId="AstAvailable"
                ownerPartyId="ORG_ZIZI_RETAIL" productId="DEMO_3_1" hasQuantity="Y" quantityOnHandTotal="100"
                availableToPromiseTotal="100" facilityId="${facilityId}" locationSeqId="01020101"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)

        then:
        dataCheckErrors.size() == 0
    }

    def "validate Assets Receipt Accounting Transactions"() {
        when:
        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55400" acctgTransTypeEnumId="AttInventoryReceipt"
                organizationPartyId="ORG_ZIZI_RETAIL" transactionDate="${effectiveTime}" isPosted="Y"
                postedDate="${effectiveTime}" glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD" assetId="55400"
                assetReceiptId="55400"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55400" acctgTransEntrySeqId="01" debitCreditFlag="C"
                amount="3200" glAccountTypeEnumId="GatUnreceivedInventory" glAccountId="149300000"
                reconcileStatusId="AterNot" isSummary="N" productId="DEMO_1_1"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55400" acctgTransEntrySeqId="02" debitCreditFlag="D"
                amount="3200" glAccountTypeEnumId="GatInventory" glAccountId="141300000"
                reconcileStatusId="AterNot" isSummary="N" productId="DEMO_1_1"/>

            <mantle.ledger.transaction.AcctgTrans acctgTransId="55401" acctgTransTypeEnumId="AttInventoryReceipt"
                organizationPartyId="ORG_ZIZI_RETAIL" transactionDate="${effectiveTime}" isPosted="Y"
                postedDate="${effectiveTime}" glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD" assetId="55401"
                assetReceiptId="55401"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55401" acctgTransEntrySeqId="01" debitCreditFlag="C"
                amount="450" glAccountTypeEnumId="GatUnreceivedInventory" glAccountId="149300000"
                reconcileStatusId="AterNot" isSummary="N" productId="DEMO_3_1"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55401" acctgTransEntrySeqId="02" debitCreditFlag="D"
                amount="450" glAccountTypeEnumId="GatInventory" glAccountId="141300000"
                reconcileStatusId="AterNot" isSummary="N" productId="DEMO_3_1"/>

            <mantle.ledger.transaction.AcctgTrans postedDate="${effectiveTime}" amountUomId="USD" isPosted="Y"
                    assetId="${equip1AssetId}" acctgTransTypeEnumId="AttAssetReceipt" glFiscalTypeEnumId="GLFT_ACTUAL"
                    transactionDate="${effectiveTime}" acctgTransId="55402" assetReceiptId="55402"
                    organizationPartyId="ORG_ZIZI_RETAIL">
                <mantle.ledger.transaction.AcctgTransEntry amount="10000" productId="EQUIP_1" glAccountId="139100000"
                    reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatUnreceivedFixedAsset"
                    debitCreditFlag="C" acctgTransEntrySeqId="01" assetId="${equip1AssetId}"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="10000" productId="EQUIP_1" glAccountId="131100000"
                    reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatFixedAsset"
                    debitCreditFlag="D" acctgTransEntrySeqId="02" assetId="${equip1AssetId}"/>
            </mantle.ledger.transaction.AcctgTrans>
            <mantle.ledger.transaction.AcctgTrans postedDate="${effectiveTime}" amountUomId="USD" isPosted="Y"
                    assetId="${equip2AssetId}" acctgTransTypeEnumId="AttAssetReceipt" glFiscalTypeEnumId="GLFT_ACTUAL"
                    transactionDate="${effectiveTime}" acctgTransId="55403" assetReceiptId="55403"
                    organizationPartyId="ORG_ZIZI_RETAIL">
                <mantle.ledger.transaction.AcctgTransEntry amount="10000" productId="EQUIP_1" glAccountId="139100000"
                    reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatUnreceivedFixedAsset"
                    debitCreditFlag="C" acctgTransEntrySeqId="01" assetId="${equip2AssetId}"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="10000" productId="EQUIP_1" glAccountId="131100000"
                    reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatFixedAsset"
                    debitCreditFlag="D" acctgTransEntrySeqId="02" assetId="${equip2AssetId}"/>
            </mantle.ledger.transaction.AcctgTrans>

        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "process Purchase Invoice"() {
        when:
        // NOTE: in real-world scenarios the invoice received may not match what is expected, may be for multiple or
        //     partial purchase orders, etc; for this we'll simply create an invoice automatically from the Order
        // to somewhat simulate real-world, create in InvoiceIncoming then change to InvoiceReceived to allow for manual
        //     changes between

        // invResult = ec.service.sync().name("mantle.account.InvoiceServices.create#EntireOrderPartInvoice")
        //         .parameters([orderId:purchaseOrderId, orderPartSeqId:orderPartSeqId, statusId:'InvoiceReceived']).call()

        // This is how we would do it manually for the Shipment, but is done by an SECA rule when Shipment is marked as ShipDelivered
        // Map invResult = ec.service.sync().name("mantle.account.InvoiceServices.create#PurchaseShipmentInvoices")
        //         .parameters([shipmentId:shipResult.shipmentId, statusId:'InvoiceReceived']).call()
        // invoiceId = invResult.invoiceIdList.first

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <!-- Invoice created and received, not yet approved/etc -->
            <mantle.account.invoice.Invoice invoiceId="55400" invoiceTypeEnumId="InvoiceSales"
                fromPartyId="ZiddlemanInc" toPartyId="ORG_ZIZI_RETAIL" statusId="InvoiceIncoming"
                invoiceDate="${effectiveTime}" description="For Order ${purchaseOrderId} part 01 and Shipment ${shipResult.shipmentId}"
                currencyUomId="USD"/>

            <mantle.account.invoice.InvoiceItem invoiceId="55400" invoiceItemSeqId="01"
                itemTypeEnumId="ItemInventory" productId="DEMO_1_1" quantity="400" amount="8.00"
                description="Demo Product One-One" itemDate=""/>
            <mantle.order.OrderItemBilling orderItemBillingId="55400" orderId="${purchaseOrderId}" orderItemSeqId="01"
                invoiceId="55400" invoiceItemSeqId="01" quantity="400" amount="8.00"
                shipmentId="${shipResult.shipmentId}"/>

            <mantle.account.invoice.InvoiceItem invoiceId="55400" invoiceItemSeqId="02"
                itemTypeEnumId="ItemInventory" productId="DEMO_3_1" quantity="100" amount="4.50"
                description="Demo Product Three-One" itemDate=""/>
            <mantle.order.OrderItemBilling orderItemBillingId="55401" orderId="${purchaseOrderId}" orderItemSeqId="02"
                invoiceId="55400" invoiceItemSeqId="02" quantity="100" amount="4.50"
                shipmentId="${shipResult.shipmentId}"/>

            <mantle.account.invoice.InvoiceItem invoiceId="55400" invoiceItemSeqId="03"
                itemTypeEnumId="ItemAsset" productId="EQUIP_1" quantity="1" amount="10,000" description="Picker Bot 2000"
                itemDate="" assetId="${equip1AssetId}"/>
            <mantle.order.OrderItemBilling orderItemBillingId="55402" orderId="${purchaseOrderId}" orderItemSeqId="03"
                invoiceId="55400" invoiceItemSeqId="03" quantity="1" amount="10,000"
                shipmentId="${shipResult.shipmentId}"/>

            <mantle.account.invoice.InvoiceItem invoiceId="55400" invoiceItemSeqId="04"
                itemTypeEnumId="ItemAsset" productId="EQUIP_1" quantity="1" amount="10,000" description="Picker Bot 2000"
                itemDate="" assetId="${equip2AssetId}"/>
            <mantle.order.OrderItemBilling orderItemBillingId="55403" orderId="${purchaseOrderId}" orderItemSeqId="03"
                invoiceId="55400" invoiceItemSeqId="04" quantity="1" amount="10,000"
                shipmentId="${shipResult.shipmentId}"/>

            <mantle.account.invoice.InvoiceItem invoiceId="55400" invoiceItemSeqId="05"
                itemTypeEnumId="ItemShipping" quantity="1" amount="145" description="Incoming Freight"
                itemDate=""/>
            <mantle.order.OrderItemBilling orderItemBillingId="55404" orderId="${purchaseOrderId}" orderItemSeqId="04"
                invoiceId="55400" invoiceItemSeqId="05" quantity="1" amount="145"/>

            <!-- ShipmentItemSource now has invoiceId and invoiceItemSeqId -->
            <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55400" shipmentId="${shipResult.shipmentId}"
                productId="DEMO_1_1" orderId="${purchaseOrderId}" orderItemSeqId="01" statusId="SisReceived" quantity="400"
                quantityNotHandled="0" invoiceId="55400" invoiceItemSeqId="01"/>
            <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55401" shipmentId="${shipResult.shipmentId}"
                productId="DEMO_3_1" orderId="${purchaseOrderId}" orderItemSeqId="02" statusId="SisReceived" quantity="100"
                quantityNotHandled="0" invoiceId="55400" invoiceItemSeqId="02"/>
            <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55402" shipmentId="${shipResult.shipmentId}"
                productId="EQUIP_1" orderId="${purchaseOrderId}" orderItemSeqId="03" statusId="SisReceived" quantity="1"
                quantityNotHandled="0" invoiceId="55400" invoiceItemSeqId="03"/>
            <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55403" shipmentId="${shipResult.shipmentId}"
                productId="EQUIP_1" orderId="${purchaseOrderId}" orderItemSeqId="03" statusId="SisReceived" quantity="1"
                quantityNotHandled="0" invoiceId="55400" invoiceItemSeqId="04"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "approve Purchase Invoice"() {
        when:
        // approve Invoice from Vendor (will trigger GL posting)
        ec.service.sync().name("update#mantle.account.invoice.Invoice")
                .parameters([invoiceId:'55400', statusId:'InvoiceApproved']).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.account.invoice.Invoice invoiceId="55400" statusId="InvoiceApproved"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "validate Purchase Invoice Accounting Transaction"() {
        when:
        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <!-- AcctgTrans created for Approved Invoice -->
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55404" acctgTransTypeEnumId="AttPurchaseInvoice"
                    organizationPartyId="ORG_ZIZI_RETAIL" transactionDate="${effectiveTime}" isPosted="Y"
                    postedDate="${effectiveTime}" glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD"
                    otherPartyId="ZiddlemanInc" invoiceId="55400">

                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="01" debitCreditFlag="D"
                    amount="3200" glAccountTypeEnumId="GatUnreceivedInventory" glAccountId="149300000"
                    reconcileStatusId="AterNot" isSummary="N" productId="DEMO_1_1" invoiceItemSeqId="01"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="02" debitCreditFlag="D"
                    amount="450" glAccountTypeEnumId="GatUnreceivedInventory" glAccountId="149300000"
                    reconcileStatusId="AterNot" isSummary="N" productId="DEMO_3_1" invoiceItemSeqId="02"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="03" debitCreditFlag="D"
                    amount="10,000" glAccountTypeEnumId="GatUnreceivedFixedAsset" glAccountId="139100000"
                    reconcileStatusId="AterNot" isSummary="N" productId="EQUIP_1" invoiceItemSeqId="03"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="04" debitCreditFlag="D"
                    amount="10,000" glAccountTypeEnumId="GatUnreceivedFixedAsset" glAccountId="139100000"
                    reconcileStatusId="AterNot" isSummary="N" productId="EQUIP_1" invoiceItemSeqId="04"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="05" debitCreditFlag="D"
                    amount="145" glAccountTypeEnumId="" glAccountId="519100000" reconcileStatusId="AterNot"
                    isSummary="N" invoiceItemSeqId="05"/>

                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="06" debitCreditFlag="C"
                    amount="23795" glAccountTypeEnumId="GatAccountsPayable" glAccountId="212000000"
                    reconcileStatusId="AterNot" isSummary="N"/>
            </mantle.ledger.transaction.AcctgTrans>

        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "adjust Purchase Invoice"() {
        when:
        // contradictory late charge and prompt payment discount, but this is just a test
        ec.service.sync().name("mantle.account.InvoiceServices.adjust#Invoice")
                .parameters([invoiceId:'55400', description:'', amount:50, itemTypeEnumId:'ItemLateCharge']).call()
        ec.service.sync().name("mantle.account.InvoiceServices.adjust#Invoice")
                .parameters([invoiceId:'55400', description:'', amount:-15, itemTypeEnumId:'ItemPromptDiscount']).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <invoices invoiceId="55400">
                <items invoiceItemSeqId="06" amount="50" quantity="1" itemDate="${effectiveTime}" itemTypeEnumId="ItemLateCharge"/>
                <items invoiceItemSeqId="07" amount="-15" quantity="1" itemDate="${effectiveTime}" itemTypeEnumId="ItemPromptDiscount"/>
            </invoices>
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55405" otherPartyId="ZiddlemanInc"
                    postedDate="${effectiveTime}" amountUomId="USD" isPosted="Y" acctgTransTypeEnumId="AttInvoiceAdjust"
                    glFiscalTypeEnumId="GLFT_ACTUAL" transactionDate="${effectiveTime}" organizationPartyId="ORG_ZIZI_RETAIL">
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="01" amount="50" glAccountId="517000000"
                        reconcileStatusId="AterNot" invoiceItemSeqId="06" isSummary="N" glAccountTypeEnumId="GatCogs"
                        debitCreditFlag="D"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="02" amount="50" glAccountId="212000000"
                        reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatAccountsPayable" debitCreditFlag="C"/>
            </mantle.ledger.transaction.AcctgTrans>
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55406" otherPartyId="ZiddlemanInc"
                    postedDate="${effectiveTime}" amountUomId="USD" isPosted="Y" acctgTransTypeEnumId="AttInvoiceAdjust"
                    glFiscalTypeEnumId="GLFT_ACTUAL" transactionDate="${effectiveTime}" organizationPartyId="ORG_ZIZI_RETAIL">
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="01" amount="15" glAccountId="864000000"
                        reconcileStatusId="AterNot" invoiceItemSeqId="07" isSummary="N" glAccountTypeEnumId="GatIncome"
                        debitCreditFlag="C"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="02" amount="15" glAccountId="212000000"
                        reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatAccountsPayable" debitCreditFlag="D"/>
            </mantle.ledger.transaction.AcctgTrans>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "send Purchase Invoice Payment"() {
        when:
        // Authorize payment
        // intentional overpay to test refund and payment to payment application; invoice amt is 23,830.00, pay 24,000.00 for 170.00 overpay
        ec.service.sync().name("update#mantle.account.payment.Payment").parameter("paymentId", setInfoOut.paymentId)
                .parameter("statusId", "PmntAuthorized").parameter("effectiveDate", new Timestamp(effectiveTime))
                .parameter("amount", 24000.0).call()

        // generate NACHA file, mark payment delivered (done automatically when file generated)
        ec.service.sync().name("mantle.account.NachaServices.generate#NachaFile")
                .parameter("paymentMethodId", "ZIRET_BA").parameter("addOffsetRecord", true).call()

        // find PaymentApplication for validation
        EntityList pappList = ec.entity.find("mantle.account.payment.PaymentApplication")
                .condition("paymentId", setInfoOut.paymentId).condition("invoiceId", "55400").list()
        sendPmtResult = [paymentApplicationId:pappList[0].paymentApplicationId]

        /* old approach for PiCompanyCheck payment
        // record Payment for Invoice and apply to Invoice (will trigger GL posting for Payment and Payment Application)
        sendPmtResult = ec.service.sync().name("mantle.account.PaymentServices.send#PromisedPayment")
                .parameters([invoiceId:'55400', paymentId:setInfoOut.paymentId, amount:24000.00]).call()
        sendPmtResult.paymentApplicationId
         */

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.account.payment.PaymentApplication paymentApplicationId="${sendPmtResult.paymentApplicationId}"
                paymentId="${setInfoOut.paymentId}" invoiceId="55400" amountApplied="23830.00"
                appliedDate="${effectiveTime}"/>
            <!-- Payment to Delivered status, set effectiveDate -->
            <mantle.account.payment.Payment paymentId="${setInfoOut.paymentId}" statusId="PmntDelivered"
                effectiveDate="${effectiveTime}" amount="24000" appliedTotal="23830" unappliedTotal="170"/>
            <!-- Invoice to Payment Sent status -->
            <mantle.account.invoice.Invoice invoiceId="55400" invoiceTypeEnumId="InvoiceSales"
                fromPartyId="ZiddlemanInc" toPartyId="ORG_ZIZI_RETAIL" statusId="InvoicePmtSent" invoiceDate="${effectiveTime}"
                currencyUomId="USD" invoiceTotal="23830" appliedPaymentsTotal="23830" unpaidTotal="0"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "validate Purchase Payment Accounting Transaction"() {
        when:
        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <!-- AcctgTrans created for Delivered Payment -->
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55407" acctgTransTypeEnumId="AttOutgoingPayment"
                    organizationPartyId="ORG_ZIZI_RETAIL" transactionDate="${effectiveTime}" isPosted="Y"
                    postedDate="${effectiveTime}" glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD"
                    otherPartyId="ZiddlemanInc" paymentId="${setInfoOut.paymentId}">
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="01" debitCreditFlag="D"
                        amount="24000" glAccountId="216000000" reconcileStatusId="AterNot" isSummary="N"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="02" debitCreditFlag="C"
                        amount="24000" glAccountId="111100000" reconcileStatusId="AterNot" isSummary="N"/>
            </mantle.ledger.transaction.AcctgTrans>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "validate Purchase Payment Application Accounting Transaction"() {
        when:
        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55408" acctgTransTypeEnumId="AttOutgoingPaymentAp"
                    organizationPartyId="ORG_ZIZI_RETAIL" transactionDate="${effectiveTime}" isPosted="Y"
                    postedDate="${effectiveTime}" glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD"
                    otherPartyId="ZiddlemanInc" paymentId="${setInfoOut.paymentId}"
                    paymentApplicationId="${sendPmtResult.paymentApplicationId}">
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="01" debitCreditFlag="C"
                        amount="23830" glAccountId="216000000" reconcileStatusId="AterNot" isSummary="N"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="02" debitCreditFlag="D"
                        amount="23830" glAccountId="212000000" reconcileStatusId="AterNot" isSummary="N"/>
            </mantle.ledger.transaction.AcctgTrans>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "receive Supplier Overpay Refund"() {
        when:
        // record received Payment
        refundPmtResult = ec.service.sync().name("mantle.account.PaymentServices.create#Payment")
                .parameters([paymentTypeEnumId:'PtRefund', statusId:'PmntDelivered', fromPartyId:vendorPartyId,
                             toPartyId:customerPartyId, effectiveDate:new Timestamp(effectiveTime),
                             paymentInstrumentEnumId:'PiCompanyCheck', amount:170.0]).call()
        // apply refund Payment to overpay Payment
        refundApplResult = ec.service.sync().name("mantle.account.PaymentServices.apply#PaymentToPayment")
                .parameters([paymentId:refundPmtResult.paymentId, toPaymentId:setInfoOut.paymentId]).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.account.payment.PaymentApplication paymentApplicationId="${refundApplResult.paymentApplicationId}"
                paymentId="${refundPmtResult.paymentId}" toPaymentId="${setInfoOut.paymentId}" amountApplied="170"
                appliedDate="${effectiveTime}"/>
            <mantle.account.payment.Payment paymentId="${refundPmtResult.paymentId}" statusId="PmntDelivered"
                effectiveDate="${effectiveTime}" amount="170" appliedTotal="170" unappliedTotal="0"/>
            <mantle.account.payment.Payment paymentId="${setInfoOut.paymentId}" statusId="PmntDelivered"
                effectiveDate="${effectiveTime}" amount="24000" appliedTotal="24000" unappliedTotal="0"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        refundApplResult.amountApplied == 170.0
        dataCheckErrors.size() == 0
    }

    def "validate Refund Payment Accounting Transaction"() {
        when:
        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <!-- AcctgTrans created for Delivered Payment -->
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55409" acctgTransTypeEnumId="AttIncomingPayment"
                    organizationPartyId="ORG_ZIZI_RETAIL" transactionDate="${effectiveTime}" isPosted="Y"
                    postedDate="${effectiveTime}" glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD"
                    otherPartyId="ZiddlemanInc" paymentId="${refundPmtResult.paymentId}">
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="01" debitCreditFlag="C"
                        amount="170" glAccountId="126000000" reconcileStatusId="AterNot" isSummary="N"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="02" debitCreditFlag="D"
                        amount="170" glAccountId="111100000" reconcileStatusId="AterNot" isSummary="N"/>
            </mantle.ledger.transaction.AcctgTrans>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "validate Refund Payment Application Accounting Transaction"() {
        when:
        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55410" acctgTransTypeEnumId="AttPaymentInOutAppl"
                    organizationPartyId="ORG_ZIZI_RETAIL" transactionDate="${effectiveTime}" isPosted="Y"
                    postedDate="${effectiveTime}" glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD"
                    otherPartyId="ZiddlemanInc" paymentId="${refundPmtResult.paymentId}" toPaymentId="${setInfoOut.paymentId}"
                    paymentApplicationId="${refundApplResult.paymentApplicationId}">
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="01" debitCreditFlag="D"
                        amount="170" glAccountId="126000000" reconcileStatusId="AterNot" isSummary="N"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="02" debitCreditFlag="C"
                        amount="170" glAccountId="216000000" reconcileStatusId="AterNot" isSummary="N"/>
            </mantle.ledger.transaction.AcctgTrans>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "depreciate Fixed Assets"() {
        when:
        // find the current Fiscal Month for ORG_ZIZI_RETAIL
        Map fiscalMonthOut = ec.service.sync().name("mantle.ledger.LedgerServices.get#OrganizationFiscalTimePeriods")
                .parameters([organizationPartyId:customerPartyId, filterDate:ec.user.nowTimestamp, timePeriodTypeId:'FiscalMonth']).call()
        Map timePeriod = (Map) fiscalMonthOut.timePeriodList[0]
        currentFiscalMonthId = timePeriod.timePeriodId

        Map deprOut = ec.service.sync().name("mantle.ledger.AssetAutoPostServices.calculateAndPost#AllFixedAssetDepreciations")
                .parameters([timePeriodId:timePeriod.timePeriodId]).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.product.asset.Asset assetId="${equip1AssetId}" acquireCost="10000" salvageValue="1500" depreciation="283.33"/>
            <mantle.product.asset.AssetDepreciation assetId="${equip1AssetId}" timePeriodId="${currentFiscalMonthId}"
                    annualDepreciation="3400" yearsRemaining="5" isLastYearPeriod="N"
                    monthlyDepreciation="283.33" acctgTransId="55411" usefulLifeYears="5"/>
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55411" amountUomId="USD" isPosted="Y" postedDate="${effectiveTime}"
                    acctgTransTypeEnumId="AttDepreciation" glFiscalTypeEnumId="GLFT_ACTUAL" organizationPartyId="ORG_ZIZI_RETAIL"
                    transactionDate="${deprOut.transactionDate.time}">
                <mantle.ledger.transaction.AcctgTransEntry amount="283.33" productId="EQUIP_1" glAccountId="182000000"
                        reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatFaAccumDepreciation"
                        debitCreditFlag="C" acctgTransEntrySeqId="01"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="283.33" productId="EQUIP_1" glAccountId="672000000"
                        reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatFaDepreciation"
                        debitCreditFlag="D" acctgTransEntrySeqId="02"/>
            </mantle.ledger.transaction.AcctgTrans>

            <mantle.product.asset.AssetDepreciation assetId="${equip2AssetId}" timePeriodId="${currentFiscalMonthId}" annualDepreciation="1700"
                    yearsRemaining="5" isLastYearPeriod="N" monthlyDepreciation="141.67" usefulLifeYears="5" acctgTransId="55412"/>
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55412" postedDate="${effectiveTime}" amountUomId="USD"
                    isPosted="Y" assetId="${equip2AssetId}" acctgTransTypeEnumId="AttDepreciation" glFiscalTypeEnumId="GLFT_ACTUAL"
                    transactionDate="${deprOut.transactionDate.time}" organizationPartyId="ORG_ZIZI_RETAIL">
                <mantle.ledger.transaction.AcctgTransEntry amount="141.67" productId="EQUIP_1" glAccountId="182000000"
                        reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatFaAccumDepreciation"
                        debitCreditFlag="C" assetId="${equip2AssetId}" acctgTransEntrySeqId="01"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="141.67" productId="EQUIP_1" glAccountId="672000000"
                        reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatFaDepreciation"
                        debitCreditFlag="D" assetId="${equip2AssetId}" acctgTransEntrySeqId="02"/>
            </mantle.ledger.transaction.AcctgTrans>

            <!-- TODO uncomment this after adding call to calc gl account org summaries:
            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="182000000" organizationPartyId="ORG_ZIZI_RETAIL"
                    timePeriodId="${currentFiscalMonthId}" postedCredits="425" endingBalance="425"/>
            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="672000000" organizationPartyId="ORG_ZIZI_RETAIL"
                    timePeriodId="${currentFiscalMonthId}" postedDebits="425" endingBalance="425"/>
            -->
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "sell Depreciated Asset Loss"() {
        when:
        Map createOrderResult = ec.service.sync().name("mantle.order.OrderServices.create#Order")
                .parameters([customerPartyId:'CustJqp', vendorPartyId:'ORG_ZIZI_RETAIL', facilityId:facilityId]).call()
        String orderId = createOrderResult.orderId
        String firstPartSeqId = createOrderResult.orderPartSeqId

        ec.service.sync().name("mantle.order.OrderServices.set#OrderBillingShippingInfo")
                .parameters([orderId:orderId, orderPartSeqId:firstPartSeqId, shippingPostalContactMechId:'CustJqpAddr']).call()

        ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                .parameters([orderId:orderId, orderPartSeqId:firstPartSeqId, itemTypeEnumId:'ItemAsset',
                             productId:'EQUIP_1', quantity:1, unitAmount:9000]).call()

        // place and approve the order
        ec.service.sync().name("mantle.order.OrderServices.place#Order").parameters([orderId:orderId]).call()
        ec.service.sync().name("mantle.order.OrderServices.approve#Order").parameters([orderId:orderId]).call()

        // create a Shipment
        Map createShipmentOut = ec.service.sync().name("mantle.shipment.ShipmentServices.create#OrderPartShipment")
                .parameters([orderId:orderId, orderPartSeqId:firstPartSeqId]).call()
        String shipmentId = createShipmentOut.shipmentId

        // set the shipment scheduled, pack the item
        ec.service.sync().name("update#mantle.shipment.Shipment")
                .parameters([shipmentId:shipmentId, statusId:'ShipScheduled']).call()
        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#ShipmentProduct")
                .parameters([shipmentId:shipmentId, productId:'EQUIP_1', quantity:1, assetId:equip1AssetId]).call()

        // set packed, will generate the invoice, etc; then set shipped
        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#Shipment").parameters([shipmentId:shipmentId]).call()
        ec.service.sync().name("mantle.shipment.ShipmentServices.ship#Shipment").parameters([shipmentId:shipmentId]).call()

        // lookup the invoiceId from ShipmentItemSource
        EntityList sisList = ec.entity.find("mantle.shipment.ShipmentItemSource").condition([shipmentId:shipmentId]).list()
        String invoiceId = sisList?.first()?.invoiceId

        // pay the invoice with a new payment
        Map invTotalOut = ec.service.sync().name("mantle.account.InvoiceServices.get#InvoiceTotal")
                .parameters([invoiceId:invoiceId]).call()
        BigDecimal invoiceTotal = invTotalOut.invoiceTotal

        ec.service.sync().name("mantle.account.PaymentServices.create#InvoicePayment")
                .parameters([invoiceId:invoiceId, statusId:'PmntDelivered', amountUomId:'USD', amount:invoiceTotal,
                             paymentInstrumentEnumId:'PiPersonalCheck', effectiveDate:ec.user.nowTimestamp,
                             paymentRefNum:'123456']).call()

        Map afterTotalOut = ec.service.sync().name("mantle.account.InvoiceServices.get#InvoiceTotal")
                .parameters([invoiceId:invoiceId]).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.product.issuance.AssetIssuance assetIssuanceId="55400" assetId="${equip1AssetId}" orderId="55401" orderItemSeqId="01"
                    issuedDate="${effectiveTime}" quantity="1" productId="EQUIP_1" shipmentId="55401">
                <mantle.product.asset.AssetDetail assetDetailId="55414" assetId="${equip1AssetId}" productId="EQUIP_1"
                        availableToPromiseDiff="-1" shipmentId="55401" effectiveDate="${effectiveTime}" quantityOnHandDiff="-1"/>
            </mantle.product.issuance.AssetIssuance>
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55415" assetIssuanceId="55400" postedDate="${effectiveTime}"
                    amountUomId="USD" isPosted="Y" assetId="${equip1AssetId}" acctgTransTypeEnumId="AttAssetIssuance"
                    glFiscalTypeEnumId="GLFT_ACTUAL" transactionDate="${effectiveTime}" organizationPartyId="ORG_ZIZI_RETAIL">
                <mantle.ledger.transaction.AcctgTransEntry amount="10000" productId="EQUIP_1" glAccountId="131100000"
                        reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatFixedAsset"
                        debitCreditFlag="C" assetId="${equip1AssetId}" acctgTransEntrySeqId="01"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="10000" productId="EQUIP_1" glAccountId="253100000"
                        reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatUnissuedFixedAsset"
                        debitCreditFlag="D" assetId="${equip1AssetId}" acctgTransEntrySeqId="02"/>
            </mantle.ledger.transaction.AcctgTrans>

            <mantle.account.invoice.Invoice invoiceId="55401" invoiceTypeEnumId="InvoiceSales"
                    toPartyId="CustJqp" fromPartyId="ORG_ZIZI_RETAIL" description="For Order 55401 part 01 and Shipment 55401"
                    invoiceDate="${effectiveTime}" currencyUomId="USD" statusId="InvoicePmtRecvd">
                <mantle.account.invoice.InvoiceItem invoiceItemSeqId="01" itemTypeEnumId="ItemAsset" amount="9000"
                        quantity="1" productId="EQUIP_1" description="Picker Bot 2000" itemDate="" assetId="${equip1AssetId}">
                    <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55404" quantity="1" productId="EQUIP_1"
                            orderId="55401" orderItemSeqId="01" statusId="SisPacked" quantityNotHandled="0" shipmentId="55401"/>
                    <mantle.order.OrderItemBilling orderItemBillingId="55405" orderItemSeqId="01" amount="9000"
                            quantity="1" orderId="55401" shipmentId="55401" assetIssuanceId="55400"/>
                </mantle.account.invoice.InvoiceItem>
                <mantle.ledger.transaction.AcctgTrans acctgTransId="55416" otherPartyId="CustJqp" postedDate="${effectiveTime}"
                        amountUomId="USD" isPosted="Y" acctgTransTypeEnumId="AttSalesInvoice" glFiscalTypeEnumId="GLFT_ACTUAL"
                        transactionDate="${effectiveTime}" organizationPartyId="ORG_ZIZI_RETAIL">
                    <mantle.ledger.transaction.AcctgTransEntry amount="10000" productId="EQUIP_1" glAccountId="253100000"
                            reconcileStatusId="AterNot" invoiceItemSeqId="01" isSummary="N"
                            glAccountTypeEnumId="GatUnissuedFixedAsset" debitCreditFlag="C" assetId="${equip1AssetId}" acctgTransEntrySeqId="01"/>
                    <mantle.ledger.transaction.AcctgTransEntry amount="283.33" productId="EQUIP_1" glAccountId="182000000"
                            reconcileStatusId="AterNot" invoiceItemSeqId="01" isSummary="N"
                            glAccountTypeEnumId="GatFaAccumDepreciation" debitCreditFlag="D" assetId="${equip1AssetId}" acctgTransEntrySeqId="02"/>
                    <mantle.ledger.transaction.AcctgTransEntry amount="716.67" productId="EQUIP_1" glAccountId="793100000"
                            reconcileStatusId="AterNot" invoiceItemSeqId="01" isSummary="N" debitCreditFlag="D"
                            assetId="${equip1AssetId}" acctgTransEntrySeqId="03"/>
                    <mantle.ledger.transaction.AcctgTransEntry amount="9000" glAccountId="121000000"
                            reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatAccountsReceivable"
                            debitCreditFlag="D" acctgTransEntrySeqId="04"/>
                </mantle.ledger.transaction.AcctgTrans>
                <mantle.account.payment.PaymentApplication paymentId="55402" amountApplied="9000"
                        appliedDate="${effectiveTime}" paymentApplicationId="55402"/>
            </mantle.account.invoice.Invoice>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
        afterTotalOut.unpaidTotal == 0
        afterTotalOut.appliedPaymentsTotal == invoiceTotal
    }

    def "sell Depreciated Asset Gain"() {
        when:
        Map createOrderResult = ec.service.sync().name("mantle.order.OrderServices.create#Order")
                .parameters([customerPartyId:'CustJqp', vendorPartyId:'ORG_ZIZI_RETAIL', facilityId:facilityId]).call()
        String orderId = createOrderResult.orderId
        String firstPartSeqId = createOrderResult.orderPartSeqId

        ec.service.sync().name("mantle.order.OrderServices.set#OrderBillingShippingInfo")
                .parameters([orderId:orderId, orderPartSeqId:firstPartSeqId, shippingPostalContactMechId:'CustJqpAddr']).call()

        ec.service.sync().name("mantle.order.OrderServices.add#OrderProductQuantity")
                .parameters([orderId:orderId, orderPartSeqId:firstPartSeqId, itemTypeEnumId:'ItemAsset',
                             productId:'EQUIP_1', quantity:1, unitAmount:11000]).call()

        // place and approve the order
        ec.service.sync().name("mantle.order.OrderServices.place#Order").parameters([orderId:orderId]).call()
        ec.service.sync().name("mantle.order.OrderServices.approve#Order").parameters([orderId:orderId]).call()

        // create a Shipment
        Map createShipmentOut = ec.service.sync().name("mantle.shipment.ShipmentServices.create#OrderPartShipment")
                .parameters([orderId:orderId, orderPartSeqId:firstPartSeqId]).call()
        String shipmentId = createShipmentOut.shipmentId

        // set the shipment scheduled, pack the item
        ec.service.sync().name("update#mantle.shipment.Shipment")
                .parameters([shipmentId:shipmentId, statusId:'ShipScheduled']).call()
        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#ShipmentProduct")
                .parameters([shipmentId:shipmentId, productId:'EQUIP_1', quantity:1, assetId:equip2AssetId]).call()

        // set packed, will generate the invoice, etc; then set shipped
        ec.service.sync().name("mantle.shipment.ShipmentServices.pack#Shipment").parameters([shipmentId:shipmentId]).call()
        ec.service.sync().name("mantle.shipment.ShipmentServices.ship#Shipment").parameters([shipmentId:shipmentId]).call()

        // lookup the invoiceId from ShipmentItemSource
        EntityList sisList = ec.entity.find("mantle.shipment.ShipmentItemSource").condition([shipmentId:shipmentId]).list()
        String invoiceId = sisList?.first()?.invoiceId

        // pay the invoice with a new payment
        Map invTotalOut = ec.service.sync().name("mantle.account.InvoiceServices.get#InvoiceTotal")
                .parameters([invoiceId:invoiceId]).call()
        BigDecimal invoiceTotal = invTotalOut.invoiceTotal

        ec.service.sync().name("mantle.account.PaymentServices.create#InvoicePayment")
                .parameters([invoiceId:invoiceId, statusId:'PmntDelivered', amountUomId:'USD', amount:invoiceTotal,
                             paymentInstrumentEnumId:'PiPersonalCheck', effectiveDate:ec.user.nowTimestamp,
                             paymentRefNum:'123456']).call()

        Map afterTotalOut = ec.service.sync().name("mantle.account.InvoiceServices.get#InvoiceTotal")
                .parameters([invoiceId:invoiceId]).call()

        // recalculate summaries, create GlAccountOrgTimePeriod records
        // ec.service.sync().name("mantle.ledger.LedgerServices.recalculate#GlAccountOrgSummaries").call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.product.issuance.AssetIssuance assetIssuanceId="55401" assetId="${equip2AssetId}" orderId="55402" orderItemSeqId="01"
                    issuedDate="${effectiveTime}" quantity="1" productId="EQUIP_1" shipmentId="55402">
                <mantle.product.asset.AssetDetail assetDetailId="55417" assetId="${equip2AssetId}" productId="EQUIP_1"
                        availableToPromiseDiff="-1" shipmentId="55402" effectiveDate="${effectiveTime}" quantityOnHandDiff="-1"/>
            </mantle.product.issuance.AssetIssuance>
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55418" assetIssuanceId="55401" postedDate="${effectiveTime}"
                    amountUomId="USD" isPosted="Y" assetId="${equip2AssetId}" acctgTransTypeEnumId="AttAssetIssuance"
                    glFiscalTypeEnumId="GLFT_ACTUAL" transactionDate="${effectiveTime}" organizationPartyId="ORG_ZIZI_RETAIL">
                <mantle.ledger.transaction.AcctgTransEntry amount="10000" productId="EQUIP_1" glAccountId="131100000"
                        reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatFixedAsset"
                        debitCreditFlag="C" assetId="${equip2AssetId}" acctgTransEntrySeqId="01"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="10000" productId="EQUIP_1" glAccountId="253100000"
                        reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatUnissuedFixedAsset"
                        debitCreditFlag="D" assetId="${equip2AssetId}" acctgTransEntrySeqId="02"/>
            </mantle.ledger.transaction.AcctgTrans>

            <mantle.account.invoice.Invoice invoiceId="55402" invoiceTypeEnumId="InvoiceSales"
                    toPartyId="CustJqp" fromPartyId="ORG_ZIZI_RETAIL" description="For Order 55402 part 01 and Shipment 55402"
                    invoiceDate="${effectiveTime}" currencyUomId="USD" statusId="InvoicePmtRecvd">
                <mantle.account.invoice.InvoiceItem invoiceItemSeqId="01" itemTypeEnumId="ItemAsset" amount="11000"
                        quantity="1" productId="EQUIP_1" description="Picker Bot 2000" itemDate="" assetId="${equip2AssetId}">
                    <mantle.shipment.ShipmentItemSource shipmentItemSourceId="55405" quantity="1" productId="EQUIP_1"
                            orderId="55402" orderItemSeqId="01" statusId="SisPacked" quantityNotHandled="0" shipmentId="55402"/>
                    <mantle.order.OrderItemBilling orderItemBillingId="55406" orderItemSeqId="01" amount="11000"
                            quantity="1" orderId="55402" shipmentId="55402" assetIssuanceId="55401"/>
                </mantle.account.invoice.InvoiceItem>
                <mantle.ledger.transaction.AcctgTrans acctgTransId="55419" otherPartyId="CustJqp" postedDate="${effectiveTime}"
                        amountUomId="USD" isPosted="Y" acctgTransTypeEnumId="AttSalesInvoice" glFiscalTypeEnumId="GLFT_ACTUAL"
                        transactionDate="${effectiveTime}" organizationPartyId="ORG_ZIZI_RETAIL">
                    <mantle.ledger.transaction.AcctgTransEntry amount="10000" productId="EQUIP_1" glAccountId="253100000"
                            reconcileStatusId="AterNot" invoiceItemSeqId="01" isSummary="N"
                            glAccountTypeEnumId="GatUnissuedFixedAsset" debitCreditFlag="C" assetId="${equip2AssetId}" acctgTransEntrySeqId="01"/>
                    <mantle.ledger.transaction.AcctgTransEntry amount="141.67" productId="EQUIP_1" glAccountId="182000000"
                            reconcileStatusId="AterNot" invoiceItemSeqId="01" isSummary="N"
                            glAccountTypeEnumId="GatFaAccumDepreciation" debitCreditFlag="D" assetId="${equip2AssetId}" acctgTransEntrySeqId="02"/>
                    <mantle.ledger.transaction.AcctgTransEntry amount="1141.67" productId="EQUIP_1" glAccountId="814100000"
                            reconcileStatusId="AterNot" invoiceItemSeqId="01" isSummary="N" debitCreditFlag="C"
                            assetId="${equip2AssetId}" acctgTransEntrySeqId="03"/>
                    <mantle.ledger.transaction.AcctgTransEntry amount="11000" glAccountId="121000000"
                            reconcileStatusId="AterNot" isSummary="N" glAccountTypeEnumId="GatAccountsReceivable"
                            debitCreditFlag="D" acctgTransEntrySeqId="04"/>
                </mantle.ledger.transaction.AcctgTrans>
                <mantle.account.payment.PaymentApplication paymentId="55403" amountApplied="11000"
                        appliedDate="${effectiveTime}" paymentApplicationId="55403"/>
            </mantle.account.invoice.Invoice>

            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="131100000" timePeriodId="${currentFiscalMonthId}"
                    postedCredits="20000" postedDebits="20000" endingBalance="0" organizationPartyId="ORG_ZIZI_RETAIL"/>
            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="253100000" timePeriodId="${currentFiscalMonthId}"
                    postedCredits="20000" postedDebits="20000" endingBalance="0" organizationPartyId="ORG_ZIZI_RETAIL"/>

            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="182000000" timePeriodId="${currentFiscalMonthId}"
                    postedCredits="491.66" postedDebits="425" endingBalance="66.66" organizationPartyId="ORG_ZIZI_RETAIL"/>
            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="672000000" timePeriodId="${currentFiscalMonthId}"
                    postedDebits="491.66" endingBalance="491.66" organizationPartyId="ORG_ZIZI_RETAIL"/>
            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="814100000" timePeriodId="${currentFiscalMonthId}"
                    postedCredits="1141.67" endingBalance="1141.67" organizationPartyId="ORG_ZIZI_RETAIL"/>
            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="793100000" timePeriodId="${currentFiscalMonthId}"
                    postedDebits="716.67" endingBalance="716.67" organizationPartyId="ORG_ZIZI_RETAIL"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
        afterTotalOut.unpaidTotal == 0
        afterTotalOut.appliedPaymentsTotal == invoiceTotal
    }

    def "inventory Shrinkage"() {
        when:
        ec.service.sync().name("mantle.product.AssetServices.record#PhysicalInventoryChange")
                .parameters([productId:'DEMO_1_1', facilityId:facilityId, quantityChange:-10,
                            statusId:'AstAvailable', locationSeqId:'01010101',
                            varianceReasonEnumId:'InVrLost', comments:'Test lost 10 DEMO_1_1']).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.product.asset.PhysicalInventory physicalInventoryId="55400" physicalInventoryDate="${effectiveTime}"
                    comments="Test lost 10 DEMO_1_1" partyId="EX_JOHN_DOE">
                <mantle.product.asset.AssetDetail assetDetailId="55418" assetId="DEMO_1_1A" productId="DEMO_1_1"
                        varianceReasonEnumId="InVrLost" availableToPromiseDiff="-10" quantityOnHandDiff="-10" effectiveDate="${effectiveTime}"/>
                <mantle.ledger.transaction.AcctgTrans acctgTransId="55421" postedDate="${effectiveTime}" amountUomId="USD"
                        isPosted="Y" assetId="DEMO_1_1A" acctgTransTypeEnumId="AttInventoryVariance"
                        glFiscalTypeEnumId="GLFT_ACTUAL" transactionDate="${effectiveTime}" organizationPartyId="ORG_ZIZI_RETAIL">
                    <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="01" amount="75" productId="DEMO_1_1"
                            glAccountId="527000000" reconcileStatusId="AterNot" isSummary="N"
                            glAccountTypeEnumId="GatInvShrinkage" debitCreditFlag="D" assetId="DEMO_1_1A"/>
                    <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="02" amount="75" productId="DEMO_1_1"
                            glAccountId="141300000" reconcileStatusId="AterNot" isSummary="N"
                            glAccountTypeEnumId="GatInventory" debitCreditFlag="C" assetId="DEMO_1_1A"/>
                </mantle.ledger.transaction.AcctgTrans>
            </mantle.product.asset.PhysicalInventory>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        EntityList resList = ec.entity.find("mantle.product.issuance.AssetReservation").condition("productId", "DEMO_1_1").list()
        def totalNotAvailable = resList.sum { EntityValue res -> res.quantityNotAvailable }
        logger.info("After Shrinkage DEMO_1_1 AssetReservation not available ${ObjectUtilities.toPlainString(totalNotAvailable)} ${resList.collect({[assetReservationId:it.assetReservationId, assetId:it.assetId, quantityNotAvailable:it.quantityNotAvailable]})}")

        then:
        // not available reservations should now be moved to Asset with available currently in the DB (assetId=55400)
        totalNotAvailable == 0.0
        dataCheckErrors.size() == 0
    }
    def "inventory Found"() {
        when:
        ec.service.sync().name("mantle.product.AssetServices.record#PhysicalInventoryChange")
                .parameters([productId:'DEMO_1_1', facilityId:facilityId, quantityChange:10, lotId:'55400', locationSeqId:'01010201',
                             varianceReasonEnumId:'InVrFound', comments:'Test found 10 DEMO_1_1']).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <assets assetId="55406" productId="DEMO_1_1" statusId="AstAvailable" assetTypeEnumId="AstTpInventory"
                    receivedDate="${effectiveTime}" acquiredDate="${effectiveTime}" quantityOnHandTotal="10" availableToPromiseTotal="10"
                    facilityId="ZIRET_WH" classEnumId="AsClsInventoryFin" ownerPartyId="ORG_ZIZI_RETAIL" hasQuantity="Y"/>
            <mantle.product.asset.PhysicalInventory physicalInventoryId="55401" physicalInventoryDate="${effectiveTime}"
                    comments="Test found 10 DEMO_1_1" partyId="EX_JOHN_DOE">
                <mantle.product.asset.AssetDetail assetDetailId="55421" assetId="55406" productId="DEMO_1_1"
                        varianceReasonEnumId="InVrFound" availableToPromiseDiff="10" quantityOnHandDiff="10" effectiveDate="${effectiveTime}"/>
            </mantle.product.asset.PhysicalInventory>
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55422" postedDate="${effectiveTime}" amountUomId="USD"
                    isPosted="Y" assetId="55406" acctgTransTypeEnumId="AttInventoryVariance" physicalInventoryId="55401"
                    glFiscalTypeEnumId="GLFT_ACTUAL" transactionDate="${effectiveTime}" organizationPartyId="ORG_ZIZI_RETAIL">
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="01" amount="75" productId="DEMO_1_1"
                        glAccountId="814300000" reconcileStatusId="AterNot" isSummary="N"
                        glAccountTypeEnumId="GatInvFound" debitCreditFlag="C" assetId="55406"/>
                <mantle.ledger.transaction.AcctgTransEntry acctgTransEntrySeqId="02" amount="75" productId="DEMO_1_1"
                        glAccountId="141300000" reconcileStatusId="AterNot" isSummary="N"
                        glAccountTypeEnumId="GatInventory" debitCreditFlag="D" assetId="55406"/>
            </mantle.ledger.transaction.AcctgTrans>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        logger.info("Checked ${fieldsChecked} fields")
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    // TODO: ===========================
    // TODO: alternate flow where invoice only created when items received using create#PurchaseShipmentInvoices
}
