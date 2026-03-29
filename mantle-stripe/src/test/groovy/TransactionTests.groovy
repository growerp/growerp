import org.moqui.Moqui
import org.moqui.context.ExecutionContext
import org.moqui.screen.ScreenTest
import org.moqui.screen.ScreenTest.ScreenTestRender
import org.moqui.entity.EntityList
import org.moqui.entity.EntityValue

import org.slf4j.Logger
import org.slf4j.LoggerFactory

import spock.lang.Shared
import spock.lang.Specification
import spock.lang.Unroll

import com.stripe.Stripe
import com.stripe.model.Charge
import com.stripe.model.Refund
import com.stripe.exception.StripeException
import com.stripe.exception.InvalidRequestException

class TransactionTests extends Specification {
    protected final static Logger logger = LoggerFactory.getLogger(TransactionTests.class)

    @Shared ExecutionContext ec

    def setupSpec() {
        println("START_SETUP_SPEC")
        ec = Moqui.getExecutionContext()
    }

    def cleanupSpec() {
        println("START_CLEANUP_SPEC")
        ec.destroy()
    }

    def setup() {
        println("START_SETUP")
        ec.artifactExecution.disableAuthz()
        ec.user.loginUser("john.doe", "moqui")

        def pgs = ec.entity.find("Stripe.PaymentGatewayStripe").condition("paymentGatewayConfigId", "StripeDemo").one()
        Stripe.apiKey = pgs.secretKey
    }

    def cleanup() {
        println("START_CLEANUP")
        ec.artifactExecution.enableAuthz()
        ec.user.logoutUser()
    }

    def "Authorize a payment via Stripe"() {
        given:
        def paymentMethodId = ec.service.sync().name("create#mantle.account.method.PaymentMethod").call().paymentMethodId
        def creditCard = ec.service.sync().name("create#mantle.account.method.CreditCard")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        cardNumber:"4242424242424242",
                        expireDate:"01/2050",
                        cardSecurityCode:"123"
                ]).call()
        def paymentId = ec.service.sync().name("create#mantle.account.payment.Payment")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        amount:30000
                ]).call().paymentId
        when:
        def paymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.authorize#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        then:
        def pgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", paymentGatewayResponseId).one()
        pgr != null
        pgr.resultSuccess == 'Y'

        def charge = Charge.retrieve(pgr.referenceNum)
        charge.captured == false

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:paymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.payment.Payment").parameters([paymentId:paymentId]).call()
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId:creditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId:paymentMethodId]).call()
    }

    def "Capture a payment via Stripe"() {
        given:
        def paymentMethodId = ec.service.sync().name("create#mantle.account.method.PaymentMethod").call().paymentMethodId
        def creditCard = ec.service.sync().name("create#mantle.account.method.CreditCard")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        cardNumber:"4242424242424242",
                        expireDate:"01/2050",
                        cardSecurityCode:"123"
                ]).call()
        def paymentId = ec.service.sync().name("create#mantle.account.payment.Payment")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        amount:30000
                ]).call().paymentId

        def authPaymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.authorize#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        def authPgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", authPaymentGatewayResponseId).one()
        authPgr != null
        authPgr.resultSuccess == 'Y'

        def beforeCaptureCharge = Charge.retrieve(authPgr.referenceNum)
        beforeCaptureCharge.captured == false

        when:
        def capPaymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.capture#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        then:
        def capPgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", capPaymentGatewayResponseId).one()
        capPgr != null
        capPgr.resultSuccess == 'Y'

        def afterCaptureCharge = Charge.retrieve(capPgr.referenceNum)
        afterCaptureCharge.captured == true

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:authPaymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:capPaymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.payment.Payment").parameters([paymentId:paymentId]).call()
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId:creditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId:paymentMethodId]).call()
    }

    def "Authorize and Capture a payment via Stripe"() {
        given:
        def paymentMethodId = ec.service.sync().name("create#mantle.account.method.PaymentMethod").call().paymentMethodId
        def creditCard = ec.service.sync().name("create#mantle.account.method.CreditCard")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        cardNumber:"4242424242424242",
                        expireDate:"01/2050",
                        cardSecurityCode:"123"
                ]).call()
        def paymentId = ec.service.sync().name("create#mantle.account.payment.Payment")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        amount:30000
                ]).call().paymentId
        when:
        def paymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.authorizeAndCapture#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        then:
        def pgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", paymentGatewayResponseId).one()
        pgr != null
        pgr.resultSuccess == 'Y'

        def charge = Charge.retrieve(pgr.referenceNum)
        charge.captured == true

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:paymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.payment.Payment").parameters([paymentId:paymentId]).call()
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId:creditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId:paymentMethodId]).call()
    }

    def "Release a payment via Stripe"() {
        given:
        def paymentMethodId = ec.service.sync().name("create#mantle.account.method.PaymentMethod").call().paymentMethodId
        def creditCard = ec.service.sync().name("create#mantle.account.method.CreditCard")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        cardNumber:"4242424242424242",
                        expireDate:"01/2050",
                        cardSecurityCode:"123"
                ]).call()
        def paymentId = ec.service.sync().name("create#mantle.account.payment.Payment")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        amount:30000
                ]).call().paymentId

        def authPaymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.authorize#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        def authPgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", authPaymentGatewayResponseId).one()
        authPgr != null
        authPgr.resultSuccess == 'Y'

        def beforeReleaseCharge = Charge.retrieve(authPgr.referenceNum)
        beforeReleaseCharge.captured == false

        when:
        def relPaymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.release#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        then:
        def relPgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", relPaymentGatewayResponseId).one()
        relPgr != null
        relPgr.resultSuccess == 'Y'

        def afterReleaseCharge = Charge.retrieve(relPgr.referenceNum)
        afterReleaseCharge.refunded == true

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:authPaymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:relPaymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.payment.Payment").parameters([paymentId:paymentId]).call()
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId:creditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId:paymentMethodId]).call()
    }

    def "Refund a payment via Stripe"() {
        given:
        def AMOUNT = 30000

        def paymentMethodId = ec.service.sync().name("create#mantle.account.method.PaymentMethod").call().paymentMethodId
        def creditCard = ec.service.sync().name("create#mantle.account.method.CreditCard")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        cardNumber:"4242424242424242",
                        expireDate:"01/2050",
                        cardSecurityCode:"123"
                ]).call()
        def paymentId = ec.service.sync().name("create#mantle.account.payment.Payment")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        amount:AMOUNT
                ]).call().paymentId

        def authCapPaymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.authorizeAndCapture#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        def authCapPgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", authCapPaymentGatewayResponseId).one()
        authCapPgr != null
        authCapPgr.resultSuccess == 'Y'

        def beforeRefundCharge = Charge.retrieve(authCapPgr.referenceNum)
        beforeRefundCharge.captured == true

        when:
        def refundPaymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.refund#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        then:
        def refPgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", refundPaymentGatewayResponseId).one()
        refPgr != null
        refPgr.resultSuccess == 'Y'

        def afterRefundCharge = Charge.retrieve(refPgr.referenceNum)
        afterRefundCharge.refunded == true
        afterRefundCharge.amountRefunded == AMOUNT

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:authCapPaymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:refundPaymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.payment.Payment").parameters([paymentId:paymentId]).call()
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId:creditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId:paymentMethodId]).call()
    }

    def "Partially capture a payment via Stripe"() {
        given:
        def AMOUNT = 30000
        def TRUE_AMOUNT = 10000

        def paymentMethodId = ec.service.sync().name("create#mantle.account.method.PaymentMethod").call().paymentMethodId
        def creditCard = ec.service.sync().name("create#mantle.account.method.CreditCard")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        cardNumber:"4242424242424242",
                        expireDate:"01/2050",
                        cardSecurityCode:"123"
                ]).call()
        def paymentId = ec.service.sync().name("create#mantle.account.payment.Payment")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        amount:AMOUNT
                ]).call().paymentId

        def authPaymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.authorize#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        def authPgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", authPaymentGatewayResponseId).one()
        authPgr != null
        authPgr.resultSuccess == 'Y'

        def beforeCaptureCharge = Charge.retrieve(authPgr.referenceNum)
        beforeCaptureCharge.captured == false

        when:
        def capPaymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.capture#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo", amount:TRUE_AMOUNT]).call().paymentGatewayResponseId

        then:
        def capPgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", capPaymentGatewayResponseId).one()
        capPgr != null
        capPgr.resultSuccess == 'Y'

        def afterCaptureCharge = Charge.retrieve(capPgr.referenceNum)
        afterCaptureCharge.captured == true
        afterCaptureCharge.amount == AMOUNT
        afterCaptureCharge.amountRefunded == AMOUNT - TRUE_AMOUNT

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:authPaymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:capPaymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.payment.Payment").parameters([paymentId:paymentId]).call()
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId:creditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId:paymentMethodId]).call()
    }

    def "Partially refund a payment via Stripe"() {
        given:
        def AMOUNT = 30000
        def REFUND_AMOUNT = 20000

        def paymentMethodId = ec.service.sync().name("create#mantle.account.method.PaymentMethod").call().paymentMethodId
        def creditCard = ec.service.sync().name("create#mantle.account.method.CreditCard")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        cardNumber:"4242424242424242",
                        expireDate:"01/2050",
                        cardSecurityCode:"123"
                ]).call()
        def paymentId = ec.service.sync().name("create#mantle.account.payment.Payment")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        amount:AMOUNT
                ]).call().paymentId

        def authCapPaymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.authorizeAndCapture#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        def authCapPgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", authCapPaymentGatewayResponseId).one()
        authCapPgr != null
        authCapPgr.resultSuccess == 'Y'

        def beforeRefundCharge = Charge.retrieve(authCapPgr.referenceNum)
        beforeRefundCharge.captured == true

        when:
        def refPaymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.refund#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo", amount:REFUND_AMOUNT]).call().paymentGatewayResponseId

        then:
        def refPgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", refPaymentGatewayResponseId).one()
        refPgr != null
        refPgr.resultSuccess == 'Y'

        def afterRefundCharge = Charge.retrieve(refPgr.referenceNum)
        afterRefundCharge.captured == true
        afterRefundCharge.amount == AMOUNT
        afterRefundCharge.amountRefunded == REFUND_AMOUNT

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:authCapPaymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:refPaymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.payment.Payment").parameters([paymentId:paymentId]).call()
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId:creditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId:paymentMethodId]).call()
    }

    def "Fails in authorize#Payment when Payment does not have an amount" () {
        given:
        def paymentMethodId = ec.service.sync().name("create#mantle.account.method.PaymentMethod").call().paymentMethodId
        def creditCard = ec.service.sync().name("create#mantle.account.method.CreditCard")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        cardNumber:"4242424242424242",
                        expireDate:"01/2050",
                        cardSecurityCode:"123"
                ]).call()
        def paymentId = ec.service.sync().name("create#mantle.account.payment.Payment")
                .parameters([
                        paymentMethodId:paymentMethodId
                ]).call().paymentId
        when:
        def paymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.authorize#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        then:
        def pgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", paymentGatewayResponseId).one()
        pgr != null
        pgr.resultSuccess == 'N'
        pgr.resultError == 'Y'

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:paymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.payment.Payment").parameters([paymentId:paymentId]).call()
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId:creditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId:paymentMethodId]).call()
    }

    def "Fails when given an expired credit card" () {
        given:
        def paymentMethodId = ec.service.sync().name("create#mantle.account.method.PaymentMethod").call().paymentMethodId
        def creditCard = ec.service.sync().name("create#mantle.account.method.CreditCard")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        cardNumber:"4242424242424242",
                        expireDate:"01/2015",
                        cardSecurityCode:"123"
                ]).call()
        def paymentId = ec.service.sync().name("create#mantle.account.payment.Payment")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        amount:30000,

                ]).call().paymentId
        when:
        def paymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.authorize#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        then:
        def pgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", paymentGatewayResponseId).one()
        pgr != null
        pgr.resultSuccess == 'N'
        pgr.resultError == 'Y'
        pgr.resultBadExpire == 'Y'

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:paymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.payment.Payment").parameters([paymentId:paymentId]).call()
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId:creditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId:paymentMethodId]).call()
    }

    def "Fails when given a credit card with an incorrect card number" () {
        given:
        def paymentMethodId = ec.service.sync().name("create#mantle.account.method.PaymentMethod").call().paymentMethodId
        def creditCard = ec.service.sync().name("create#mantle.account.method.CreditCard")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        cardNumber:"0000000000000000",
                        expireDate:"01/2050",
                        cardSecurityCode:"123"
                ]).call()
        def paymentId = ec.service.sync().name("create#mantle.account.payment.Payment")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        amount:30000
                ]).call().paymentId
        when:
        def paymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.authorize#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        then:
        def pgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", paymentGatewayResponseId).one()
        pgr != null
        pgr.resultSuccess == 'N'
        pgr.resultError == 'Y'
        pgr.resultBadCardNumber == 'Y'

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:paymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.payment.Payment").parameters([paymentId:paymentId]).call()
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId:creditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId:paymentMethodId]).call()
    }

    def "Authorize a payment with extra personal information (name, postal address, phone number, email)" () {
        given:
        def EMAIL = "stripetest.helloworld@moqui.org"
        def PHONE = ["123","123","1234"]
        def FIRSTNAME = "Stripe"
        def LASTNAME = "Test"

        def postalContactMechId = ec.service.sync().name("mantle.party.ContactServices.create#PostalAddress")
                .parameters([
                        address1:"123 test street",
                        address2:"",
                        city:"San Diego",
                        stateProvinceGeoId:"USA_CA",
                        countryGeoId:"USA",
                        postalCode:"92101"
                ]).call().contactMechId
        def telecomContactMechId = ec.service.sync().name("mantle.party.ContactServices.create#TelecomNumber")
                .parameters([
                        areaCode:PHONE[0],
                        contactNumber:PHONE[1]+PHONE[2]
                ]).call().contactMechId
        def emailContactMechId = ec.service.sync().name("mantle.party.ContactServices.create#EmailAddress")
                .parameters([
                        emailAddress:EMAIL
                ]).call().contactMechId

        def paymentMethodId = ec.service.sync().name("create#mantle.account.method.PaymentMethod")
                .parameters([
                        firstNameOnAccount:FIRSTNAME,
                        lastNameOnAccount:LASTNAME,
                        postalContactMechId:postalContactMechId,
                        telecomConactMechId:telecomContactMechId,
                        emailContactMechId:emailContactMechId
                ]).call().paymentMethodId

        def postalAddress = ec.entity.find("mantle.party.contact.PostalAddress").condition("contactMechId", postalContactMechId).one()
        def creditCard = ec.service.sync().name("create#mantle.account.method.CreditCard")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        cardNumber:"4242424242424242",
                        expireDate:"01/2050",
                        cardSecurityCode:"123",
                        name:FIRSTNAME + " " + LASTNAME,
                        address_line1:postalAddress.address1,
                        address_line2:postalAddress.address2,
                        address_city:postalAddress.city,
                        address_state:postalAddress.stateProvinceGeoId.substring(postalAddress.stateProvinceGeoId.indexOf('_')+1),
                        address_zip:postalAddress.postalCode,
                        address_country:postalAddress.countryGeoId
                ]).call()

        def paymentId = ec.service.sync().name("create#mantle.account.payment.Payment")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        amount:30000
                ]).call().paymentId
        when:
        def paymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.authorize#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        then:
        def pgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", paymentGatewayResponseId).one()
        pgr != null
        pgr.resultSuccess == 'Y'

        def charge = Charge.retrieve(pgr.referenceNum)
        charge.captured == false
        charge.receiptEmail == EMAIL

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:paymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.payment.Payment").parameters([paymentId:paymentId]).call()
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId:creditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId:paymentMethodId]).call()

        ec.service.sync().name("delete#mantle.party.contact.PostalAddress").parameters([contactMechId:postalContactMechId]).call()
        ec.service.sync().name("delete#mantle.party.contact.ContactMech").parameters([contactMechId:postalContactMechId]).call()
        ec.service.sync().name("delete#mantle.party.contact.TelecomNumber").parameters([contactMechId:telecomContactMechId]).call()
        ec.service.sync().name("delete#mantle.party.contact.ContactMech").parameters([contactMechId:telecomContactMechId]).call()
        ec.service.sync().name("delete#mantle.party.contact.ContactMech").parameters([contactMechId:emailContactMechId]).call()
    }

    def "Fails when paymentMethod is not a credit card" () {
        given:
        def paymentMethodId = ec.service.sync().name("create#mantle.account.method.PaymentMethod").call().paymentMethodId
        def giftCard = ec.service.sync().name("create#mantle.account.method.GiftCard")
                .parameters([
                    paymentMethodId:paymentMethodId
                ]).call()
        def paymentId = ec.service.sync().name("create#mantle.account.payment.Payment")
                .parameters([
                        paymentMethodId:paymentMethodId,
                        amount:30000,

                ]).call().paymentId
        when:
        def paymentGatewayResponseId = ec.service.sync().name("Stripe.StripePaymentServices.authorize#Payment").parameters([paymentId:paymentId,paymentGatewayConfigId:"StripeDemo"]).call().paymentGatewayResponseId

        then:
        def pgr = ec.entity.find("mantle.account.method.PaymentGatewayResponse").condition("paymentGatewayResponseId", paymentGatewayResponseId).one()
        pgr == null

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentGatewayResponseId:paymentGatewayResponseId]).call()
        ec.service.sync().name("delete#mantle.account.payment.Payment").parameters([paymentId:paymentId]).call()
        ec.service.sync().name("delete#mantle.account.method.GiftCard").parameters([paymentMethodId:giftCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId:paymentMethodId]).call()
    }
}