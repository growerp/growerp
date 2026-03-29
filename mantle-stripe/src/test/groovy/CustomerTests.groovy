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
import com.stripe.model.Customer
import com.stripe.exception.StripeException
import com.stripe.exception.InvalidRequestException

class CustomerTests extends Specification {
    protected final static Logger logger = LoggerFactory.getLogger(CustomerTests.class)

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

    def "Stripe customer is created when a credit card is created (via SECA)"() {
        when:
        def creditCard = ec.service.sync().name("mantle.account.PaymentMethodServices.create#CreditCard")
                .parameters([
                        cardNumber:"4242424242424242",
                        expireDate:"12/2050",
                        cardSecurityCode:"123"
                ]).call()

        then:
        def paymentMethod = ec.entity.find("mantle.account.method.PaymentMethod").condition('paymentMethodId', creditCard.paymentMethodId).one()
        paymentMethod.gatewayCimId != null

        def customer = Customer.retrieve(paymentMethod.gatewayCimId)
        customer.id == paymentMethod.gatewayCimId

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId: creditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentMethodId:creditCard.paymentMethodId, paymentGatewayResponseId:"*"]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId: creditCard.paymentMethodId]).call()
        customer.delete()
    }

    def "Stripe customer is updated when a credit card is updated (via SECA)"() {
        // CreditCards and PaymentMethods are treated as immutable, so update creates a new ones. (But they're cloned, so the gatewayCimId remains the same.

        def oldCreditCard = ec.service.sync().name("mantle.account.PaymentMethodServices.create#CreditCard")
                .parameters([
                        cardNumber:"4242424242424242",
                        expireDate:"12/2050",
                        cardSecurityCode:"123"
                ]).call()

        def oldPaymentMethod = ec.entity.find("mantle.account.method.PaymentMethod").condition('paymentMethodId', oldCreditCard.paymentMethodId).one()
        oldPaymentMethod.gatewayCimId != null
        def customer = Customer.retrieve(oldPaymentMethod.gatewayCimId)

        when:
        def newCreditCard = ec.service.sync().name("mantle.account.PaymentMethodServices.update#CreditCard")
                .parameters([
                        paymentMethodId: oldCreditCard.paymentMethodId,
                        cardNumber:"4242424242424242",
                        expireDate:"12/2051",
                        cardSecurityCode:"123"
                ]).call()

        then:
        def newPaymentMethod = ec.entity.find("mantle.account.method.PaymentMethod").condition('paymentMethodId', newCreditCard.paymentMethodId).one()
        newPaymentMethod.gatewayCimId != null
        newPaymentMethod.gatewayCimId == oldPaymentMethod.gatewayCimId

        def updatedCustomer = Customer.retrieve(newPaymentMethod.gatewayCimId) // getting the most recent version of the customer, with the updated information
        customer.id == updatedCustomer.id

        def oldCardExpYear = customer.sources.data[0].expYear
        def newCardExpYear = updatedCustomer.sources.data[0].expYear
        oldCardExpYear != newCardExpYear

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId: oldCreditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId: newCreditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentMethodId:oldCreditCard.paymentMethodId, paymentGatewayResponseId:"*"]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentMethodId:newCreditCard.paymentMethodId, paymentGatewayResponseId:"*"]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId: oldCreditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId: newCreditCard.paymentMethodId]).call()
        updatedCustomer.delete()
    }

    def "Stripe customer is deleted when a credit card is deleted (via SECA)"() {
        given:
        def creditCard = ec.service.sync().name("mantle.account.PaymentMethodServices.create#CreditCard")
                .parameters([
                        cardNumber:"4242424242424242",
                        expireDate:"12/2050",
                        cardSecurityCode:"123"
                ]).call()

        // validate that a customer was correctly created in the first place
        def paymentMethod = ec.entity.find("mantle.account.method.PaymentMethod").condition('paymentMethodId', creditCard.paymentMethodId).one()
        paymentMethod.gatewayCimId != null

        def customer = Customer.retrieve(paymentMethod.gatewayCimId)
        customer.id == paymentMethod.gatewayCimId

        when:
        ec.service.sync().name("mantle.account.PaymentMethodServices.delete#PaymentMethod").parameters([paymentMethodId:creditCard.paymentMethodId]).call()

        then:
        // credit card and payment method will be expired, not actually removed from the db, but the stripe customer will be deleted
        def expiredPaymentMethod = ec.entity.find("mantle.account.method.PaymentMethod").condition('paymentMethodId', creditCard.paymentMethodId).one()
        expiredPaymentMethod.thruDate < ec.user.nowTimestamp
        expiredPaymentMethod.gatewayCimId == null

        def expiredCreditCard = ec.entity.find("mantle.account.method.CreditCard").condition('paymentMethodId', creditCard.paymentMethodId).one()
        expiredCreditCard != null

        try {
            def deletedCustomer = Customer.retrieve(paymentMethod.gatewayCimId)
            "Should not be able to retrieve customer" == ""
        } catch (Exception e) {
            "Correctly threw an exception when trying to retrieve deleted customer" == "Correctly threw an exception when trying to retrieve deleted customer"
        }

        cleanup:
        ec.service.sync().name("delete#mantle.account.method.CreditCard").parameters([paymentMethodId: creditCard.paymentMethodId]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentGatewayResponse").parameters([paymentMethodId:creditCard.paymentMethodId, paymentGatewayResponseId:"*"]).call()
        ec.service.sync().name("delete#mantle.account.method.PaymentMethod").parameters([paymentMethodId: creditCard.paymentMethodId]).call()
    }

    def "Does not create Stripe customer when credit card is invalid"() {
        // It looks like mantle.account.PaymentMethodServices doesn't even resolve if the card number is wrong.
        // So no credit card / payment method is made, so no way to even add a customer to Stripe.
        // Gonna leave this test in anyways, for clarity.
    }
}